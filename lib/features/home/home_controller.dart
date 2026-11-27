import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/match.dart';
import '../../models/misc.dart';
import '../matches/match_repository.dart';
import '../wallet/wallet_repository.dart';

class HomeData {
  HomeData({
    required this.name,
    required this.avatarUrl,
    required this.balance,
    required this.winning,
    this.coins = 0,
    required this.notice,
    required this.marquee,
    required this.sliders,
    required this.matchTypes,
    this.featuredMatch,
    this.unreadNotifications = 0,
    this.unreadSupport = 0,
  });

  final String name;
  final String? avatarUrl;
  final String balance;
  final String winning;
  final int coins;
  final String notice;
  final String marquee;
  final List<Slider> sliders;
  final List<MatchType> matchTypes;
  final GameMatch? featuredMatch;
  final int unreadNotifications;
  final int unreadSupport;
}

final homeProvider = FutureProvider<HomeData>((ref) async {
  ref.keepAlive();
  ref.watch(walletRefreshProvider);
  final api = ref.watch(apiClientProvider);
  final data = (await api.get(
    '/home',
    useCache: true,
    cacheMaxAge: const Duration(minutes: 5),
  )) as Map<String, dynamic>;

  final user = (data['user'] as Map).cast<String, dynamic>();

  GameMatch? featured;
  if (data['featured_match'] is Map) {
    try {
      featured = GameMatch.fromJson((data['featured_match'] as Map).cast<String, dynamic>());
    } catch (_) {}
  }

  return HomeData(
    name: user['name'] ?? '',
    avatarUrl: (user['avatar_url'] as String?)?.isEmpty ?? true ? null : user['avatar_url'],
    balance: '${user['balance'] ?? '0.00'}',
    winning: '${user['winning'] ?? '0.00'}',
    coins: (user['coins'] as num?)?.toInt() ?? 0,
    notice: data['notice'] ?? '',
    marquee: data['marquee'] ?? '',
    sliders: ((data['sliders'] as List?) ?? [])
        .map((e) => Slider.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    matchTypes: ((data['match_types'] as List?) ?? [])
        .map((e) => MatchType.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    featuredMatch: featured,
    unreadNotifications: (data['unread_notifications'] as num?)?.toInt() ?? 0,
    unreadSupport: (data['unread_support'] as num?)?.toInt() ?? 0,
  );
});

/// The match shown in the Home "Featured Tournament" card.
/// Uses the consolidated match embedded in HomeData when available (0 network calls),
/// falling back to repository queries only if necessary.
final featuredMatchProvider = FutureProvider<GameMatch?>((ref) async {
  ref.keepAlive();
  final homeData = ref.watch(homeProvider).valueOrNull;
  if (homeData != null && homeData.featuredMatch != null) {
    return homeData.featuredMatch;
  }
  try {
    final live = await ref.watch(matchRepositoryProvider).list(status: 'live', page: 1);
    if (live.matches.isNotEmpty) return live.matches.first;
    final up = await ref.watch(matchRepositoryProvider).list(status: 'upcoming', page: 1);
    return up.matches.isNotEmpty ? up.matches.first : null;
  } catch (_) {
    return null;
  }
});
