import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../models/wallet.dart';
import 'wallet_repository.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(walletSummaryProvider);
    final recent = ref.watch(recentTxnProvider);

    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.cardHi,
            onRefresh: () async => ref.read(walletRefreshProvider.notifier).state++,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                Text('Wallet', style: AppText.h1.copyWith(fontSize: 26)),
                const SizedBox(height: 16),
                summary.valueOrNull != null
                    ? Row(children: [
                        Expanded(child: MoneyTile(label: 'Deposit Balance', value: summary.value!.balance, accent: AppColors.cyan, icon: Icons.account_balance_wallet_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: MoneyTile(label: 'Winning Balance', value: summary.value!.winning, accent: AppColors.gold, icon: Icons.emoji_events_rounded)),
                      ])
                    : summary.when(
                        loading: () => const BzSkeletonList(itemHeight: 96, count: 1, padding: EdgeInsets.zero),
                        error: (e, _) => BzCard(child: Text('$e', style: AppText.bodyM)),
                        data: (s) => Row(children: [
                          Expanded(child: MoneyTile(label: 'Deposit Balance', value: s.balance, accent: AppColors.cyan, icon: Icons.account_balance_wallet_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: MoneyTile(label: 'Winning Balance', value: s.winning, accent: AppColors.gold, icon: Icons.emoji_events_rounded)),
                        ]),
                      ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: BzButton(label: 'DEPOSIT', icon: Icons.add_rounded, onPressed: () => context.push('/deposit'))),
                  const SizedBox(width: 12),
                  Expanded(child: BzButton(label: 'WITHDRAW', icon: Icons.arrow_outward_rounded, kind: BzBtn.ghost, onPressed: () => context.push('/withdraw'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: BzButton(label: 'SHARE', icon: Icons.swap_horiz_rounded, kind: BzBtn.ghost, onPressed: () => context.push('/share'))),
                  const SizedBox(width: 12),
                  Expanded(child: BzButton(label: 'PROMO', icon: Icons.card_giftcard_rounded, kind: BzBtn.gold, onPressed: () => context.push('/promo'))),
                ]),
                const SizedBox(height: 24),
                const SectionHeader('About Your Wallets'),
                BzCard(
                  child: Column(children: [
                    _walletInfo(AppColors.cyan, 'Deposit Balance', 'Money you add via bKash / Nagad / Rocket. Used to join matches. Cannot be withdrawn directly.'),
                    const Divider(height: 22),
                    _walletInfo(AppColors.gold, 'Winning Balance', 'Prize money from matches. Withdraw once per day to your mobile wallet.'),
                  ]),
                ),
                const SizedBox(height: 20),
                SectionHeader('Recent Transactions', actionLabel: 'See All', onAction: () => context.push('/transactions')),
                recent.valueOrNull != null
                    ? (recent.value!.isEmpty
                        ? BzCard(child: Text('No transactions yet.', style: AppText.bodyM))
                        : Column(children: [for (var i = 0; i < recent.value!.length; i++) _TxnRow(t: recent.value![i]).stagger(i)]))
                    : recent.when(
                        loading: () => const BzSkeletonList(itemHeight: 56, count: 3, padding: EdgeInsets.zero),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (list) => list.isEmpty
                            ? BzCard(child: Text('No transactions yet.', style: AppText.bodyM))
                            : Column(children: [for (var i = 0; i < list.length; i++) _TxnRow(t: list[i]).stagger(i)]),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletInfo(Color c, String title, String body) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 5), width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyStrong),
              const SizedBox(height: 3),
              Text(body, style: AppText.bodyS.copyWith(height: 1.5)),
            ],
          )),
        ],
      );
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.t});
  final Txn t;
  @override
  Widget build(BuildContext context) {
    final credit = t.kind == 'deposit' || (t.kind != 'match' && t.title.toLowerCase().contains('winning'));
    final isMatch = t.kind == 'match';
    final sign = isMatch ? '−' : (credit ? '+' : '−');
    final col = isMatch ? AppColors.danger : (credit ? AppColors.success : AppColors.danger);
    final label = isMatch ? 'Match Entry' : (t.kind == 'deposit' ? 'Deposit' : (t.kind == 'withdraw' ? 'Withdraw' : (credit ? 'Winning' : 'Debit')));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text('$sign${Fmt.taka(t.amount)}', style: AppText.numM.copyWith(color: col, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.bodyStrong),
            Text(Fmt.relative(t.at), style: AppText.bodyS),
          ],
        )),
        if (t.status.isNotEmpty)
          Text(t.status[0].toUpperCase() + t.status.substring(1),
              style: AppText.bodyS.copyWith(
                color: switch (t.status) { 'paid' || 'success' || 'completed' => AppColors.success, 'pending' => AppColors.warning, _ => AppColors.textMuted },
              )),
      ]),
    );
  }
}
