import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight in-memory & persistent cache for API responses.
/// Provides instant UI display on app launch (0ms perceived latency)
/// while network revalidates in background (stale-while-revalidate).
/// Powered by NeXdEvE.
class ApiCache {
  ApiCache._();

  static final Map<String, _CacheEntry> _memory = {};
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  static const String _prefix = 'gt_cache_';

  static Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      // Pre-load persisted cache keys into memory
      final keys = _prefs?.getKeys() ?? {};
      for (final k in keys) {
        if (k.startsWith(_prefix)) {
          final raw = _prefs?.getString(k);
          if (raw != null) {
            final map = jsonDecode(raw);
            if (map is Map<String, dynamic>) {
              final exp = map['exp'] as int?;
              final data = map['data'];
              final cleanKey = k.substring(_prefix.length);
              _memory[cleanKey] = _CacheEntry(
                data: data,
                expiresAt: exp != null ? DateTime.fromMillisecondsSinceEpoch(exp) : null,
              );
            }
          }
        }
      }
    } catch (_) {
      // Fallback to in-memory only if SharedPreferences is unavailable
      _initialized = true;
    }
  }

  static dynamic get(String key, {bool allowStale = true}) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (!allowStale && entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      return null;
    }
    return entry.data;
  }

  static Future<void> put(String key, dynamic data, {Duration? ttl, bool persist = true}) async {
    final exp = ttl != null ? DateTime.now().add(ttl) : null;
    _memory[key] = _CacheEntry(data: data, expiresAt: exp);

    if (persist && _prefs != null) {
      try {
        final payload = jsonEncode({
          'exp': exp?.millisecondsSinceEpoch,
          'data': data,
        });
        await _prefs?.setString('$_prefix$key', payload);
      } catch (_) {}
    }
  }

  static Future<void> invalidate(String key) async {
    _memory.remove(key);
    await _prefs?.remove('$_prefix$key');
  }

  static Future<void> clear() async {
    _memory.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    }
  }
}

class _CacheEntry {
  _CacheEntry({required this.data, this.expiresAt});
  final dynamic data;
  final DateTime? expiresAt;
}
