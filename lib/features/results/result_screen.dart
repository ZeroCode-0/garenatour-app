import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../models/match.dart';

final _resultProvider = FutureProvider.autoDispose.family<_ResultData, String>((ref, key) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/matches/$key/result') as Map<String, dynamic>;
  final m = (data['match'] as Map).cast<String, dynamic>();
  final winners = ((data['winners'] as List?) ?? []).cast<Map<String, dynamic>>();
  final mine = data['my_result'] as Map?;
  return _ResultData(
    title: m['title'] ?? '',
    typeName: m['type_name'] ?? '',
    prizePool: m['prize_pool']?.toString() ?? '0',
    published: m['result_published'] == true,
    winners: winners.map(MatchWinner.fromJson).toList(),
    myKills: mine?['kills'] as int?,
    myPrize: mine?['prize']?.toString(),
  );
});

class _ResultData {
  _ResultData({required this.title, required this.typeName, required this.prizePool, required this.published, required this.winners, this.myKills, this.myPrize});
  final String title, typeName, prizePool;
  final bool published;
  final List<MatchWinner> winners;
  final int? myKills;
  final String? myPrize;
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.matchKey});
  final String matchKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(_resultProvider(matchKey));
    return Scaffold(
      appBar: AppBar(title: const Text('Match Result')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: res.when(
            loading: () => const BzLoader(),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(_resultProvider(matchKey))),
            data: (d) {
              if (!d.published) {
                return const BzEmpty(title: 'Result not published yet', message: 'The admin is still verifying scores.', icon: Icons.hourglass_empty_rounded);
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(d.typeName.toUpperCase(), style: AppText.label.copyWith(fontSize: 10)),
                  Text(d.title, style: AppText.h2),
                  const SizedBox(height: 16),
                  if (d.myPrize != null)
                    BzCard(
                      glow: AppColors.gold,
                      borderColor: AppColors.gold.withValues(alpha: 0.4),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.16), shape: BoxShape.circle),
                          child: const Icon(Icons.military_tech_rounded, color: AppColors.gold, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR RESULT', style: AppText.label.copyWith(fontSize: 9.5)),
                            Text('${d.myKills ?? 0} kills', style: AppText.bodyM),
                          ],
                        )),
                        MoneyText(double.tryParse(d.myPrize ?? '0') ?? 0, style: AppText.numXl.copyWith(color: AppColors.gold, fontSize: 22)),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  const SectionHeader('Winners'),
                  if (d.winners.isEmpty)
                    BzCard(child: Text('No winners recorded for this match.', style: AppText.bodyM))
                  else
                    for (var i = 0; i < d.winners.length; i++) _WinnerRow(w: d.winners[i]).stagger(i),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WinnerRow extends StatelessWidget {
  const _WinnerRow({required this.w});
  final MatchWinner w;
  @override
  Widget build(BuildContext context) {
    final medal = switch (w.position) {
      1 => AppColors.gold,
      2 => const Color(0xFFC7C7D1),
      3 => const Color(0xFFCD7F45),
      _ => AppColors.textMuted,
    };
    return BzCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: w.position <= 3 ? medal.withValues(alpha: 0.4) : AppColors.line,
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: medal.withValues(alpha: 0.16), shape: BoxShape.circle, border: Border.all(color: medal.withValues(alpha: 0.5))),
          alignment: Alignment.center,
          child: Text('${w.position}', style: AppText.numM.copyWith(fontSize: 12, color: medal)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(w.ign, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (w.kills > 0) ...[Text('${w.kills}K', style: AppText.bodyS.copyWith(color: AppColors.text)), const SizedBox(width: 12)],
        Text(Fmt.taka(w.prize), style: AppText.numM.copyWith(fontSize: 13, color: AppColors.gold)),
      ]),
    );
  }
}
