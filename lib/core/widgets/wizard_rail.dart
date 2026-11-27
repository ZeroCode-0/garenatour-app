import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The 1–2–3–4 step rail at the top of the join wizard.
class WizardRail extends StatelessWidget {
  const WizardRail({super.key, required this.step, required this.total, this.labels});
  final int step; // 1-based
  final int total;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          _node(i),
          if (i != total)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < step ? AppColors.primary : AppColors.line,
              ),
            ),
        ],
      ],
    );
  }

  Widget _node(int i) {
    final done = i < step;
    final active = i == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (done || active) ? AppColors.primaryGrad : null,
        color: (done || active) ? null : AppColors.card,
        border: Border.all(color: (done || active) ? Colors.transparent : AppColors.line),
        boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)] : null,
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : Text('$i', style: AppText.numM.copyWith(fontSize: 12, color: active ? Colors.white : AppColors.textMuted)),
    );
  }
}
