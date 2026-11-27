import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match.dart';
import 'match_repository.dart';

final matchDetailProvider = FutureProvider.autoDispose.family<GameMatch, String>(
  (ref, key) => ref.watch(matchRepositoryProvider).detail(key),
);

final matchPlayersProvider = FutureProvider.autoDispose
    .family<({List<MatchPlayer> players, bool locked, int capacity}), String>(
  (ref, key) => ref.watch(matchRepositoryProvider).players(key),
);
