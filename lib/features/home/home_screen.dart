import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/format.dart';
import '../../core/launch.dart';
import '../../core/network/api_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/match_banner.dart';
import '../../core/widgets/mode_visual.dart';
import '../../core/widgets/gt_shapes.dart';
import '../extras/extras_repository.dart';
import '../../models/match.dart';
import '../../models/misc.dart' as models;
import '../notifications/notifications_controller.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.cardHi,
            onRefresh: () async {
              await ApiCache.invalidate('GET:/home:{}');
              ref.invalidate(homeProvider);
              ref.invalidate(featuredMatchProvider);
              ref.read(notificationsRefreshProvider.notifier).state++;
            },
            child: home.valueOrNull != null
                ? _Body(d: home.value!, unread: unread)
                : home.when(
                    skipLoadingOnRefresh: true,
                    skipLoadingOnReload: true,
                    loading: () => ListView(children: const [SizedBox(height: 140), BzLoader(label: 'Loading arena…')]),
                    error: (e, _) => home.hasValue
                        ? _Body(d: home.value!, unread: unread)
                        : ListView(children: [const SizedBox(height: 90), BzError(message: '$e', onRetry: () => ref.invalidate(homeProvider))]),
                    data: (d) => _Body(d: d, unread: unread),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.d, required this.unread});
  final HomeData d;
  final int unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = d.featuredMatch ?? ref.watch(featuredMatchProvider).valueOrNull;
    final total = (double.tryParse(d.balance) ?? 0) + (double.tryParse(d.winning) ?? 0);
    final supportUnread = d.unreadSupport > 0 ? d.unreadSupport : (ref.watch(supportUnreadProvider).valueOrNull ?? 0);
    final effectiveUnread = d.unreadNotifications > 0 ? d.unreadNotifications : unread;
    final quick = <Widget>[
      GtQuickTile(icon: Icons.diamond_rounded, label: 'DIAMOND', color: const Color(0xFF4DA3FF), onTap: () => context.push('/diamond')),
      GtQuickTile(icon: Icons.workspace_premium_rounded, label: 'VIP PASS', color: AppColors.gold, onTap: () => context.push('/vip')),
      GtQuickTile(icon: Icons.casino_rounded, label: 'SPIN & WIN', color: const Color(0xFFFF5252), onTap: () => context.push('/spin')),
      GtQuickTile(icon: Icons.shopping_bag_rounded, label: 'SHOP', onTap: () => context.go('/shop')),
      GtQuickTile(icon: Icons.monetization_on_rounded, label: 'EARN', color: AppColors.gold, onTap: () => context.push('/earn')),
      GtQuickTile(icon: Icons.swap_horiz_rounded, label: 'SHARE', color: const Color(0xFF38D18B), onTap: () => context.push('/share')),
      GtQuickTile(icon: Icons.card_giftcard_rounded, label: 'PROMO', color: const Color(0xFFFF8A3D), onTap: () => context.push('/promo')),
      GtQuickTile(icon: Icons.group_add_rounded, label: 'REFER', color: const Color(0xFFB36BFF), onTap: () => context.push('/refer')),
      GtQuickTile(icon: Icons.sports_esports_rounded, label: 'MATCHES', color: const Color(0xFF3B82F6), onTap: () => context.go('/matches')),
      GtQuickTile(icon: Icons.leaderboard_rounded, label: 'TOP', color: AppColors.gold, onTap: () => context.push('/leaderboard')),
      GtQuickTile(icon: Icons.history_rounded, label: 'HISTORY', color: const Color(0xFF10B981), onTap: () => context.push('/transactions')),
      GtQuickTile(icon: Icons.support_agent_rounded, label: 'SUPPORT', badge: supportUnread, onTap: () => context.push('/support')),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      children: [
        _Header(name: d.name, avatar: d.avatarUrl, unread: effectiveUnread),
        const SizedBox(height: 16),
        _WalletHero(total: total, balance: d.balance, winning: d.winning, coins: d.coins)
            .animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
        if ((d.marquee.isNotEmpty) || d.notice.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NoticeBar(text: d.marquee.isNotEmpty ? d.marquee : d.notice),
        ],
        if (d.sliders.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SliderCarousel(slides: d.sliders).animate().fadeIn(duration: 350.ms),
        ],
        const SizedBox(height: 20),
        const GtSectionTitle('Quick Actions'),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.86,
          children: [for (var i = 0; i < quick.length; i++) quick[i].stagger(i)],
        ),
        const SizedBox(height: 22),
        GtSectionTitle('Featured Tournament', action: 'VIEW ALL', onAction: () => context.go('/matches')),
        if (featured != null)
          _FeaturedCard(m: featured).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.98, end: 1)
        else
          BzCard(child: Row(children: [
            const Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('No tournament running right now', style: AppText.bodyM),
          ])),
        const SizedBox(height: 22),
        GtSectionTitle('Game Modes', action: 'VIEW ALL', onAction: () => context.go('/matches')),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            for (var i = 0; i < d.matchTypes.length; i++)
              _ModeCard(t: d.matchTypes[i]).stagger(i),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.avatar, required this.unread});
  final String name;
  final String? avatar;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGrad),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardHi,
            backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar!) : null,
            child: avatar == null ? const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 20) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetalText('GARENA TOUR', style: AppText.h3.copyWith(fontSize: 19, letterSpacing: 1.5, height: 1.1)),
              Text('Hi, $name 👋', style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                child: const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.text),
              ),
              if (unread > 0)
                Positioned(
                  right: -3, top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text('${unread > 9 ? '9+' : unread}',
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: AppText.body),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.total, required this.balance, required this.winning, required this.coins});
  final double total;
  final String balance, winning;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return GtCutCard(
      cut: 22,
      glow: AppColors.primary,
      border: AppColors.primary.withValues(alpha: .45),
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        colors: [Color(0xFF5A0610), Color(0xFF2A070C), Color(0xFF140609)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      child: Stack(children: [
        Positioned(
          right: -18, top: -10,
          child: Icon(Icons.local_fire_department_rounded, size: 130, color: AppColors.primary.withValues(alpha: .10)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('TOTAL BALANCE', style: AppText.label.copyWith(color: AppColors.textDim)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/earn'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text('$coins', style: AppText.numM.copyWith(fontSize: 12, color: AppColors.gold)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 2),
            MetalText(Fmt.taka(total), style: AppText.numXl.copyWith(fontSize: 34)),
            const SizedBox(height: 12),
            Row(children: [
              _mini('Deposit', Fmt.taka(balance), AppColors.text),
              Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 14), color: AppColors.line),
              _mini('Winning', Fmt.taka(winning), AppColors.gold),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _btn(context, Icons.add_rounded, 'ADD MONEY', '/deposit', true)),
              const SizedBox(width: 10),
              Expanded(child: _btn(context, Icons.arrow_outward_rounded, 'WITHDRAW', '/withdraw', false)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _mini(String l, String v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.toUpperCase(), style: AppText.tiny.copyWith(letterSpacing: 1)),
        Text(v, style: AppText.numM.copyWith(color: c, fontSize: 15)),
      ]);

  Widget _btn(BuildContext context, IconData i, String l, String to, bool primary) => Material(
        color: primary ? AppColors.primary : Colors.white.withValues(alpha: .06),
        shape: gtCutShape(cut: 8, side: primary ? null : AppColors.line),
        child: InkWell(
          customBorder: gtCutShape(cut: 8),
          onTap: () => context.push(to),
          child: SizedBox(
            height: 42,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(l, style: AppText.button.copyWith(fontSize: 13)),
            ]),
          ),
        ),
      );
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, size: 15, color: AppColors.primaryHi),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.bodyS.copyWith(color: AppColors.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.m});
  final GameMatch m;

  @override
  Widget build(BuildContext context) {
    final live = m.status == 'live';
    return GestureDetector(
      onTap: () => context.push('/match/${m.matchKey}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.rCard),
          border: Border.all(color: AppColors.line),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 26, spreadRadius: -6)],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: MatchBanner(typeCode: m.type, imageUrl: m.bannerUrl)),
            Positioned(top: 12, right: 12, child: StatusPill(live ? 'LIVE' : 'UPCOMING', color: live ? AppColors.live : AppColors.primary, pulse: live)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 46),
                  Text((m.typeName ?? m.type ?? '').toUpperCase(), style: AppText.label.copyWith(fontSize: 10)),
                  Text(m.title, style: AppText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _fStat('PRIZE POOL', Fmt.taka(m.prizePool), AppColors.gold),
                      const SizedBox(width: 24),
                      _fStat('ENTRY FEE', m.entryFee == 0 ? 'FREE' : Fmt.taka(m.entryFee), AppColors.cyan),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 14, color: AppColors.textDim),
                      const SizedBox(width: 5),
                      Text('${m.joinedSlots}/${m.totalSlots} Players', style: AppText.bodyS),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textDim),
                      const SizedBox(width: 5),
                      if (live)
                        Text('Live now', style: AppText.bodyS.copyWith(color: AppColors.live))
                      else
                        LiveCountdown(
                          m.startAtDate,
                          prefix: 'in ',
                          style: AppText.bodyS.copyWith(color: AppColors.cyan),
                          liveLabel: 'Starting…',
                          liveStyle: AppText.bodyS.copyWith(color: AppColors.live),
                        ),
                      const Spacer(),
                      _joinPill(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fStat(String l, String v, Color c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: AppText.label.copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Text(v, style: AppText.numL.copyWith(fontSize: 16, color: c)),
        ],
      );

  Widget _joinPill(BuildContext context) {
    final label = m.joined ? 'JOINED' : (m.isFull ? 'FULL' : 'JOIN NOW');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: m.joined || m.isFull ? null : AppColors.primaryGradH,
        color: m.joined || m.isFull ? AppColors.cardHi : null,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: m.joined || m.isFull ? AppColors.line : Colors.transparent),
      ),
      child: Text(label, style: AppText.button.copyWith(fontSize: 12, color: m.joined || m.isFull ? AppColors.textMuted : Colors.white)),
    );
  }
}

