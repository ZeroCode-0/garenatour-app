import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/env.dart';
import '../storage/device_info.dart';
import '../storage/token_store.dart';
import 'api_cache.dart';
import 'api_exception.dart';

/// High-performance wrapper over Dio:
///  • HTTP connection pooling and socket keep-alive (optimized for mobile 2G/3G/4G/Wi-Fi)
///  • Safe retry with exponential backoff on idempotent requests
///  • Strict financial safety: non-idempotent financial POSTs are NEVER blindly retried
///  • Optional Request cancellation via [CancelToken]
///  • Built-in Stale-While-Revalidate caching via [ApiCache]
///  • Transparent single-flight access token refresh
///  • Unwraps `{ ok, data | error }` envelope
/// Powered by NeXdEvE.
class ApiClient {
  ApiClient(this._tokens, {this.onSessionExpired}) {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBase,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      sendTimeout: Env.connectTimeout,
      headers: {
        'Accept': 'application/json',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate',
      },
      validateStatus: (_) => true, // we inspect the body ourselves
    ));

    // Optimize underlying Dart IO HttpClient for high latency & cellular connections
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 45);
        client.connectionTimeout = const Duration(seconds: 12);
        client.maxConnectionsPerHost = 10;
        return client;
      };
    }
  }

  late final Dio _dio;
  final TokenStore _tokens;
  final void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  // ---------------------------------------------------------------------------

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
    CancelToken? cancelToken,
    bool useCache = false,
    Duration? cacheMaxAge,
  }) =>
      _send(
        'GET',
        path,
        query: query,
        auth: auth,
        cancelToken: cancelToken,
        useCache: useCache,
        cacheMaxAge: cacheMaxAge,
      );

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    CancelToken? cancelToken,
  }) =>
      _send('POST', path, body: body, auth: auth, cancelToken: cancelToken);

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool auth = true,
    CancelToken? cancelToken,
  }) =>
      _send('PATCH', path, body: body, auth: auth, cancelToken: cancelToken);

  Future<dynamic> delete(
    String path, {
    Object? body,
    bool auth = true,
    CancelToken? cancelToken,
  }) =>
      _send('DELETE', path, body: body, auth: auth, cancelToken: cancelToken);

  /// multipart upload (image_base64 is simpler cross-platform; see repos).
  Future<dynamic> upload(
    String path,
    FormData form, {
    CancelToken? cancelToken,
  }) =>
      _send('POST', path, formData: form, auth: true, cancelToken: cancelToken);

  // ---------------------------------------------------------------------------

  bool _isFinancialPath(String method, String path) {
    if (method != 'GET' && method != 'HEAD' && method != 'OPTIONS') {
      final p = path.toLowerCase();
      if (p.contains('/wallet/') ||
          p.contains('/deposit') ||
          p.contains('/withdraw') ||
          p.contains('/shop/') ||
          p.contains('/matches/join') ||
          p.contains('/share') ||
          p.contains('/credit')) {
        return true;
      }
    }
    return false;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    FormData? formData,
    bool auth = true,
    bool isRetry = false,
    CancelToken? cancelToken,
    bool useCache = false,
    Duration? cacheMaxAge,
  }) async {
    final cacheKey = '$method:$path:${jsonEncode(query ?? {})}';

    if (useCache && method == 'GET') {
      final cached = ApiCache.get(cacheKey, allowStale: true);
      if (cached != null) {
        // Asynchronously revalidate in background without blocking caller
        unawaited(_revalidate(
          method,
          path,
          query: query,
          auth: auth,
          cacheKey: cacheKey,
          cacheMaxAge: cacheMaxAge,
        ));
        return cached;
      }
    }

    if (auth) await _ensureFreshAccess();

    int attempt = 0;
    const maxRetries = 2;
    final isFinancial = _isFinancialPath(method, path);

    while (true) {
      Response res;
      try {
        res = await _dio.request(
          path,
          queryParameters: query,
          data: formData ?? body,
          cancelToken: cancelToken,
          options: Options(
            method: method,
            headers: auth ? await _authHeader() : null,
          ),
        );
      } on DioException catch (e) {
        if (cancelToken?.isCancelled == true) {
          throw ApiException('CANCELLED', 'Request cancelled.');
        }

        final isNetwork = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;

        // SAFE RETRY: Only idempotent requests (GET) are auto-retried.
        // Financial mutations (POST/withdraw/join/deposit) are NEVER retried automatically.
        final canRetry = method == 'GET' &&
            !isFinancial &&
            isNetwork &&
            attempt < maxRetries &&
            (cancelToken == null || !cancelToken.isCancelled);

        if (canRetry) {
          attempt++;
          final backoffMs = (300 * attempt) + (DateTime.now().microsecond % 150);
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        // If network failed but cache exists, gracefully fallback to cached data
        if (isNetwork && useCache) {
          final stale = ApiCache.get(cacheKey);
          if (stale != null) return stale;
        }

        if (isNetwork) {
          throw ApiException.network();
        }
        throw ApiException.unknown(e.message);
      }

      final data = res.data;
      final status = res.statusCode ?? 0;

      if (data is Map && data['ok'] == true) {
        final payload = data['data'];
        if (useCache && method == 'GET') {
          await ApiCache.put(cacheKey, payload, ttl: cacheMaxAge);
        }
        return payload;
      }

      // envelope error
      String code = 'UNKNOWN';
      String message = 'Something went wrong.';
      Map<String, String> fields = {};
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        code = (err['code'] ?? code).toString();
        message = (err['message'] ?? message).toString();
        if (err['details'] is Map) {
          fields = (err['details'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } else if (status >= 500) {
        message = 'Server error. Please try again shortly.';
        code = 'SERVER_ERROR';
      }

      // one automatic refresh + retry on auth failure
      if (status == 401 && auth && !isRetry && code != 'ACCOUNT_BANNED') {
        final ok = await _refreshTokens();
        if (ok) {
          return _send(
            method,
            path,
            query: query,
            body: body,
            formData: formData,
            auth: auth,
            isRetry: true,
            cancelToken: cancelToken,
            useCache: useCache,
            cacheMaxAge: cacheMaxAge,
          );
        }
        if ((await _tokens.refreshToken) == null) {
          onSessionExpired?.call();
        }
      }

      throw ApiException(code, message, statusCode: status, fieldErrors: fields);
    }
  }

  Future<void> _revalidate(
    String method,
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
    required String cacheKey,
    Duration? cacheMaxAge,
  }) async {
    try {
      if (auth) await _ensureFreshAccess();
      final res = await _dio.request(
        path,
        queryParameters: query,
        options: Options(
          method: method,
          headers: auth ? await _authHeader() : null,
        ),
      );
      if (res.data is Map && res.data['ok'] == true) {
        await ApiCache.put(cacheKey, res.data['data'], ttl: cacheMaxAge);
      }
    } catch (_) {
      // background revalidation error swallowed; stale cache remains
    }
  }

  Future<Map<String, String>> _authHeader() async {
    final t = await _tokens.accessToken;
    return {if (t != null) 'Authorization': 'Bearer $t'};
  }

  Future<void> _ensureFreshAccess() async {
    final exp = await _tokens.accessExpiry;
    final hasRefresh = (await _tokens.refreshToken) != null;
    if (!hasRefresh) return;
    if (exp == null || DateTime.now().add(Env.accessSkew).isAfter(exp)) {
      await _refreshTokens();
    }
  }

  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  /// Codes that mean the refresh token / account is genuinely unusable — the
  /// only situations where we wipe the session and send the user to login.
  static const _fatalRefreshCodes = {
    'TOKEN_INVALID',
    'TOKEN_EXPIRED',
    'TOKEN_REUSE',
    'TOKEN_REQUIRED',
    'DEVICE_MISMATCH',
    'ACCOUNT_UNAVAILABLE',
    'ACCOUNT_BANNED',
  };

  Future<bool> _doRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;

    Response res;
    try {
      final device = await DeviceInfo.load();
      res = await _dio.post('/auth/refresh', data: {
        'refresh_token': refresh,
        'device_id': device.id,
      });
    } on DioException catch (_) {
      return false;
    }

    final data = res.data;
    final status = res.statusCode ?? 0;

    if (data is Map && data['ok'] == true) {
      try {
        final tk = data['data']['tokens'] as Map;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await _tokens.save(
          access: tk['access_token'] as String,
          refresh: tk['refresh_token'] as String,
          accessExpiresAt:
              (tk['expires_at'] ?? now + (tk['expires_in'] as num).toInt()).toInt(),
        );
        if (data['data']['user'] is Map) {
          await _tokens.saveUser(
              (data['data']['user'] as Map).cast<String, dynamic>());
        }
        return true;
      } catch (_) {
        return false;
      }
    }

    final code = (data is Map && data['error'] is Map)
        ? '${(data['error'] as Map)['code'] ?? ''}'
        : '';
    if (status == 403 || _fatalRefreshCodes.contains(code)) {
      await _tokens.clear();
      return false;
    }
    return false;
  }
}
