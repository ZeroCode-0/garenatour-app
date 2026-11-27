import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/wizard_rail.dart';
import '../../models/match.dart';
import '../auth/auth_controller.dart';
import '../home/home_controller.dart';
import '../wallet/wallet_repository.dart';
import 'match_detail_controller.dart';
import 'match_list_controller.dart';
import 'match_repository.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.matchKey});
  final String matchKey;
  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  int _step = 1;
  final Set<int> _slots = {};
  late final List<TextEditingController> _igns = [];
  // Server caps idempotency_key at 36 chars (DB CHAR(36)) — keep it short.
  late final String _idem = _makeIdem();
  static String _makeIdem() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(0x7fffffff).toRadixString(36);
    return 'j-$ts-$rnd'; // ~20 chars
  }

  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    for (final c in _igns) {
      c.removeListener(_syncFooter);
      c.dispose();
    }
    super.dispose();
  }

  void _ensureIgns(int n) {
    while (_igns.length < n) {
      _igns.add(TextEditingController()..addListener(_syncFooter));
    }
  }

  void _syncFooter() {
    if (mounted) setState(() {});
  }

  void _toggleSlot(int n, int teamSize) {
    setState(() {
      if (_slots.contains(n)) {
        _slots.remove(n);
      } else if (_slots.length < teamSize) {
        _slots.add(n);
      } else if (teamSize == 1) {
        _slots
          ..clear()
          ..add(n);
      }
    });
  }

  Future<void> _join(GameMatch m) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(matchRepositoryProvider).join(
            key: widget.matchKey,
            igns: _igns.take(m.teamSize).map((c) => c.text.trim()).toList(),
            idempotencyKey: _idem,
            preferredSlots: _slots.toList()..sort(),
          );
      ref.read(authControllerProvider.notifier).patchWallet(
            balance: double.tryParse('${res['balance'] ?? ''}'),
            winning: double.tryParse('${res['winning'] ?? ''}'),
          );
      ref.read(walletRefreshProvider.notifier).state++;
      ref.invalidate(homeProvider);
      ref.invalidate(matchDetailProvider(widget.matchKey));
      ref.invalidate(matchListProvider);
      ref.invalidate(matchSlotsProvider(widget.matchKey));
      setState(() {
        _result = res;
        _step = 4;
      });
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message, kind: SnackKind.error);
        // a slot was taken between load and submit → refresh the grid + go back
        if (e.code == 'SLOT_TAKEN' || e.code == 'BAD_SLOT') {
          ref.invalidate(matchSlotsProvider(widget.matchKey));
          setState(() {
            _slots.clear();
            _step = 1;
          });
        }
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Could not join. Try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(matchDetailProvider(widget.matchKey));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Tournament'),
        leading: BackButton(onPressed: () => _step > 1 && _step < 4 ? setState(() => _step--) : Navigator.pop(context)),
      ),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: detail.when(
            loading: () => const BzLoader(),
            error: (e, _) => BzError(message: '$e'),
            data: (m) {
              _ensureIgns(m.teamSize);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: WizardRail(step: _step, total: 4),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(a), child: c),
                      ),
                      child: _stepBody(m),
                    ),
                  ),
                  _footer(m),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stepBody(GameMatch m) {
    switch (_step) {
      case 1:
        return _SlotStep(
          key: const ValueKey(1),
          matchKey: widget.matchKey,
          teamSize: m.teamSize,
          selected: _slots,
          onTap: (n) => _toggleSlot(n, m.teamSize),
        );
      case 2:
        return _TeamStep(key: const ValueKey(2), m: m, igns: _igns);
      case 3:
        return _ReviewStep(key: const ValueKey(3), m: m, slots: _slots, igns: _igns);
      default:
        return _DoneStep(key: const ValueKey(4), m: m, result: _result);
    }
  }

  Widget _footer(GameMatch m) {
    if (_step == 4) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(color: AppColors.bg2, border: Border(top: BorderSide(color: AppColors.line))),
        child: SafeArea(top: false, child: Row(children: [
          Expanded(child: BzButton(label: 'VIEW MATCH', kind: BzBtn.ghost, onPressed: () { context.pop(); })),
          const SizedBox(width: 10),
          Expanded(child: BzButton(label: 'BACK TO PLAY', onPressed: () { context.go('/matches'); })),
        ])),
      );
    }

    final user = ref.watch(authControllerProvider).user;
    final total = m.entryFee * m.teamSize;
    final short = (user?.total ?? 0) + 0.001 < total;
    String label;
    bool ready;
    VoidCallback? onTap;
    switch (_step) {
      case 1:
        final need = m.teamSize;
        label = _slots.length == need ? 'CONTINUE' : 'PICK ${need - _slots.length} MORE SLOT${need - _slots.length == 1 ? '' : 'S'}';
        ready = _slots.length == need;
        onTap = ready ? () => setState(() => _step = 2) : null;
      case 2:
        label = 'CONTINUE';
        final names = _igns.take(m.teamSize).map((c) => c.text.trim()).toList();
        final allFilled = names.every((n) => n.isNotEmpty);
        final allUnique = names.map((n) => n.toLowerCase()).toSet().length == names.length;
        ready = allFilled && allUnique;
        onTap = ready ? () => setState(() => _step = 3) : null;
      default:
        label = short ? 'INSUFFICIENT BALANCE' : (m.entryFee == 0 ? 'CONFIRM & JOIN' : 'PAY ${Fmt.taka(total)} & JOIN');
        ready = !short;
        onTap = ready ? () => _join(m) : null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(color: AppColors.bg2, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(
        top: false,
        child: BzButton(label: label, loading: _loading, onPressed: onTap, icon: _step == 3 && !short ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
      ),
    );
  }
}

