import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_segmented.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/match_banner.dart';
import '../../core/widgets/match_icons.dart';
import '../../models/match.dart';
import 'match_detail_controller.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.matchKey});
  final String matchKey;
  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(matchDetailProvider(widget.matchKey));
    return Scaffold(
      body: BzBackground(
        child: detail.when(
          loading: () => const SafeArea(child: BzLoader()),
          error: (e, _) => SafeArea(child: BzError(message: '$e', onRetry: () => ref.invalidate(matchDetailProvider(widget.matchKey)))),
          data: (m) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardHi,
                  onRefresh: () async {
                    ref.invalidate(matchDetailProvider(widget.matchKey));
                    ref.invalidate(matchPlayersProvider(widget.matchKey));
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _Hero(m: m),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _tag(m),
                              const SizedBox(width: 8),
                              Text(m.map, style: AppText.bodyS),
                              if (m.platform != null) ...[const SizedBox(width: 8), Text('· ${m.platform}', style: AppText.bodyS)],
                            ]),
                            const SizedBox(height: 14),
                            _statStrip(m),
                            const SizedBox(height: 16),
                            BzSegmented(
                              tabs: const ['Overview', 'Players', 'Rules', 'Rewards'],
                              index: _tab,
                              onChanged: (i) => setState(() => _tab = i),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _tabBody(m),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BottomBar(m: m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(GameMatch m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          '${(m.type ?? 'MATCH').replaceAll('_', ' ')} #${m.numId ?? m.matchKey.substring(0, 4).toUpperCase()}'.toUpperCase(),
          style: AppText.label.copyWith(fontSize: 9.5, color: AppColors.primaryHi),
        ),
      );

  Widget _statStrip(GameMatch m) {
    final up = m.status == 'upcoming';
    return BzCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          MiniStatWrap('PLAYERS', '${m.joinedSlots}/${m.totalSlots}'),
          _div(),
          MiniStatWrap(
            up ? 'STARTS IN' : 'TIME',
            up ? '' : Fmt.matchTime(m.startAt),
            color: up ? AppColors.cyan : null,
            valueWidget: up
                ? LiveCountdown(
                    m.startAtDate,
                    style: AppText.numM.copyWith(fontSize: 13, color: AppColors.cyan),
                    liveLabel: 'LIVE',
                    liveStyle: AppText.numM.copyWith(fontSize: 13, color: AppColors.live),
                  )
                : null,
          ),
          _div(),
          MiniStatWrap('ENTRY', m.entryFee == 0 ? 'FREE' : Fmt.taka(m.entryFee)),
          _div(),
          MiniStatWrap('PRIZE', Fmt.takaShort(m.prizePool), color: AppColors.gold),
        ],
      ),
    );
  }

  Widget _div() => Container(width: 1, height: 30, color: AppColors.line);

  Widget _tabBody(GameMatch m) {
    switch (_tab) {
      case 1:
        return _PlayersTab(key: const ValueKey(1), matchKey: widget.matchKey, m: m);
      case 2:
        return _TextCard(key: const ValueKey(2), title: 'Match Rules', body: (m.rules ?? '').trim().isEmpty ? 'Standard fair-play rules apply.' : m.rules!.trim());
      case 3:
        return _RewardsTab(key: const ValueKey(3), m: m);
      default:
        return _OverviewTab(key: const ValueKey(0), m: m);
    }
  }
}

