import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_chip.dart';
import '../../core/widgets/bz_states.dart';
import 'match_list_controller.dart';
import 'widgets/match_card.dart';

/// Used as the "Play" tab (typeCode == null) and as a per-category screen.
class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key, this.typeCode});
  final String? typeCode;

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  String _status = 'upcoming';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.typeCode;
  }

  MatchQuery get _mq => MatchQuery(typeCode: _typeFilter, status: _status);

  String _pretty(String code) => code
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final isCategory = widget.typeCode != null;
    final types = ref.watch(matchTypesProvider);
    final state = ref.watch(matchListProvider(_mq));

    final statusTabs = <(String, String)>[
      ('upcoming', 'Upcoming'),
      ('live', 'Live'),
      ('completed', 'Results'),
      if (!isCategory) ('mine-upcoming', 'My Matches'),
    ];

    String title = 'Play';
    if (isCategory) {
      final match = (types.valueOrNull ?? []).where((t) => t.code == widget.typeCode).toList();
      title = match.isNotEmpty ? match.first.name : _pretty(widget.typeCode!);
    }

    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    if (isCategory)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.arrow_back_rounded, size: 22)),
                      ),
                    Text(title, style: AppText.h1.copyWith(fontSize: 26)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => showSearch(
                        context: context,
                        delegate: _MatchSearch(_mq),
                      ),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                        child: const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              BzChipRow(
                children: [
                  for (final t in statusTabs)
                    BzChip(label: t.$2, selected: _status == t.$1, onTap: () => setState(() => _status = t.$1)),
                ],
              ),
              if (!isCategory && !_status.startsWith('mine'))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: types.maybeWhen(
                    data: (list) => BzChipRow(
                      height: 38,
                      children: [
                        BzChip(label: 'All', compact: true, selected: _typeFilter == null, onTap: () => setState(() => _typeFilter = null)),
                        for (final t in list)
                          BzChip(label: t.name, compact: true, selected: _typeFilter == t.code, onTap: () => setState(() => _typeFilter = t.code)),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _List(state: state, mq: _mq)),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.state, required this.mq});
  final MatchListState state;
  final MatchQuery mq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading && state.matches.isEmpty) return const BzSkeletonList(itemHeight: 190);
    if (state.error != null && state.matches.isEmpty) {
      return BzError(message: state.error!, onRetry: () => ref.read(matchListProvider(mq).notifier).load());
    }
    if (state.matches.isEmpty) {
      return BzEmpty(
        title: 'No matches here',
        message: mq.status.startsWith('mine') ? "You haven't joined any matches yet." : 'New matches drop every day.',
        icon: Icons.sports_esports_rounded,
        onRetry: () => ref.read(matchListProvider(mq).notifier).load(refresh: true),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardHi,
      onRefresh: () => ref.read(matchListProvider(mq).notifier).load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 400) {
            ref.read(matchListProvider(mq).notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
          itemCount: state.matches.length + (state.hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= state.matches.length) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.4)));
            }
            return MatchCard(match: state.matches[i]);
          },
        ),
      ),
    );
  }
}

class _MatchSearch extends SearchDelegate<void> {
  _MatchSearch(this.mq);
  final MatchQuery mq;

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.bg),
      );

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.close_rounded))];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back_rounded));

  @override
  Widget buildSuggestions(BuildContext context) => _results();
  @override
  Widget buildResults(BuildContext context) => _results();

  Widget _results() => Consumer(builder: (context, ref, _) {
        final state = ref.watch(matchListProvider(mq));
        final q = query.trim().toLowerCase();
        final list = state.matches.where((m) => q.isEmpty || m.title.toLowerCase().contains(q)).toList();
        if (list.isEmpty) {
          return const BzEmpty(title: 'No matches', icon: Icons.search_off_rounded);
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final m in list) MatchCard(match: m)],
        );
      });
}
