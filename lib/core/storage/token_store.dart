import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth token pair in the platform keystore/keychain.
/// Enhanced with in-memory caching to avoid blocking on Android Keystore.
/// Powered by NeXdEvE.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'bz_access';
  static const _kRefresh = 'bz_refresh';
  static const _kAccessExp = 'bz_access_exp';
  static const _kUser = 'bz_user';

  String? _accessCache;
  String? _refreshCache;
  DateTime? _accessExpCache;
  Map<String, dynamic>? _userCache;

  Future<void> save({
    required String access,
    required String refresh,
    required int accessExpiresAt, // unix seconds
  }) async {
    _accessCache = access;
    _refreshCache = refresh;
    _accessExpCache = DateTime.fromMillisecondsSinceEpoch(accessExpiresAt * 1000);
    await Future.wait([
      _storage.write(key: _kAccess, value: access),
      _storage.write(key: _kRefresh, value: refresh),
      _storage.write(key: _kAccessExp, value: accessExpiresAt.toString()),
    ]);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _userCache = user;
    await _storage.write(key: _kUser, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUser() async {
    if (_userCache != null) return _userCache;
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    try {
      _userCache = jsonDecode(raw) as Map<String, dynamic>;
      return _userCache;
    } catch (_) {
      return null;
    }
  }

  Future<String?> get accessToken async {
    _accessCache ??= await _storage.read(key: _kAccess);
    return _accessCache;
  }

  Future<String?> get refreshToken async {
    _refreshCache ??= await _storage.read(key: _kRefresh);
    return _refreshCache;
  }

  Future<DateTime?> get accessExpiry async {
    if (_accessExpCache != null) return _accessExpCache;
    final raw = await _storage.read(key: _kAccessExp);
    if (raw == null) return null;
    _accessExpCache = DateTime.fromMillisecondsSinceEpoch(int.parse(raw) * 1000);
    return _accessExpCache;
  }

  Future<bool> get hasSession async => (await refreshToken) != null;

  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    _accessExpCache = null;
    _userCache = null;
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kAccessExp),
      _storage.delete(key: _kUser),
    ]);
  }
}