class MiniStatWrap extends StatelessWidget {
  const MiniStatWrap(this.label, this.value, {super.key, this.color, this.valueWidget});
  final String label, value;
  final Color? color;
  final Widget? valueWidget;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          valueWidget ??
              Text(value, style: AppText.numM.copyWith(fontSize: 13, color: color ?? AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(label, style: AppText.label.copyWith(fontSize: 8.5)),
        ]),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.m});
  final GameMatch m;
  @override
  Widget build(BuildContext context) {
    final live = m.status == 'live';
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MatchBanner(typeCode: m.type, imageUrl: m.bannerUrl),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  _circleBtn(Icons.ios_share_rounded, () => Share.share('Join "${m.title}" on Garena Tour — ${Env.siteUrl}')),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(live ? 'LIVE' : m.status.toUpperCase(), color: live ? AppColors.live : AppColors.primary, pulse: live),
                const SizedBox(height: 8),
                Text((m.typeName ?? m.type ?? '').toUpperCase(), style: AppText.label.copyWith(fontSize: 10)),
                Text(m.title, style: AppText.h1.copyWith(fontSize: 24), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData i, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
          child: Icon(i, size: 19, color: Colors.white),
        ),
      );
}

/// parse "1st Prize ৳500 / 2nd ৳300 …" style breakdowns out of prize_details
List<(String, String)> _prizeRows(String? details) {
  final out = <(String, String)>[];
  final text = (details ?? '').replaceAll(RegExp(r'[^\S\r\n]+'), ' ');
  for (final line in text.split(RegExp(r'[\n•]'))) {
    final l = line.trim();
    if (l.isEmpty) continue;
    final money = RegExp(r'(?:৳|Tk|BDT)\s*([\d,]+)', caseSensitive: false).firstMatch(l);
    if (money == null) continue;
    final label = l.replaceAll(money.group(0)!, '').replaceAll(RegExp(r'[–\-:|]+\s*$'), '').trim();
    out.add((label.isEmpty ? 'Prize' : label, '৳${money.group(1)!.replaceAll(',', '')}'));
  }
  return out;
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({super.key, required this.m});
  final GameMatch m;
  @override
  Widget build(BuildContext context) {
    final rows = m.rewards.isNotEmpty
        ? [for (final r in m.rewards) (r.label, r.amount.contains(RegExp(r'[৳$%]')) ? r.amount : Fmt.taka(double.tryParse(r.amount) ?? 0))]
        : _prizeRows(m.prizeDetails);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty) ...[
          const SectionHeader('Prize Breakdown'),
          BzCard(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  Row(children: [
                    _rankBadge(i + 1),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rows[i].$1, style: AppText.bodyStrong)),
                    Text(rows[i].$2, style: AppText.numM.copyWith(color: AppColors.gold)),
                  ]),
                  if (i != rows.length - 1) const Divider(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SectionHeader('About Tournament'),
        BzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: m.overview.isNotEmpty
                ? [
                    for (var i = 0; i < m.overview.length; i++) ...[
                      _iconBullet(m.overview[i].icon, m.overview[i].text),
                      if (i != m.overview.length - 1) const SizedBox(height: 6),
                    ],
                  ]
                : [
                    _bullet('Only ${m.totalSlots} players can join'),
                    _bullet('${m.teamLabel} mode on ${m.map}'),
                    if (m.perKill > 0) _bullet('${Fmt.taka(m.perKill)} per kill'),
                    _bullet('No hacker or emulator allowed'),
                    _bullet('Fair play is our first priority'),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _iconBullet(String iconKey, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(matchIcon(iconKey), size: 15, color: AppColors.primaryHi),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.bodyM)),
        ]),
      );

  Widget _rankBadge(int n) {
    final c = switch (n) { 1 => AppColors.gold, 2 => const Color(0xFFC7C7D1), 3 => const Color(0xFFCD7F45), _ => AppColors.textMuted };
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: 0.5))),
      alignment: Alignment.center,
      child: Text('$n', style: AppText.numM.copyWith(fontSize: 12, color: c)),
    );
  }

  Widget _bullet(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.only(top: 6), width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primaryHi, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(s, style: AppText.bodyM)),
        ]),
      );
}

