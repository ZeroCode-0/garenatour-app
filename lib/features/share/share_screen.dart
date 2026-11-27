import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/gt_shapes.dart';
import '../extras/extras_repository.dart';
import '../wallet/wallet_repository.dart';

/// Balance Share (send deposit balance to a friend). Powered by NeXdEvE.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});
  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _to = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Map<String, dynamic>? _found;
  bool _looking = false;

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_to.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _looking = true; _found = null; });
    try {
      final r = await ref.read(extrasRepoProvider).shareLookup(_to.text.trim());
      setState(() => _found = r);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _confirm(Map<String, dynamic> info) async {
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
    if (_found == null || amt <= 0) {
      showSnack(context, 'Find the player and enter an amount first.', kind: SnackKind.error);
      return;
    }
    final fee = amt * ((info['fee_percent'] as num).toDouble()) / 100;
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Confirm transfer'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Send ${Fmt.taka(amt)} to ${_found!['name']} (${_found!['phone']})', style: AppText.bodyM),
          if (fee > 0) Text('Fee: ${Fmt.taka(fee)}', style: AppText.bodyS),
          const SizedBox(height: 14),
          BzField(controller: pass, label: 'YOUR PASSWORD', icon: Icons.lock_rounded, obscure: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('SEND', style: TextStyle(color: AppColors.primaryHi))),
        ],
      ),
    );
    if (ok != true || pass.text.isEmpty) return;
    try {
      final r = await ref.read(extrasRepoProvider).shareSend(to: _to.text.trim(), amount: _amount.text.trim(), password: pass.text, note: _note.text.trim());
      HapticFeedback.mediumImpact();
      ref.read(extrasRefreshProvider.notifier).state++;
      ref.read(walletRefreshProvider.notifier).state++;
      _amount.clear(); _note.clear();
      setState(() => _found = null);
      if (mounted) showSnack(context, 'Sent ${Fmt.taka(r['amount'])} to ${r['to']} ✅', kind: SnackKind.success);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(shareInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Balance Share')),
      body: BzBackground(
        child: info.when(
          loading: () => const BzLoader(),
          error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(shareInfoProvider)),
          data: (d) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              GtCutCard(
                glow: AppColors.primary,
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: .25), AppColors.card]),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryHi, size: 30),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Deposit balance', style: AppText.bodyS),
                    Text(Fmt.taka(d['balance']), style: AppText.numXl.copyWith(fontSize: 26)),
                  ])),
                  Text('${d['used_today']}/${d['per_day']}\ntoday', textAlign: TextAlign.right, style: AppText.bodyS),
                ]),
              ),
              const SizedBox(height: 10),
              Text('Only deposit balance can be shared (৳${d['min']} – ৳${d['max']}). Winning balance cannot be shared.',
                  style: AppText.bodyS.copyWith(height: 1.5)),
              const SizedBox(height: 18),
              if (d['enabled'] != true)
                const BzEmpty(title: 'Balance Share is off', icon: Icons.block_rounded)
              else ...[
                BzField(
                  controller: _to, label: 'SEND TO', hint: 'Phone, email or refer code', icon: Icons.person_search_rounded,
                  trailing: _looking
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.primaryHi), onPressed: _lookup),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _found == null
                      ? const SizedBox(height: 12)
                      : Padding(
                          key: ValueKey(_found!['phone']),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: GtCutCard(
                            border: AppColors.success.withValues(alpha: .5),
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              const Icon(Icons.verified_rounded, color: AppColors.success),
                              const SizedBox(width: 10),
                              Expanded(child: Text('${_found!['name']}  ·  ${_found!['phone']}', style: AppText.bodyStrong)),
                            ]),
                          ),
                        ),
                ),
                BzField(controller: _amount, label: 'AMOUNT (৳)', hint: 'e.g. 100', icon: Icons.payments_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                BzField(controller: _note, label: 'NOTE (OPTIONAL)', hint: 'For squad entry', icon: Icons.edit_note_rounded, maxLength: 120),
                const SizedBox(height: 8),
                BzButton(label: 'SEND BALANCE', icon: Icons.send_rounded, onPressed: () => _confirm(d)),
              ],
              const SizedBox(height: 26),
              const _PromoBox(),
              const SizedBox(height: 26),
              if ((d['recent'] as List).isNotEmpty) ...[
                const GtSectionTitle('Recent'),
                for (final r in (d['recent'] as List).cast<Map>())
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      Icon(r['direction'] == 'sent' ? Icons.north_east_rounded : Icons.south_west_rounded,
                          color: r['direction'] == 'sent' ? AppColors.danger : AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${r['direction'] == 'sent' ? 'To' : 'From'} ${r['other_name']}', style: AppText.bodyM)),
                      Text(Fmt.taka(r['amount']), style: AppText.numM),
                    ]),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Promo code redeem box (also reused on the Wallet).
class _PromoBox extends ConsumerStatefulWidget {
  const _PromoBox();
  @override
  ConsumerState<_PromoBox> createState() => _PromoBoxState();
}

class _PromoBoxState extends ConsumerState<_PromoBox> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(extrasRepoProvider).promo(_code.text.trim());
      HapticFeedback.mediumImpact();
      _code.clear();
      ref.read(extrasRefreshProvider.notifier).state++;
      ref.read(walletRefreshProvider.notifier).state++;
      if (mounted) showSnack(context, '🎁 ${Fmt.taka(r['amount'])} bonus added!', kind: SnackKind.success);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GtCutCard(
      border: AppColors.gold.withValues(alpha: .4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: AppColors.gold),
          const SizedBox(width: 10),
          Text('PROMO CODE', style: AppText.h3.copyWith(fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        BzField(controller: _code, label: 'CODE', hint: 'Enter promo code', icon: Icons.confirmation_number_rounded,
            textCapitalization: TextCapitalization.characters),
        const SizedBox(height: 10),
        BzButton(label: 'REDEEM', kind: BzBtn.gold, loading: _busy, onPressed: _busy ? null : _go),
      ]),
    );
  }
}

/// Promo-only page (opened from Wallet / Home)
class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Promo Code')),
        body: const BzBackground(child: Padding(padding: EdgeInsets.all(16), child: _PromoBox())),
      );
}
