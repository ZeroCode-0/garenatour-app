import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../../models/wallet.dart';
import 'bz_card.dart';
import 'bz_snack.dart';
import 'common.dart';

IconData txnIcon(String kind) => switch (kind) {
      'deposit' => Icons.south_west_rounded,
      'withdraw' => Icons.north_east_rounded,
      'match' => Icons.sports_esports_rounded,
      'refer' => Icons.redeem_rounded,
      'bonus' => Icons.card_giftcard_rounded,
      'refund' => Icons.replay_rounded,
      _ => Icons.receipt_long_rounded,
    };

({String label, Color color, String sign}) txnFace(Txn t) {
  final credit = switch (t.kind) {
    'deposit' || 'refer' || 'bonus' || 'refund' => true,
    'withdraw' || 'match' => false,
    _ => !t.title.toLowerCase().contains('debit'),
  };
  return (
    label: switch (t.kind) {
      'deposit' => 'Deposit',
      'withdraw' => 'Withdrawal',
      'match' => 'Match Entry',
      'refer' => 'Referral Bonus',
      'bonus' => 'Bonus',
      'refund' => 'Refund',
      _ => credit ? 'Credit' : 'Debit',
    },
    color: credit ? AppColors.success : AppColors.danger,
    sign: credit ? '+' : '−',
  );
}

/// A polished detail sheet for one wallet transaction. Reused everywhere a
/// transaction row can be tapped.
Future<void> showTxnDialog(BuildContext context, Txn t) {
  final f = txnFace(t);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(14),
      child: BzCard(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: f.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                  child: Icon(txnIcon(t.kind), color: f.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.label, style: AppText.bodyStrong),
                    Text(Fmt.dateTime(t.at), style: AppText.bodyS),
                  ]),
                ),
                Text('${f.sign}${Fmt.taka(t.amount)}', style: AppText.numL.copyWith(color: f.color, fontSize: 18)),
              ]),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (t.status.isNotEmpty)
                KV('Status', t.status[0].toUpperCase() + t.status.substring(1),
                    valueStyle: AppText.bodyStrong.copyWith(
                      color: switch (t.status) {
                        'paid' || 'success' || 'completed' => AppColors.success,
                        'pending' => AppColors.warning,
                        'rejected' || 'failed' => AppColors.danger,
                        _ => AppColors.text,
                      },
                    )),
              if (t.title.isNotEmpty) ...[
                const SizedBox(height: 10),
                KV(t.kind == 'match' ? 'Tournament' : 'Method', t.title),
              ],
              if (t.ref.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: KV('Reference', t.ref)),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 17, color: AppColors.textMuted),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: t.ref));
                      showSnack(context, 'Reference copied', kind: SnackKind.success);
                    },
                  ),
                ]),
              ],
              const SizedBox(height: 10),
              KV('Date', Fmt.dateTime(t.at)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
