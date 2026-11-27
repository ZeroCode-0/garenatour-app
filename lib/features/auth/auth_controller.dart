import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/user.dart';
import '../extras/extras_repository.dart';
import '../home/home_controller.dart';
import '../matches/match_list_controller.dart';
import '../notifications/notifications_controller.dart';
import '../profile/profile_repository.dart';
import '../wallet/wallet_repository.dart';
import 'auth_repository.dart';

enum AuthPhase { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.phase, this.user});
  final AuthPhase phase;
  final AppUser? user;

  AuthState copyWith({AuthPhase? phase, AppUser? user, bool clearUser = false}) => AuthState(
        phase: phase ?? this.phase,
        user: clearUser ? null : (user ?? this.user),
      );
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(phase: AuthPhase.unknown)) {
    _ref.listen(sessionExpiredProvider, (prev, next) => _forceLogout());
    bootstrap();
  }

  final Ref _ref;
  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    final store = _ref.read(tokenStoreProvider);
    try {
      final has = await store.hasSession.timeout(const Duration(milliseconds: 300), onTimeout: () => false);
      if (!has) {
        state = const AuthState(phase: AuthPhase.unauthenticated);
        return;
      }
    } catch (_) {
      state = const AuthState(phase: AuthPhase.unauthenticated);
      return;
    }
    final cached = await store.readUser();
    // Resolve auth phase IMMEDIATELY without waiting for network
    state = AuthState(
      phase: AuthPhase.authenticated,
      user: cached != null ? AppUser.fromJson(cached) : null,
    );

    // Verify / refresh user profile asynchronously in the background
    try {
      final fresh = await _repo.me();
      await store.saveUser(_userJson(fresh));
      state = AuthState(phase: AuthPhase.authenticated, user: fresh);
    } catch (_) {
      // Couldn't reach the server. Only sign out if the session was actually
      // invalidated (token store cleared) — otherwise trust the cache so a
      // flaky network never kicks the user back to login.
      if (!await store.hasSession) {
        state = const AuthState(phase: AuthPhase.unauthenticated);
      }
    }
  }

  Future<void> _persist(AuthResult r) async {
    final store = _ref.read(tokenStoreProvider);
    await store.save(access: r.access, refresh: r.refresh, accessExpiresAt: r.accessExpiresAt);
    await store.saveUser(_userJson(r.user));
    state = AuthState(phase: AuthPhase.authenticated, user: r.user);
    _invalidateAllUserData();
  }

  Future<void> login(String email, String password) async {
    await _persist(await _repo.login(email: email.trim(), password: password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referCode,
  }) async {
    await _persist(await _repo.register(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      referCode: referCode?.trim(),
    ));
  }

  Future<void> logout() async {
    final store = _ref.read(tokenStoreProvider);
    final refresh = await store.refreshToken;
    try {
      await _repo.logout(refresh);
    } catch (_) {}
    await _clearUserState();
  }

  Future<void> _forceLogout() async {
    await _clearUserState();
  }

  Future<void> _clearUserState() async {
    await _ref.read(tokenStoreProvider).clear();
    state = const AuthState(phase: AuthPhase.unauthenticated);
    _invalidateAllUserData();
  }

  void _invalidateAllUserData() {
    _ref.invalidate(homeProvider);
    _ref.invalidate(featuredMatchProvider);
    _ref.invalidate(walletSummaryProvider);
    _ref.invalidate(depositInfoProvider);
    _ref.invalidate(withdrawInfoProvider);
    _ref.invalidate(recentTxnProvider);
    _ref.invalidate(profileStatsProvider);
    _ref.invalidate(unreadCountProvider);
    _ref.invalidate(supportUnreadProvider);
    _ref.invalidate(ticketsProvider);
    _ref.invalidate(shopOrdersProvider);
    _ref.invalidate(earnProvider);
    _ref.invalidate(shareInfoProvider);
    _ref.invalidate(matchListProvider);
    _ref.read(walletRefreshProvider.notifier).state++;
    _ref.read(extrasRefreshProvider.notifier).state++;
  }

  /// Called by other features when they fetch a fresher user object.
  void patchUser(AppUser u) {
    state = state.copyWith(user: u);
    _ref.read(tokenStoreProvider).saveUser(_userJson(u));
  }

  void patchWallet({double? balance, double? winning}) {
    final u = state.user;
    if (u == null) return;
    patchUser(u.copyWith(balance: balance, winning: winning));
  }

  Map<String, dynamic> _userJson(AppUser u) => {
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
        'balance': u.balance,
        'winning': u.winning,
        'total_refer': u.totalRefer,
        'total_play': u.totalPlay,
        'total_kill': u.totalKill,
        'total_win': u.totalWin,
        'refer_code': u.referCode,
        'status': u.status,
        'avatar_url': u.avatarUrl,
        'created_at': u.createdAt,
      };
}
