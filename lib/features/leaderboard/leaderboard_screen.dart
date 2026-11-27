import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_chip.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/podium.dart';
import '../../models/misc.dart';

final _leaderboardProvider =
    FutureProvider.family<({List<LeaderRow> rows, int? myRank}), String>((ref, sort) async {
  ref.keepAlive();
  final api = ref.watch(apiClientProvider);
  final data = await api.get(
    '/leaderboard',
    query: {'sort': sort},
    useCache: true,
    cacheMaxAge: const Duration(minutes: 5),
  ) as Map<String, dynamic>;
  final rows = (data['leaderboard'] as List).cast<Map<String, dynamic>>().map(LeaderRow.fromJson).toList();
  return (rows: rows, myRank: (data['my_rank'] as num?)?.toInt());
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _S();
}

class _S extends ConsumerState<LeaderboardScreen> {
  String _sort = 'wins';
  static const _tabs = {'wins': 'Total Wins', 'earnings': 'Total Earnings', 'kills': 'Most Kills'};

  String _metric(LeaderRow r) => switch (_sort) {
        'earnings' => Fmt.takaShort(r.metric == 0 ? r.prize : r.metric),
        'kills' => '${(r.metric == 0 ? r.kills : r.metric).toInt()} Kills',
        _ => '${(r.metric == 0 ? r.wins : r.metric).toInt()} Wins',
      };

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(_leaderboardProvider(_sort));
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: Column(
            children: [
              BzChipRow(
                height: 46,
                children: [for (final t in _tabs.entries) BzChip(label: t.value, selected: _sort == t.key, onTap: () => setState(() => _sort = t.key))],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: board.when(
                  loading: () => const BzSkeletonList(itemHeight: 62),
                  error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(_leaderboardProvider(_sort))),
                  data: (d) {
                    if (d.rows.isEmpty) {
                      return const BzEmpty(title: 'No rankings yet', message: 'Win matches to climb the board.', icon: Icons.leaderboard_rounded);
                    }
                    final top3 = d.rows.take(3).map((r) => PodiumEntry(name: r.name, metric: _metric(r), avatarUrl: r.avatarUrl)).toList();
                    final rest = d.rows.skip(3).toList();
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.cardHi,
                      onRefresh: () async => ref.invalidate(_leaderboardProvider(_sort)),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        children: [
                          if (d.myRank != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(gradient: AppColors.primaryGradH, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const Icon(Icons.my_location_rounded, color: Colors.white, size: 17),
                                const SizedBox(width: 8),
                                Text('Your rank: #${d.myRank}', style: AppText.bodyStrong.copyWith(color: Colors.white)),
                              ]),
                            ),
                          Podium(entries: top3),
                          const SizedBox(height: 18),
                          for (var i = 0; i < rest.length; i++) _RankRow(row: rest[i], metric: _metric(rest[i])).stagger(i),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, required this.metric});
  final LeaderRow row;
  final String metric;
  @override
  Widget build(BuildContext context) {
    return BzCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: row.isMe ? AppColors.primary.withValues(alpha: 0.5) : AppColors.line,
      child: Row(children: [
        SizedBox(width: 30, child: Text('#${row.rank}', style: AppText.numM.copyWith(fontSize: 13, color: AppColors.textMuted))),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.cardHi,
          backgroundImage: row.avatarUrl != null ? CachedNetworkImageProvider(row.avatarUrl!) : null,
          child: row.avatarUrl == null ? Text(row.name.isNotEmpty ? row.name[0].toUpperCase() : '?', style: AppText.bodyS) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(row.name, style: AppText.bodyM.copyWith(color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(metric, style: AppText.numM.copyWith(fontSize: 12, color: AppColors.gold)),
      ]),
    );
  }
}
