import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_chip.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../models/wallet.dart';
import 'wallet_repository.dart';

final _txnProvider = FutureProvider.family<List<Txn>, String>((ref, type) async {
  ref.keepAlive();
  final r = await ref.watch(walletRepositoryProvider).transactions(type: type);
  return r.txns;
});

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _S();
}

class _S extends ConsumerState<TransactionsScreen> {
  String _type = 'deposit';
  static const _tabs = {'deposit': 'Deposits', 'withdraw': 'Withdraws', 'match': 'Matches'};

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(_txnProvider(_type));
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: Column(
            children: [
              BzChipRow(
                height: 46,
                children: [for (final t in _tabs.entries) BzChip(label: t.value, selected: _type == t.key, onTap: () => setState(() => _type = t.key))],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: txns.when(
                  loading: () => const BzSkeletonList(itemHeight: 64),
                  error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(_txnProvider(_type))),
                  data: (list) => list.isEmpty
                      ? BzEmpty(title: 'No ${_tabs[_type]!.toLowerCase()} yet', icon: Icons.receipt_long_rounded)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.cardHi,
                          onRefresh: () async => ref.invalidate(_txnProvider(_type)),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: list.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _Row(t: list[i], type: _type).stagger(i),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.t, required this.type});
  final Txn t;
  final String type;
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'deposit' => (Icons.south_west_rounded, AppColors.success),
      'withdraw' => (Icons.north_east_rounded, AppColors.warning),
      _ => (Icons.sports_esports_rounded, AppColors.primaryHi),
    };
    final statusColor = switch (t.status) {
      'paid' || 'success' || 'completed' => AppColors.success,
      'pending' || 'upcoming' || 'live' => AppColors.warning,
      'rejected' || 'cancelled' => AppColors.danger,
      _ => AppColors.textMuted,
    };
    return BzCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'match' ? t.title : (t.title.isEmpty ? type : t.title[0].toUpperCase() + t.title.substring(1)),
              style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text('${t.ref.isNotEmpty ? '${t.ref} · ' : ''}${Fmt.relative(t.at)}', style: AppText.bodyS),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.taka(t.amount), style: AppText.numM.copyWith(fontSize: 13)),
            if (t.status.isNotEmpty)
              Text(t.status.toUpperCase(), style: AppText.label.copyWith(fontSize: 8.5, color: statusColor)),
          ],
        ),
      ]),
    );
  }
}
