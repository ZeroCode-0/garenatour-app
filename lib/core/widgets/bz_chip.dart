import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Pill filter chip — purple fill when selected, hairline outline when idle.
class BzChip extends StatelessWidget {
  const BzChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 16, vertical: compact ? 7 : 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradH : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.transparent : AppColors.line),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: compact ? 11 : 12,
                letterSpacing: 0.6,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// horizontally scrolling chip row
class BzChipRow extends StatelessWidget {
  const BzChipRow({super.key, required this.children, this.height = 42, this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}