class _RewardsTab extends StatelessWidget {
  const _RewardsTab({super.key, required this.m});
  final GameMatch m;
  @override
  Widget build(BuildContext context) {
    final admin = m.rewards; // admin-defined reward rows
    final parsed = _prizeRows(m.prizeDetails);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KV('Prize pool', Fmt.taka(m.prizePool), valueStyle: AppText.numM.copyWith(color: AppColors.gold)),
              const Divider(height: 16),
              KV('Per kill', m.perKill == 0 ? '—' : Fmt.taka(m.perKill)),
            ],
          ),
        ),
        if (admin.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Reward Breakdown'),
          BzCard(
            child: Column(
              children: [
                for (var i = 0; i < admin.length; i++) ...[
                  Row(children: [
                    Icon(matchIcon(admin[i].icon), size: 17, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(child: Text(admin[i].label, style: AppText.bodyStrong)),
                    Text(
                      admin[i].amount.contains(RegExp(r'[৳$%]')) ? admin[i].amount : Fmt.taka(double.tryParse(admin[i].amount) ?? 0),
                      style: AppText.numM.copyWith(color: AppColors.gold),
                    ),
                  ]),
                  if (i != admin.length - 1) const Divider(height: 18),
                ],
              ],
            ),
          ),
        ] else if (parsed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Reward Breakdown'),
          BzCard(
            child: Column(children: [
              for (final r in parsed) KV(r.$1, r.$2, valueStyle: AppText.numM.copyWith(color: AppColors.gold)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({super.key, required this.title, required this.body});
  final String title, body;
  @override
  Widget build(BuildContext context) => BzCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: AppText.label.copyWith(color: AppColors.text)),
            const SizedBox(height: 10),
            Text(body, style: AppText.bodyM),
          ],
        ),
      );
}

class _PlayersTab extends ConsumerWidget {
  const _PlayersTab({super.key, required this.matchKey, required this.m});
  final String matchKey;
  final GameMatch m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(matchPlayersProvider(matchKey));
    return players.when(
      loading: () => const SizedBox(height: 60, child: BzLoader()),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.locked) {
          return BzCard(child: Row(children: [
            const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(child: Text('Join the match to see the player lobby.', style: AppText.bodyS)),
          ]));
        }
        if (data.players.isEmpty) {
          return BzCard(child: Text('No players yet — be the first to join.', style: AppText.bodyM));
        }
        return BzCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < data.players.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  child: Row(children: [
                    Text('${i + 1}'.padLeft(2, '0'), style: AppText.numM.copyWith(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data.players[i].ign, style: AppText.bodyM.copyWith(color: AppColors.text))),
                    if (data.players[i].kills > 0)
                      Text('${data.players[i].kills} K', style: AppText.numM.copyWith(fontSize: 12, color: AppColors.gold)),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.m});
  final GameMatch m;
  @override
  Widget build(BuildContext context) {
    Widget btn;
    if (m.status == 'completed') {
      btn = BzButton(
        label: m.resultPublished ? 'VIEW RESULT' : 'AWAITING RESULT',
        icon: Icons.emoji_events_rounded,
        onPressed: m.resultPublished ? () => context.push('/match/${m.matchKey}/result') : null,
      );
    } else if (m.joined) {
      btn = BzButton(label: 'YOU HAVE JOINED', icon: Icons.check_circle_rounded, kind: BzBtn.ghost, onPressed: () {});
    } else if (m.isFull) {
      btn = const BzButton(label: 'TOURNAMENT FULL', kind: BzBtn.ghost, onPressed: null);
    } else if (m.status == 'live') {
      btn = const BzButton(label: 'JOINING CLOSED', kind: BzBtn.ghost, onPressed: null);
    } else {
      btn = BzButton(
        label: m.entryFee == 0 ? 'JOIN TOURNAMENT — FREE' : 'JOIN TOURNAMENT',
        icon: Icons.bolt_rounded,
        onPressed: () => context.push('/match/${m.matchKey}/join'),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(color: AppColors.bg2, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(top: false, child: btn),
    );
  }
}