class _SlotStep extends ConsumerWidget {
  const _SlotStep({
    super.key,
    required this.matchKey,
    required this.teamSize,
    required this.selected,
    required this.onTap,
  });
  final String matchKey;
  final int teamSize;
  final Set<int> selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(matchSlotsProvider(matchKey));
    return slots.when(
      loading: () => const BzLoader(),
      error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(matchSlotsProvider(matchKey))),
      data: (s) {
        final total = s.totalSlots;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text(
              teamSize == 1
                  ? 'Pick your slot'
                  : 'Pick $teamSize slots for your ${s.teamMode.isEmpty ? 'team' : s.teamMode}',
              style: AppText.bodyM,
            ),
            const SizedBox(height: 4),
            Text('${s.booked.length}/$total booked', style: AppText.bodyS),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
              itemCount: total,
              itemBuilder: (_, i) {
                final n = i + 1;
                final isBooked = s.booked.contains(n);
                final isSel = selected.contains(n);
                final (bg, fg, br) = isSel
                    ? (AppColors.primary, Colors.white, AppColors.primary)
                    : isBooked
                        ? (AppColors.danger.withValues(alpha: 0.14), AppColors.danger, AppColors.danger.withValues(alpha: 0.4))
                        : (AppColors.card, AppColors.textDim, AppColors.line);
                return GestureDetector(
                  onTap: isBooked ? null : () => onTap(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: br)),
                    alignment: Alignment.center,
                    child: isBooked
                        ? const Icon(Icons.lock_rounded, size: 12, color: AppColors.danger)
                        : Text('$n', style: AppText.numM.copyWith(fontSize: 12, color: fg)),
                  ),
                ).stagger(i ~/ 6);
              },
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 8, children: const [
              _Legend('Available', AppColors.line),
              _Legend('Selected', AppColors.primary),
              _Legend('Booked', AppColors.danger),
            ]),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
          color: color == AppColors.line ? Colors.transparent : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4), border: Border.all(color: color))),
        const SizedBox(width: 6),
        Text(label, style: AppText.bodyS),
      ]);
}

