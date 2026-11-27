import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../models/match.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(apiClientProvider)),
);

class MatchListPage {
  MatchListPage(this.matches, this.hasMore, this.page);
  final List<GameMatch> matches;
  final bool hasMore;
  final int page;
}

class MatchRepository {
  MatchRepository(this._api);
  final ApiClient _api;

  Future<List<MatchType>> types() async {
    final data = await _api.get('/match-types', useCache: true, cacheMaxAge: const Duration(hours: 1));
    final list = ((data as Map)['match_types'] as List).cast<Map<String, dynamic>>();
    return list.map(MatchType.fromJson).toList();
  }

  Future<MatchListPage> list({
    String? typeCode,
    String status = 'upcoming',
    int page = 1,
  }) async {
    final data = await _api.get(
      '/matches',
      query: {
        if (typeCode != null) 'type': typeCode,
        'status': status,
        'page': page,
      },
      useCache: page == 1,
      cacheMaxAge: const Duration(minutes: 3),
    ) as Map<String, dynamic>;
    final list = (data['matches'] as List).cast<Map<String, dynamic>>();
    return MatchListPage(
      list.map(GameMatch.fromJson).toList(),
      data['has_more'] == true,
      (data['page'] as num?)?.toInt() ?? page,
    );
  }

  Future<List<GameMatch>> myMatches({String filter = 'upcoming'}) async {
    final data = await _api.get(
      '/my/matches',
      query: {'filter': filter},
      useCache: true,
      cacheMaxAge: const Duration(minutes: 2),
    ) as Map<String, dynamic>;
    return (data['matches'] as List)
        .cast<Map<String, dynamic>>()
        .map(GameMatch.fromJson)
        .toList();
  }

  Future<GameMatch> detail(String key) async {
    final data = await _api.get('/matches/$key') as Map<String, dynamic>;
    return GameMatch.fromJson((data['match'] as Map).cast<String, dynamic>());
  }

  Future<({List<MatchPlayer> players, bool locked, int capacity})> players(String key) async {
    final data = await _api.get('/matches/$key/players') as Map<String, dynamic>;
    final list = ((data['players'] as List?) ?? []).cast<Map<String, dynamic>>();
    return (
      players: list.map(MatchPlayer.fromJson).toList(),
      locked: data['locked'] == true,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>> join({
    required String key,
    required List<String> igns,
    required String idempotencyKey,
    List<int> preferredSlots = const [],
  }) async {
    final data = await _api.post('/matches/$key/join', body: {
      'idempotency_key': idempotencyKey,
      'igns': igns,
      if (preferredSlots.isNotEmpty) 'preferred_slots': preferredSlots,
    });
    return (data as Map).cast<String, dynamic>();
  }

  /// slot-grid state for the join screen
  Future<({int totalSlots, int teamSize, String teamMode, Set<int> booked})> slots(String key) async {
    final data = await _api.get('/matches/$key/slots') as Map<String, dynamic>;
    return (
      totalSlots: (data['total_slots'] as num?)?.toInt() ?? 0,
      teamSize: (data['team_size'] as num?)?.toInt() ?? 1,
      teamMode: '${data['team_mode'] ?? ''}',
      booked: ((data['booked'] as List?) ?? []).map((e) => (e as num).toInt()).toSet(),
    );
  }
}

final matchSlotsProvider = FutureProvider.autoDispose
    .family<({int totalSlots, int teamSize, String teamMode, Set<int> booked}), String>(
  (ref, key) => ref.watch(matchRepositoryProvider).slots(key),
);
