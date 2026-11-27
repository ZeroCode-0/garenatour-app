import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../models/misc.dart';

final _referProvider = FutureProvider<ReferInfo>((ref) async {
  ref.keepAlive();
  final data = await ref.watch(apiClientProvider).get('/refer', useCache: true, cacheMaxAge: const Duration(minutes: 5));
  return ReferInfo.fromJson((data as Map).cast<String, dynamic>());
});

final _referralsProvider = FutureProvider<List<Referral>>((ref) async {
  ref.keepAlive();
  final data = await ref.watch(apiClientProvider).get('/refer/list', useCache: true, cacheMaxAge: const Duration(minutes: 5)) as Map<String, dynamic>;
  return (data['referrals'] as List).cast<Map<String, dynamic>>().map(Referral.fromJson).toList();
});

class ReferScreen extends ConsumerWidget {
  const ReferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(_referProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: info.when(
            loading: () => const BzLoader(),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(_referProvider)),
            data: (d) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                BzCard(
                  glow: AppColors.success,
                  borderColor: AppColors.success.withValues(alpha: 0.35),
                  child: Column(children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: const Icon(Icons.redeem_rounded, color: AppColors.success, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(d.bonusRule, style: AppText.bodyM, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(d.referCode, style: AppText.h1.copyWith(fontSize: 24, color: AppColors.cyan, letterSpacing: 4)),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () { Clipboard.setData(ClipboardData(text: d.referCode)); showSnack(context, 'Code copied', kind: SnackKind.success); },
                          child: const Icon(Icons.copy_rounded, color: AppColors.primaryHi, size: 20),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                BzButton(label: 'SHARE INVITE', icon: Icons.ios_share_rounded, onPressed: () => Share.share(d.shareText)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _stat('REFERRALS', '${d.totalRefer}', AppColors.cyan)),
                  const SizedBox(width: 12),
                  Expanded(child: _statMoney('EARNED', d.totalEarned, AppColors.gold)),
                ]),
                const SizedBox(height: 20),
                const SectionHeader('Your Referrals'),
                Consumer(builder: (context, ref, _) {
                  final list = ref.watch(_referralsProvider);
                  return list.when(
                    loading: () => const BzSkeletonList(itemHeight: 56, count: 2, padding: EdgeInsets.zero),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) => items.isEmpty
                        ? BzCard(child: Text('No one has joined with your code yet. Share it to start earning.', style: AppText.bodyM))
                        : Column(children: [
                            for (var i = 0; i < items.length; i++)
                              BzCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(children: [
                                  CircleAvatar(radius: 15, backgroundColor: AppColors.cardHi, child: Text(items[i].name.isNotEmpty ? items[i].name[0].toUpperCase() : '?', style: AppText.bodyS)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(items[i].name, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('Joined ${Fmt.relative(items[i].joinedAt)}', style: AppText.bodyS),
                                    ],
                                  )),
                                  Text('${Fmt.takaShort(items[i].deposited)} dep.', style: AppText.bodyS.copyWith(color: AppColors.text)),
                                ]),
                              ).stagger(i),
                          ]),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String l, String v, Color c) => BzCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [Text(l, style: AppText.label.copyWith(fontSize: 9.5)), const SizedBox(height: 4), Text(v, style: AppText.numXl.copyWith(color: c, fontSize: 20))]),
      );
  Widget _statMoney(String l, double v, Color c) => BzCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [Text(l, style: AppText.label.copyWith(fontSize: 9.5)), const SizedBox(height: 4), MoneyText(v, style: AppText.numXl.copyWith(color: c, fontSize: 20))]),
      );
}