/// Promo banners set by the admin. Each slide can carry a link that opens
/// externally on tap. Auto-advances locally (no network) and pauses on touch.
class _SliderCarousel extends StatefulWidget {
  const _SliderCarousel({required this.slides});
  final List<models.Slider> slides;

  @override
  State<_SliderCarousel> createState() => _SliderCarouselState();
}

class _SliderCarouselState extends State<_SliderCarousel> {
  final _ctrl = PageController(viewportFraction: 0.88);
  Timer? _auto;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) _startAuto();
  }

  void _startAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final next = (_page + 1) % widget.slides.length;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        SizedBox(
          height: 188,
          // bleed past the page's 16px side padding so slides run edge-to-edge
          child: OverflowBox(
            maxWidth: w,
            child: SizedBox(
              width: w,
              child: Listener(
                onPointerDown: (_) => _auto?.cancel(),
                onPointerUp: (_) => slides.length > 1 ? _startAuto() : null,
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final s = slides[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: s.link.trim().isEmpty ? null : () => openLink(context, s.link),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.rCard),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 22, spreadRadius: -8)],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: s.image,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                            memCacheHeight: 360,
                            maxWidthDiskCache: 1200,
                            fadeInDuration: const Duration(milliseconds: 250),
                            placeholder: (_, __) => Container(color: AppColors.cardHi),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.cardHi,
                              child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted),
                            ),
                          ),
                          if (s.link.trim().isNotEmpty)
                            const Positioned(
                              right: 10, bottom: 10,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: _page,
            count: slides.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 5,
              dotWidth: 5,
              expansionFactor: 3.4,
              spacing: 5,
              activeDotColor: AppColors.primaryHi,
              dotColor: AppColors.line,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.t});
  final dynamic t; // MatchType

  @override
  Widget build(BuildContext context) {
    final v = ModeVisual.of(t.code as String);
    return GestureDetector(
      onTap: () => context.push('/matches/${t.code}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MatchBanner(typeCode: t.code as String, imageUrl: t.cardImage as String?),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(v.icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.glyph, style: AppText.h1.copyWith(fontSize: 24, color: Colors.white)),
                      const SizedBox(height: 1),
                      Text('${t.name}'.toUpperCase(),
                          style: AppText.label.copyWith(fontSize: 8.5, color: Colors.white70, letterSpacing: 0.6),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),
            if ((t.liveCount as int) > 0)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(999)),
                  child: Text('${t.liveCount}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: AppText.body)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

