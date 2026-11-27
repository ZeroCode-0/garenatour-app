import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/gt_shapes.dart';
import '../extras/extras_repository.dart';
import '../wallet/wallet_repository.dart';
import 'rewarded_ad.dart';

/// Google's official test unit — used until the admin sets a real one.
const _testUnitAndroid = 'ca-app-pub-3940256099942544/5224354917';
const _testUnitIos = 'ca-app-pub-3940256099942544/1712485313';

class EarnScreen extends ConsumerStatefulWidget {
  const EarnScreen({super.key});
  @override
  ConsumerState<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends ConsumerState<EarnScreen> {
  bool _watching = false;
  bool _redeeming = false;

  Future<void> _watch(Map<String, dynamic> info) async {
    setState(() => _watching = true);
    final repo = ref.read(extrasRepoProvider);
    try {
      final s = await repo.adSession();
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      String unit = '${ios ? s['ad_unit_ios'] : s['ad_unit_android']}';
      if (unit.isEmpty || unit == 'null') unit = ios ? _testUnitIos : _testUnitAndroid;

      final earned = await showRewardedAd(adUnitId: unit, userId: '${s['ssv_user_id']}', nonce: '${s['nonce']}');
      if (!earned) {
        if (mounted) showSnack(context, 'Watch the full ad to earn coins.');
        return;
      }
      // Google's server confirms the view to our server — poll briefly for it.
      var status = 'issued';
      for (var i = 0; i < 8 && status == 'issued'; i++) {
        await Future.delayed(Duration(milliseconds: 900 + i * 300));
        status = '${(await repo.adStatus('${s['nonce']}'))['status']}';
      }
      ref.read(extrasRefreshProvider.notifier).state++;
      if (!mounted) return;
      if (status == 'rewarded') {
        HapticFeedback.mediumImpact();
        showSnack(context, '+${s['coins']} coins added! 🪙', kind: SnackKind.success);
      } else {
        showSnack(context, 'Coins will appear in a moment after verification.');
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (e) {
      if (mounted) showSnack(context, '$e'.replaceFirst('Exception: ', ''), kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _watching = false);
    }
  }

  Future<void> _redeem(int coins) async {
    setState(() => _redeeming = true);
    try {
      final r = await ref.read(extrasRepoProvider).redeem(coins);
      ref.read(extrasRefreshProvider.notifier).state++;
      ref.read(walletRefreshProvider.notifier).state++;
      if (mounted) showSnack(context, '${Fmt.taka(r['credited'])} added to your deposit balance', kind: SnackKind.success);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(earnProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Earn Coins')),
      body: BzBackground(
        child: data.when(
          loading: () => const BzLoader(),
          error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(earnProvider)),
          data: (d) {
            final coins = (d['coins'] as num).toInt();
            final rate = (d['coins_per_taka'] as num).toInt();
            final minR = (d['min_redeem'] as num).toInt();
            final today = (d['ads_today'] as num).toInt();
            final cap = (d['ads_per_day'] as num).toInt();
            final history = (d['history'] as List).cast<Map>();
            final canWatch = d['enabled'] == true && today < cap;
            final redeemable = coins >= minR;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                GtCutCard(
                  glow: AppColors.gold,
                  gradient: LinearGradient(colors: [const Color(0xFF3A1C05), AppColors.card], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 46),
                    const SizedBox(height: 6),
                    Text('$coins', style: AppText.numXl.copyWith(fontSize: 42, color: AppColors.gold)),
                    Text('YOUR COINS  ·  ≈ ${Fmt.taka(d['coins_value'])}', style: AppText.label),
                    const SizedBox(height: 16),
                    FillBar(ratio: cap == 0 ? 0 : today / cap),
                    const SizedBox(height: 6),
                    Text('Ads today: $today / $cap', style: AppText.bodyS),
                  ]),
                ),
                const SizedBox(height: 16),
                BzButton(
                  label: canWatch ? 'WATCH AD  ·  +${d['coins_per_ad']} COINS' : (d['enabled'] == true ? 'DAILY LIMIT REACHED' : 'EARN IS OFF'),
                  icon: Icons.play_circle_fill_rounded,
                  kind: BzBtn.gold,
                  loading: _watching,
                  onPressed: canWatch && !_watching ? () => _watch(d) : null,
                ),
                const SizedBox(height: 10),
                BzButton(
                  label: redeemable ? 'REDEEM $coins COINS → ${Fmt.taka((coins / rate * 100).floor() / 100)}' : 'REDEEM (min $minR coins)',
                  icon: Icons.currency_exchange_rounded,
                  kind: BzBtn.ghost,
                  loading: _redeeming,
                  onPressed: redeemable && !_redeeming ? () => _redeem(coins) : null,
                ),
                const SizedBox(height: 10),
                BzButton(
                  label: 'PLAY LUCKY SPIN WHEEL 🎡',
                  icon: Icons.casino_rounded,
                  kind: BzBtn.ghost,
                  onPressed: () => context.push('/spin'),
                ),
                const SizedBox(height: 22),
                const SectionHeader('How it works'),
                _step('1', 'Watch a short ad to the end.'),
                _step('2', 'Coins are verified by Google and added to you.'),
                _step('3', '$rate coins = ৳1. Redeem from $minR coins into your deposit balance and join matches.'),
                const SizedBox(height: 18),
                if (history.isNotEmpty) ...[
                  const SectionHeader('Coin history'),
                  for (final h in history.take(15))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Text('${h['direction'] == 'credit' ? '+' : '−'}${h['coins']}',
                            style: AppText.numM.copyWith(color: h['direction'] == 'credit' ? AppColors.success : AppColors.danger)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${h['note'] ?? h['type']}', style: AppText.bodyM, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(Fmt.relative('${h['created_at']}'), style: AppText.tiny),
                      ]),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _step(String n, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 24, height: 24, alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(n, style: AppText.button.copyWith(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(t, style: AppText.bodyM)),
        ]),
      );
}
