import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/launch.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/bz_card.dart';
import '../auth/auth_controller.dart';
import 'wallet_repository.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});
  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _trx = TextEditingController();
  String _provider = 'bkash';
  bool _loading = false;
  static const _labels = {'bkash': 'bKash', 'nagad': 'Nagad', 'rocket': 'Rocket'};

  @override
  void dispose() {
    _trx.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_trx.text.trim().length < 4) {
      showSnack(context, 'Enter the Transaction ID from your payment SMS', kind: SnackKind.error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final res = await ref.read(walletRepositoryProvider).deposit(provider: _provider, trxId: _trx.text.trim());
      ref.read(authControllerProvider.notifier).patchWallet(balance: double.tryParse('${res['balance']}'));
      ref.read(walletRefreshProvider.notifier).state++;
      if (mounted) {
        _trx.clear();
        showSnack(context, 'Deposit successful — ${Fmt.taka(res['deposited'])} added.', kind: SnackKind.success);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (_) {
      if (mounted) showSnack(context, 'Deposit failed. Try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(depositInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Balance')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: info.when(
            loading: () => const BzLoader(),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(depositInfoProvider)),
            data: (d) {
              final number = d.numbers[_provider] ?? '';
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const SectionHeader('1 · Choose method'),
                  Row(children: [
                    for (final p in _labels.keys)
                      Expanded(child: Padding(
                        padding: EdgeInsets.only(right: p == 'rocket' ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _provider = p),
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
                  const SizedBox(height: 18),
                  const SectionHeader('2 · Send Money'),
                  BzCard(
                    borderColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Send Money to this ${_labels[_provider]} number', style: AppText.bodyS),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text(number.isEmpty ? 'Not configured' : number, style: AppText.numXl.copyWith(fontSize: 20))),
                        if (number.isNotEmpty)
                          GestureDetector(
                            onTap: () { Clipboard.setData(ClipboardData(text: number)); showSnack(context, 'Number copied', kind: SnackKind.success); },
                            child: const Icon(Icons.copy_rounded, color: AppColors.primaryHi),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      Text('Minimum ${Fmt.taka(d.minDeposit)} · Maximum ${Fmt.taka(d.maxDeposit)}', style: AppText.bodyS),
                      if (d.helpLink != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => openLink(context, d.helpLink),
                          child: Text('How to deposit?', style: AppText.bodyS.copyWith(color: AppColors.primaryHi)),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader('3 · Submit Transaction ID'),
                  BzField(
                    controller: _trx, label: 'Transaction ID (TrxID)', hint: 'From your payment SMS',
                    icon: Icons.tag_rounded, textCapitalization: TextCapitalization.characters,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(40)],
                  ),
                  const SizedBox(height: 8),
                  Text(d.instructions, style: AppText.bodyS.copyWith(height: 1.5)),
                  const SizedBox(height: 18),
                  BzButton(label: 'VERIFY & ADD BALANCE', icon: Icons.verified_rounded, loading: _loading, onPressed: _submit),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
