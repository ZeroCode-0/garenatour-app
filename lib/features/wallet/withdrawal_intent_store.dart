import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure model representing an in-flight or unresolved withdrawal intent.
/// Preserves the exact request payload and idempotency key across app restarts
/// to guarantee zero duplicate balance deductions on unreliable cellular/Wi-Fi connections.
/// Powered by NeXdEvE.
class WithdrawalIntent {
  const WithdrawalIntent({
    required this.userId,
    required this.idempotencyKey,
    required this.provider,
    required this.accountNumber,
    required this.amount,
    required this.createdAtMs,
  });

  final int userId;
  final String idempotencyKey;
  final String provider;
  final String accountNumber;
  final double amount;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'idempotency_key': idempotencyKey,
        'provider': provider,
        'account_number': accountNumber,
        'amount': amount,
        'created_at_ms': createdAtMs,
      };

  factory WithdrawalIntent.fromJson(Map<String, dynamic> json) => WithdrawalIntent(
        userId: (json['user_id'] as num).toInt(),
        idempotencyKey: json['idempotency_key'] as String,
        provider: json['provider'] as String,
        accountNumber: json['account_number'] as String,
        amount: (json['amount'] as num).toDouble(),
        createdAtMs: (json['created_at_ms'] as num).toInt(),
      );

  /// Check if intent is older than given duration (default 24 hours).
  bool isExpired([Duration maxAge = const Duration(hours: 24)]) {
    final age = DateTime.now().millisecondsSinceEpoch - createdAtMs;
    return age > maxAge.inMilliseconds;
  }
}

/// Persistent store for pending withdrawal intents, isolated per user.
class WithdrawalIntentStore {
  WithdrawalIntentStore._();

  static const String _keyPrefix = 'gt_pending_withdraw_user_';

  static String _storageKey(int userId) => '$_keyPrefix$userId';

  /// Generates a globally unique, bounded-length idempotency key (capped <= 36 chars).
  static String generateKey(int userId) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random.secure().nextInt(0xfffffff).toRadixString(36);
    final key = 'w$userId-$ts-$rnd';
    return key.length > 36 ? key.substring(0, 36) : key;
  }

  /// Persists a pending withdrawal intent before the HTTP request is dispatched.
  static Future<void> save(WithdrawalIntent intent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(intent.toJson());
      await prefs.setString(_storageKey(intent.userId), jsonStr);
    } catch (_) {
      // Non-fatal fallback; in-memory flow continues
    }
  }

  /// Retrieves the pending withdrawal intent for a specific user.
  /// Automatically discards expired intents older than 24 hours.
  static Future<WithdrawalIntent?> getForUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final intent = WithdrawalIntent.fromJson(map);

      if (intent.isExpired()) {
        await clearForUser(userId);
        return null;
      }
      return intent;
    } catch (_) {
      return null;
    }
  }

  /// Clears the pending intent for a user upon definitive server response.
  static Future<void> clearForUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(userId));
    } catch (_) {}
  }

  /// Clears all pending intents across all users (e.g. on full storage reset).
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
