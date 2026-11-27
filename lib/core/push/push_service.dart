import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registered from `main()` before `runApp`. Fires for messages that arrive
/// while the app is terminated / in the background. The server always sends a
/// `notification` block alongside `data`, so Android builds the system-tray
/// notification itself — this handler only needs to exist.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // no-op: the tray notification comes from the payload's `notification` block
}

/// A push that landed while the app was in the foreground.
class ForegroundPush {
  ForegroundPush(this.title, this.body, this.data);
  final String title;
  final String body;
  final Map<String, dynamic> data;
}

class PushService {
  PushService({required this.onNavigate, required this.onForeground});

  /// Route to open when a notification is tapped (e.g. `/match/abc123`).
  final void Function(String route) onNavigate;

  /// A push arrived while the app is open — show it in-app.
  final void Function(ForegroundPush push) onForeground;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Admin-panel broadcasts target this topic.
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all-users');
    } catch (_) {/* offline — retried next launch */}

    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      onForeground(ForegroundPush(
        n?.title ?? '${m.data['title'] ?? 'Garena Tour'}',
        n?.body ?? '${m.data['body'] ?? ''}',
        m.data,
      ));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) => _routeFromData(m.data));

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _routeFromData(initial.data);
  }

  /// Current device token, or null if messaging is unavailable.
  Future<String?> token() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[push] getToken failed: $e');
      return null;
    }
  }

  Stream<String> get tokenRefreshes => FirebaseMessaging.instance.onTokenRefresh;

  void routeFor(Map<String, dynamic> data) => _routeFromData(data);

  void _routeFromData(Map<String, dynamic> data) {
    final type = '${data['type'] ?? ''}';
    final key = '${data['match_key'] ?? ''}';
    final route = switch (type) {
      'match_room' when key.isNotEmpty => '/match/$key',
      'match_result' when key.isNotEmpty => '/match/$key/result',
      'match_cancelled' || 'match' => '/matches',
      'withdraw_paid' || 'withdraw_rejected' || 'wallet' || 'deposit' => '/wallet',
      'refer' => '/refer',
      _ => '/notifications',
    };
    onNavigate(route);
  }
}

/// Guarded, idempotent Firebase init so a misconfigured build can still start.
Future<bool> initFirebase() async {
  if (Firebase.apps.isNotEmpty) return true;
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[push] Firebase.initializeApp failed: $e');
    return false;
  }
}
