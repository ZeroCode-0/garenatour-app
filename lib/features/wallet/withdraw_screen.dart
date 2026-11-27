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
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_controller.dart';
import '../home/home_controller.dart';
import 'wallet_repository.dart';
import 'withdrawal_intent_store.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});
  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _pin = TextEditingController();
  String _provider = 'bkash';
  bool _loading = false;
  WithdrawalIntent? _pendingIntent;
  static const _labels = {'bkash': 'bKash', 'nagad': 'Nagad', 'rocket': 'Rocket'};

  @override
  void initState() {
    super.initState();
    _loadPendingIntent();
  }

  Future<void> _loadPendingIntent() async {
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      final pending = await WithdrawalIntentStore.getForUser(user.id);
      if (pending != null && mounted) {
        setState(() {
          _pendingIntent = pending;
          _provider = pending.provider;
          _number.text = pending.accountNumber;
          _amount.text = pending.amount.toStringAsFixed(0);
        });
        return;
      }
    }
    if (mounted) {
      _number.text = user?.phone ?? '';
    }
  }

  Future<void> _discardPendingIntent() async {
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      await WithdrawalIntentStore.clearForUser(user.id);
      if (mounted) {
        setState(() {
          _pendingIntent = null;
          _amount.clear();
          _number.text = user.phone;
        });
        showSnack(context, 'Unresolved withdrawal request discarded.', kind: SnackKind.info);
      }
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    // If an unresolved intent exists, preserve the exact original key and payload
    final providerToUse = _pendingIntent?.provider ?? _provider;
    final accountToUse = _pendingIntent?.accountNumber ?? _number.text.trim();
    final amountToUse = _pendingIntent?.amount ?? double.parse(_amount.text.trim());
    final idemToUse = _pendingIntent?.idempotencyKey;
    final pinToUse = _pin.text.trim();

    try {
      final res = await ref.read(walletRepositoryProvider).withdraw(
            userId: user.id,
            provider: providerToUse,
            accountNumber: accountToUse,
            amount: amountToUse,
            pin: pinToUse.isNotEmpty ? pinToUse : null,
            idempotencyKey: idemToUse,
          );

      _pendingIntent = null;
      ref.read(authControllerProvider.notifier).patchWallet(winning: double.tryParse('${res['winning']}'));
      ref.read(walletRefreshProvider.notifier).state++;
      ref.invalidate(homeProvider);

      if (mounted) {
        final isIdem = res['idempotent'] == true;
        final msg = isIdem
            ? 'Withdraw request verified (${res['ref']}). Paid within 24h.'
            : 'Withdraw request submitted (${res['ref']}). Paid within 24h.';
        showSnack(context, msg, kind: SnackKind.success);
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      final status = e.statusCode;
      if (status != null && status >= 400 && status < 500) {
        // Definitive business error -> clear locally
        _pendingIntent = null;
      }
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (_) {
      // Network drop: re-read intent to ensure UI shows unresolved status banner
      final pending = await WithdrawalIntentStore.getForUser(user.id);
      if (mounted) {
        setState(() => _pendingIntent = pending);
        showSnack(context, 'Network issue. Request saved safely — retry to verify without double charge.', kind: SnackKind.info);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(withdrawInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: info.when(
            loading: () => const BzLoader(),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(withdrawInfoProvider)),
            data: (d) => Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_pendingIntent != null) ...[
                    BzCard(
                      borderColor: AppColors.cyan.withValues(alpha: 0.6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync_problem_rounded, color: AppColors.cyan, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Unresolved Withdrawal Detected', style: AppText.h3.copyWith(fontSize: 14, color: AppColors.cyan)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A pending withdrawal of ৳${_pendingIntent!.amount.toStringAsFixed(0)} to ${_pendingIntent!.provider.toUpperCase()} (${_pendingIntent!.accountNumber}) was saved from a previous session. Tap RETRY to safely complete or verify with zero duplicate charge.',
                            style: AppText.bodyS,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _loading ? null : _discardPendingIntent,
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.warning),
                              label: Text('Discard Request', style: AppText.button.copyWith(fontSize: 12, color: AppColors.warning)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BzCard(
                    glow: AppColors.gold,
                    borderColor: AppColors.gold.withValues(alpha: 0.35),
                    child: Column(children: [
                      Text('WINNING BALANCE', style: AppText.label.copyWith(fontSize: 10)),
                      const SizedBox(height: 4),
                      MoneyText(d.winning, style: AppText.numXl.copyWith(color: AppColors.gold, fontSize: 26)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (!d.canWithdraw)
                    BzCard(
                      borderColor: AppColors.warning.withValues(alpha: 0.4),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 17),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Today\'s withdraw is used (${d.perDay}/day). Try again tomorrow.', style: AppText.bodyS.copyWith(color: AppColors.text))),
                      ]),
                    ),
                  if (!d.canWithdraw) const SizedBox(height: 16),
                  const SectionHeader('Payment method'),
                  Row(children: [
                    for (final p in _labels.keys)
                      Expanded(child: Padding(
                        padding: EdgeInsets.only(right: p == 'rocket' ? 0 : 8),
                        child: GestureDetector(
                          onTap: _pendingIntent != null ? null : () => setState(() => _provider = p),
                          child: Container(
                            height: 46, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: _provider == p ? AppColors.primaryGradH : null,
                              color: _provider == p ? null : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _provider == p ? Colors.transparent : AppColors.line),
                            ),
                            child: Text(_labels[p]!, style: AppText.button.copyWith(fontSize: 12.5, color: _provider == p ? Colors.white : AppColors.textMuted)),
                          ),
                        ),
                      )),
                  ]),
                  const SizedBox(height: 16),
                  BzField(
                    controller: _number, label: 'Account Number', hint: '01XXXXXXXXX',
                    icon: Icons.smartphone_rounded, keyboardType: TextInputType.phone,
                    enabled: _pendingIntent == null,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                    validator: BzValidators.phoneBD,
                  ),
                  const SizedBox(height: 14),
                  BzField(
                    controller: _amount, label: 'Amount (৳)', hint: 'Min ${d.minWithdraw.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded, keyboardType: TextInputType.number,
                    enabled: _pendingIntent == null,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => BzValidators.amount(v, min: d.minWithdraw, max: d.maxWithdraw > d.winning ? d.winning : d.maxWithdraw),
                  ),
                  if (d.hasPin) ...[
                    const SizedBox(height: 14),
                    BzField(
                      controller: _pin, label: 'Wallet Security PIN', hint: '••••',
                      icon: Icons.lock_outline_rounded, obscure: true, keyboardType: TextInputType.number,
                      enabled: _pendingIntent == null,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      validator: (v) => (v == null || v.trim().length != 4) ? 'Enter 4-digit PIN' : null,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('Min ${Fmt.taka(d.minWithdraw)} · Max ${Fmt.taka(d.maxWithdraw)} · ${d.perDay} withdraw/day', style: AppText.bodyS),
                  const SizedBox(height: 18),
                  BzButton(
                    label: _pendingIntent != null ? 'RETRY WITHDRAWAL' : 'REQUEST WITHDRAW',
                    icon: _pendingIntent != null ? Icons.refresh_rounded : Icons.arrow_outward_rounded,
                    loading: _loading,
                    onPressed: d.canWithdraw ? _submit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
