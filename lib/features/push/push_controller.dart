import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../auth/auth_controller.dart';
import '../notifications/notifications_controller.dart';
import '../profile/profile_repository.dart';

/// Instantiated once (watched in `GarenaTourApp`). Owns the [PushService],
/// registers the FCM token with the backend after login, re-registers when
/// Firebase rotates the token, and surfaces foreground pushes in-app.
final pushControllerProvider = Provider<PushController>((ref) {
  final c = PushController(ref);
  ref.onDispose(c.dispose);
  c.start();
  return c;
});

class PushController {
  PushController(this._ref);
  final Ref _ref;

  PushService? _service;
  StreamSubscription<String>? _refreshSub;
  ProviderSubscription<AuthState>? _authSub;
  String? _lastSent;

  Future<void> start() async {
    if (!await initFirebase()) return;

    _service = PushService(
      onNavigate: _go,
      onForeground: _showInApp,
    );
    await _service!.init();

    _refreshSub = _service!.tokenRefreshes.listen(_sendToken);

    _authSub = _ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.phase == AuthPhase.authenticated) _syncToken();
    }, fireImmediately: true);
  }

  void _go(String route) {
    try {
      _ref.read(routerProvider).go(route);
    } catch (e) {
      if (kDebugMode) debugPrint('[push] navigate failed: $e');
    }
  }

  void _showInApp(ForegroundPush p) {
    _ref.read(notificationsRefreshProvider.notifier).state++;
    final messenger = rootMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.cardHi,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        content: Row(children: [
          const Icon(Icons.notifications_active_rounded, color: AppColors.primaryHi, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (p.body.isNotEmpty)
                  Text(p.body, style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: AppColors.primaryHi,
          onPressed: () => _service?.routeFor(p.data),
        ),
      ));
  }

  Future<void> _syncToken() async {
    final token = await _service?.token();
    if (token != null) _sendToken(token);
  }

  Future<void> _sendToken(String token) async {
    if (token == _lastSent) return;
    if (_ref.read(authControllerProvider).phase != AuthPhase.authenticated) return;
    try {
      await _ref.read(profileRepositoryProvider).registerFcmToken(token);
      _lastSent = token;
      if (kDebugMode) debugPrint('[push] token registered');
    } catch (e) {
      if (kDebugMode) debugPrint('[push] token register failed: $e');
    }
  }

  void dispose() {
    _refreshSub?.cancel();
    _authSub?.close();
  }
}
