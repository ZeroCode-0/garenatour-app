import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match.dart';
import 'match_repository.dart';

final matchTypesProvider = FutureProvider<List<MatchType>>((ref) {
  ref.keepAlive();
  return ref.watch(matchRepositoryProvider).types();
});

class MatchQuery {
  const MatchQuery({this.typeCode, this.status = 'upcoming'});
  final String? typeCode;
  final String status; // upcoming | completed | mine-upcoming | mine-completed

  @override
  bool operator ==(Object other) =>
      other is MatchQuery && other.typeCode == typeCode && other.status == status;
  @override
  int get hashCode => Object.hash(typeCode, status);
}

class MatchListState {
  const MatchListState({
    this.matches = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
    this.page = 1,
  });

  final List<GameMatch> matches;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final int page;

  MatchListState copyWith({
    List<GameMatch>? matches,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    int? page,
  }) =>
      MatchListState(
        matches: matches ?? this.matches,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        page: page ?? this.page,
      );
}

final matchListProvider = StateNotifierProvider.family<MatchListController, MatchListState, MatchQuery>(
  (ref, q) {
    ref.keepAlive();
    return MatchListController(ref.watch(matchRepositoryProvider), q)..load();
  },
);

class MatchListController extends StateNotifier<MatchListState> {
  MatchListController(this._repo, this._q) : super(const MatchListState());

  final MatchRepository _repo;
  final MatchQuery _q;

  bool get _isMine => _q.status.startsWith('mine-');

  Future<void> load({bool refresh = false}) async {
    final hasExisting = state.matches.isNotEmpty;
    state = state.copyWith(loading: !hasExisting, clearError: true, page: 1);
    try {
      if (_isMine) {
        final filter = _q.status == 'mine-completed' ? 'completed' : 'upcoming';
        final list = await _repo.myMatches(filter: filter);
        state = state.copyWith(matches: list, loading: false, hasMore: false);
      } else {
        final res = await _repo.list(typeCode: _q.typeCode, status: _q.status, page: 1);
        state = state.copyWith(
          matches: res.matches,
          loading: false,
          hasMore: res.hasMore,
          page: res.page,
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: hasExisting ? null : '$e');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || _isMine) return;
    state = state.copyWith(loadingMore: true);
    try {
      final res = await _repo.list(typeCode: _q.typeCode, status: _q.status, page: state.page + 1);
      state = state.copyWith(
        matches: [...state.matches, ...res.matches],
        loadingMore: false,
        hasMore: res.hasMore,
        page: res.page,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}
