import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/matches/match_list_screen.dart';
import '../../features/matches/match_detail_screen.dart';
import '../../features/matches/join_screen.dart';
import '../../features/results/result_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/deposit_screen.dart';
import '../../features/wallet/withdraw_screen.dart';
import '../../features/wallet/transactions_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/refer/refer_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/developer_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/system/maintenance_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/earn/earn_screen.dart';
import '../../features/earn/spin_screen.dart';
import '../../features/vip/vip_screen.dart';
import '../../features/share/share_screen.dart';
import '../../features/support/support_screens.dart';
import '../../features/account/account_screens.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// App-wide messenger so background services (push) can show in-app banners
/// without holding a BuildContext.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final phase = auth.phase;

      if (phase == AuthPhase.unknown) {
        return (loc == '/splash' || loc == '/login') ? null : '/splash';
      }
      final authed = phase == AuthPhase.authenticated;
      final onAuthPages = loc == '/login' || loc == '/register' || loc == '/splash' || loc == '/forgot';
      if (loc == '/forgot' || loc.startsWith('/legal/')) return authed && loc == '/forgot' ? '/home' : null;

      if (!authed && !onAuthPages) return '/login';
      if (authed && onAuthPages) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/legal/:slug', builder: (_, s) => LegalScreen(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/maintenance', builder: (_, __) => const MaintenanceScreen()),

      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(navigatorKey: _shellKey, routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/matches', builder: (_, __) => const MatchListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/matches/:type',
        builder: (_, s) => MatchListScreen(typeCode: s.pathParameters['type']),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/match/:key',
        builder: (_, s) => MatchDetailScreen(matchKey: s.pathParameters['key']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/match/:key/join',
        builder: (_, s) => JoinScreen(matchKey: s.pathParameters['key']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/match/:key/result',
        builder: (_, s) => ResultScreen(matchKey: s.pathParameters['key']!),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/deposit', builder: (_, __) => const DepositScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/withdraw', builder: (_, __) => const WithdrawScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/transactions', builder: (_, __) => const TransactionsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/refer', builder: (_, __) => const ReferScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/developer', builder: (_, __) => const DeveloperScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/diamond', builder: (_, __) => const ShopScreen(initialTab: 0)),
      GoRoute(parentNavigatorKey: _rootKey, path: '/shop/orders', builder: (_, __) => const ShopOrdersScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/earn', builder: (_, __) => const EarnScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/spin', builder: (_, __) => const SpinScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/vip', builder: (_, __) => const VipScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/share', builder: (_, __) => const ShareScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/promo', builder: (_, __) => const PromoScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/support/:id',
          builder: (_, s) => TicketChatScreen(id: int.parse(s.pathParameters['id']!))),
      GoRoute(parentNavigatorKey: _rootKey, path: '/account/delete', builder: (_, __) => const DeleteAccountScreen()),
    ],
  );
});
