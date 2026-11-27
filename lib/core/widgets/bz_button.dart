import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text.dart';

enum BzBtn { primary, ghost, danger, gold }

class BzButton extends StatefulWidget {
  const BzButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BzBtn.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final BzBtn kind;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  State<BzButton> createState() => _BzButtonState();
}

class _BzButtonState extends State<BzButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    late final Decoration deco;
    late final Color fg;
    switch (widget.kind) {
      case BzBtn.primary:
        deco = BoxDecoration(
          gradient: AppColors.primaryGrad,
          borderRadius: BorderRadius.circular(AppTheme.rField),
          boxShadow: disabled ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.38), blurRadius: 20, offset: const Offset(0, 8))],
        );
        fg = Colors.white;
      case BzBtn.gold:
        deco = BoxDecoration(
          gradient: AppColors.goldGrad,
          borderRadius: BorderRadius.circular(AppTheme.rField),
          boxShadow: disabled ? null : [BoxShadow(color: AppColors.gold.withValues(alpha: 0.34), blurRadius: 20, offset: const Offset(0, 8))],
        );
        fg = const Color(0xFF2A1A05);
      case BzBtn.ghost:
        deco = BoxDecoration(
          color: AppColors.cardHi,
          borderRadius: BorderRadius.circular(AppTheme.rField),
          border: Border.all(color: AppColors.line),
        );
        fg = AppColors.text;
      case BzBtn.danger:
        deco = BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.rField),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.55)),
        );
        fg = AppColors.danger;
    }

    final content = widget.loading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(fg)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 9)],
              Text(widget.label, style: AppText.button.copyWith(color: fg)),
            ],
          );

    return AnimatedOpacity(
      opacity: disabled && !widget.loading ? 0.45 : 1,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: widget.expand ? null : const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: deco,
            child: content,
          ),
        ),
      ),
    );
  }
}
