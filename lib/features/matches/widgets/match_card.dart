import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/match_banner.dart';
import '../../../models/match.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final GameMatch match;

  @override
  Widget build(BuildContext context) {
    final live = match.status == 'live';
    final completed = match.status == 'completed';
    final tag = '${(match.type ?? 'MATCH').replaceAll('_', ' ')} #${match.numId ?? match.matchKey.substring(0, 4).toUpperCase()}';

    return GestureDetector(
      onTap: () => context.push(
        completed && match.resultPublished ? '/match/${match.matchKey}/result' : '/match/${match.matchKey}',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppColors.cardGrad,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: match.joined ? AppColors.primary.withValues(alpha: 0.5) : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MatchBanner(typeCode: match.type, imageUrl: match.bannerUrl),
                  Positioned(top: 10, right: 10, child: _statePill(live, completed)),
                  Positioned(
                    left: 12, bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tag.toUpperCase(), style: AppText.label.copyWith(fontSize: 8.5, color: Colors.white70)),
                        Text(match.title, style: AppText.h3.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(match.typeName ?? '', style: AppText.bodyS.copyWith(color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _stat(Icons.groups_rounded, '${match.joinedSlots}/${match.totalSlots}'),
                      _stat(
                        Icons.schedule_rounded,
                        completed ? Fmt.dayMonth(match.startAt) : Fmt.matchTime(match.startAt),
                        child: (!completed && !live && match.startAtDate.difference(DateTime.now()).inHours < 24)
                            ? LiveCountdown(
                                match.startAtDate,
                                style: AppText.numM.copyWith(fontSize: 12, color: AppColors.cyan),
                                liveLabel: 'SOON',
                                liveStyle: AppText.numM.copyWith(fontSize: 12, color: AppColors.live),
                              )
                            : null,
                      ),
                      _stat(Icons.login_rounded, match.entryFee == 0 ? 'FREE' : Fmt.takaShort(match.entryFee)),
                      _stat(Icons.emoji_events_rounded, Fmt.takaShort(match.prizePool), color: AppColors.gold),
                    ],
                  ),
                  if (!completed) ...[
                    const SizedBox(height: 12),
                    FillBar(ratio: match.fillRatio, height: 5),
                    const SizedBox(height: 12),
                    _cta(context),
                  ] else if (match.myPrize != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Text('Your result', style: AppText.bodyS),
                      const Spacer(),
                      Text('${match.myKills ?? 0} kills  ·  ${Fmt.taka(match.myPrize)}', style: AppText.numM.copyWith(color: AppColors.gold)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statePill(bool live, bool completed) {
    if (match.joined) return const StatusPill('JOINED', color: AppColors.success, icon: Icons.check_rounded);
    if (live) return const StatusPill('LIVE', color: AppColors.live, pulse: true);
    if (completed) return StatusPill(match.resultPublished ? 'RESULT' : 'ENDED', color: AppColors.textMuted);
    return const StatusPill('UPCOMING', color: AppColors.primary);
  }

  Widget _stat(IconData i, String v, {Color? color, Widget? child}) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: child ??
                  Text(v, style: AppText.numM.copyWith(fontSize: 12, color: color ?? AppColors.text), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _cta(BuildContext context) {
    final (label, active) = match.joined
        ? ('VIEW MATCH', false)
        : match.isFull
            ? ('MATCH FULL', false)
            : match.status == 'live'
                ? ('JOINING CLOSED', false)
                : (match.entryFee == 0 ? 'JOIN FREE' : 'JOIN MATCH', true);
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: active ? AppColors.primaryGradH : null,
        color: active ? null : AppColors.cardHi,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: active ? Colors.transparent : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          if (active) const SizedBox(width: 6),
          Text(label, style: AppText.button.copyWith(fontSize: 12.5, color: active ? Colors.white : AppColors.textMuted)),
        ],
      ),
    );
  }
}
