import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../auth/auth_controller.dart';
import '../extras/extras_repository.dart';
import '../wallet/wallet_repository.dart';

class VipScreen extends ConsumerStatefulWidget {
  const VipScreen({super.key});

  @override
  ConsumerState<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends ConsumerState<VipScreen> {
  bool _subscribing = false;

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final price = double.tryParse('${plan['price'] ?? 0}') ?? 0;
    final planName = plan['name'] ?? 'VIP Pass';
    final planId = (plan['id'] as num?)?.toInt() ?? 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        title: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Activate VIP Pass', style: AppText.h2),
          ],
        ),
        content: Text(
          'Confirm activating $planName for ${Fmt.taka(price)} from your wallet balance?',
          style: AppText.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppText.button.copyWith(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _subscribing = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await ref.read(extrasRepoProvider).vipSubscribe(planId);
      ref.invalidate(vipStatusProvider);
      ref.read(walletRefreshProvider.notifier).state++;
      ref.read(authControllerProvider.notifier).patchWallet(
            balance: double.tryParse('${res['balance'] ?? ''}'),
            winning: double.tryParse('${res['winning'] ?? ''}'),
          );

      if (mounted) {
        showSnack(context, '👑 ${res['plan_name']} activated successfully!', kind: SnackKind.success);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not activate VIP. Check your wallet balance.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(vipStatusProvider);
    final plansAsync = ref.watch(vipPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VIP Pass & Player Tier')),
      body: BzBackground(
        child: SafeArea(
          child: statusAsync.when(
            loading: () => const BzLoader(label: 'Loading VIP Status…'),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(vipStatusProvider)),
            data: (status) {
              final isVip = status['is_vip'] == true;
              final daysLeft = (status['days_left'] as num?)?.toInt() ?? 0;
              final planName = status['plan_name'] ?? 'Free Member';
              final discount = (status['discount_percent'] as num?)?.toInt() ?? 0;
              final tier = (status['tier'] as Map?)?.cast<String, dynamic>() ?? {};
              final tierName = tier['name'] ?? 'Rookie';
              final tierBadge = tier['badge'] ?? '🔰';
              final xp = (status['xp'] as num?)?.toInt() ?? 0;
              final nextXp = (tier['next_xp'] as num?)?.toInt();
              final progress = (tier['progress'] as num?)?.toDouble() ?? 0.0;
              final perks = ((status['perks'] as List?) ?? []).cast<String>();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  // VIP Status Card
                  BzCard(
                    glow: isVip ? AppColors.gold : null,
                    borderColor: isVip ? AppColors.gold.withValues(alpha: 0.5) : AppColors.line,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isVip ? AppColors.gold.withValues(alpha: 0.15) : AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isVip ? AppColors.gold : AppColors.line),
                              ),
                              child: Center(
                                child: Text(isVip ? '👑' : '🎮', style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    planName,
                                    style: AppText.h2.copyWith(
                                      color: isVip ? AppColors.gold : AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    isVip ? '$daysLeft days remaining • $discount% discount active' : 'Join VIP to unlock match discounts & priority perks',
                                    style: AppText.bodyS.copyWith(color: isVip ? AppColors.success : AppColors.textDim),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (perks.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.line, height: 1),
                          const SizedBox(height: 12),
                          ...perks.map((p) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 16),
                                    const SizedBox(width: 8),
                                    Text(p, style: AppText.bodyS),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Player Tier & XP Progress
                  BzCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(tierBadge, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(tierName, style: AppText.bodyStrong.copyWith(fontSize: 16)),
                              ],
                            ),
                            Text('$xp XP', style: AppText.bodyStrong.copyWith(color: AppColors.cyan)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: AppColors.bg2,
                            valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextXp != null ? '${nextXp - xp} XP needed for next rank' : 'Max Rank Reached! Grandmaster 👑',
                          style: AppText.bodyS.copyWith(color: AppColors.textDim, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Available VIP Passes', style: AppText.h2),
                  const SizedBox(height: 12),

                  plansAsync.when(
                    loading: () => const BzLoader(label: 'Loading VIP plans…'),
                    error: (e, _) => Text('Could not load plans: $e', style: AppText.bodyS),
                    data: (planData) {
                      final plans = ((planData['plans'] as List?) ?? []).cast<Map<String, dynamic>>();

                      return Column(
                        children: plans.map((p) {
                          final pName = p['name'] ?? '';
                          final pPrice = double.tryParse('${p['price'] ?? 0}') ?? 0;
                          final pDays = p['days'] ?? 30;
                          final pPerks = ((p['perks'] as List?) ?? []).cast<String>();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: BzCard(
                              padding: const EdgeInsets.all(16),
                              borderColor: AppColors.gold.withValues(alpha: 0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(pName, style: AppText.bodyStrong.copyWith(fontSize: 17, color: AppColors.gold)),
                                          Text('$pDays Days Validity', style: AppText.bodyS.copyWith(color: AppColors.textDim)),
                                        ],
                                      ),
                                      Text(
                                        Fmt.taka(pPrice),
                                        style: AppText.h2.copyWith(fontSize: 22, color: AppColors.primaryHi),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...pPerks.map((pk) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 15),
                                            const SizedBox(width: 6),
                                            Text(pk, style: AppText.bodyS.copyWith(fontSize: 12)),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 14),
                                  BzButton(
                                    label: 'ACTIVATE NOW',
                                    kind: BzBtn.primary,
                                    loading: _subscribing,
                                    onPressed: _subscribing ? null : () => _subscribe(p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