class _TeamStep extends StatelessWidget {
  const _TeamStep({super.key, required this.m, required this.igns});
  final GameMatch m;
  final List<TextEditingController> igns;
  bool _isDuplicate(int i) {
    final v = igns[i].text.trim().toLowerCase();
    if (v.isEmpty) return false;
    for (var j = 0; j < m.teamSize; j++) {
      if (j != i && igns[j].text.trim().toLowerCase() == v) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Text('${m.teamLabel} match — enter your in-game name${m.teamSize > 1 ? 's' : ''}', style: AppText.bodyM),
        if (m.teamSize > 1) ...[
          const SizedBox(height: 4),
          Text('Every player needs a different Free Fire name.', style: AppText.bodyS),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < m.teamSize; i++) ...[
          BzField(
            controller: igns[i],
            label: m.teamSize == 1 ? 'Your IGN' : 'Player ${i + 1} IGN',
            hint: 'Any name — emoji / any language is fine',
            icon: Icons.person_outline_rounded,
            errorText: _isDuplicate(i) ? 'Same as another player' : null,
          ),
          const SizedBox(height: 12),
        ],
        BzCard(
          borderColor: AppColors.warning.withValues(alpha: 0.35),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(child: Text('Wrong IGN can get you disqualified with no refund.', style: AppText.bodyS.copyWith(color: AppColors.text))),
          ]),
        ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({super.key, required this.m, required this.slots, required this.igns});
  final GameMatch m;
  final Set<int> slots;
  final List<TextEditingController> igns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final total = m.entryFee * m.teamSize;
    final slotText = (slots.toList()..sort()).map((s) => '#$s').join(', ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Text('Review & confirm', style: AppText.h3),
        const SizedBox(height: 14),
        BzCard(
          child: Column(children: [
            KV('Tournament', m.title),
            const Divider(height: 16),
            KV(slots.length > 1 ? 'Slots' : 'Slot', slotText.isEmpty ? '—' : slotText),
            const Divider(height: 16),
            KV('Players', igns.take(m.teamSize).map((c) => c.text.trim()).where((s) => s.isNotEmpty).join(', ')),
          ]),
        ),
        const SizedBox(height: 12),
        BzCard(
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          child: Column(children: [
            KV('Entry fee', m.entryFee == 0 ? 'FREE' : '${Fmt.taka(m.entryFee)} × ${m.teamSize}'),
            const Divider(height: 16),
            KV('Total to pay', Fmt.taka(total), valueStyle: AppText.numL.copyWith(color: AppColors.gold)),
            const Divider(height: 16),
            KV('Your balance', Fmt.taka(user?.total ?? 0)),
          ]),
        ),
        const SizedBox(height: 10),
        Text('Paid from deposit balance first, then winning balance.', style: AppText.bodyS),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({super.key, required this.m, required this.result});
  final GameMatch m;
  final Map<String, dynamic>? result;
  @override
  Widget build(BuildContext context) {
    final slots = (result?['slots'] as List?)?.map((e) => '#$e').join(', ') ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGrad, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 30)]),
              child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 22),
            Text("YOU'RE IN!", style: AppText.h1),
            const SizedBox(height: 8),
            Text('Room ID & Password will appear here before the match starts. Keep the app open near start time.',
                style: AppText.bodyM, textAlign: TextAlign.center),
            if (slots.isNotEmpty) ...[
              const SizedBox(height: 16),
              BzCard(child: KV(slots.contains(',') ? 'Your slots' : 'Your slot', slots)),
            ],
            if (result?['fee_paid'] != null) ...[
              const SizedBox(height: 10),
              BzCard(child: KV('Entry fee paid', Fmt.taka(result!['fee_paid']), valueStyle: AppText.numM.copyWith(color: AppColors.gold))),
            ],
          ],
        ),
      ),
    );
  }
}
