import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Standard surface. Optional tap adds a subtle press-scale.
class BzCard extends StatefulWidget {
  const BzCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = AppTheme.rCard,
    this.borderColor,
    this.gradient,
    this.glow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? glow;

  @override
  State<BzCard> createState() => _BzCardState();
}

class _BzCardState extends State<BzCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: widget.gradient ?? AppColors.cardGrad,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: widget.borderColor ?? AppColors.line),
          boxShadow: [
            const BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
            if (widget.glow != null)
              BoxShadow(color: widget.glow!.withValues(alpha: 0.28), blurRadius: 26, spreadRadius: -6),
          ],
        ),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.onTap == null) return card;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
