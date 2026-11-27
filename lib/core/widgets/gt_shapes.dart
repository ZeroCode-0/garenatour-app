import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Garena Tour "Inferno" design language — angular cut-corner surfaces,
/// metallic silver type and red glow, taken from the brand emblem.
/// Powered by NeXdEvE.

const _cut = 14.0;

ShapeBorder gtCutShape({double cut = _cut, Color? side, double width = 1}) => BeveledRectangleBorder(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(cut), bottomRight: Radius.circular(cut)),
      side: side == null ? BorderSide.none : BorderSide(color: side, width: width),
    );

/// Card with chamfered top-left / bottom-right corners.
class GtCutCard extends StatelessWidget {
  const GtCutCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.gradient,
    this.color,
    this.border,
    this.glow,
    this.cut = _cut,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final Color? border;
  final Color? glow;
  final double cut;

  @override
  Widget build(BuildContext context) {
    final shape = gtCutShape(cut: cut, side: border ?? AppColors.line);
    Widget body = Ink(
      decoration: ShapeDecoration(
        shape: shape,
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        shadows: glow == null ? null : [BoxShadow(color: glow!.withValues(alpha: .28), blurRadius: 26, spreadRadius: -6)],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      body = InkWell(onTap: onTap, customBorder: shape, splashColor: AppColors.primary.withValues(alpha: .15), child: body);
    }
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(type: MaterialType.transparency, child: body),
    );
  }
}

/// Brushed-silver headline text (like the emblem lettering).
class MetalText extends StatelessWidget {
  const MetalText(this.text, {super.key, this.style, this.red = false, this.textAlign});
  final String text;
  final TextStyle? style;
  final bool red;
  final TextAlign? textAlign;

  static const _silver = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFD9D9E0), Color(0xFF9C9CA6), Color(0xFFEDEDF2)],
    stops: [0, .45, .55, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const _red = LinearGradient(
    colors: [Color(0xFFFF6A5A), Color(0xFFFF1F2D), Color(0xFFB3000F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => (red ? _red : _silver).createShader(r),
      child: Text(text, textAlign: textAlign, style: (style ?? AppText.h1).copyWith(color: Colors.white)),
    );
  }
}

/// Section title with a red slash accent:  ▍ TITLE ............ action
class GtSectionTitle extends StatelessWidget {
  const GtSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Transform(
          transform: Matrix4.skewX(-.35),
          child: Container(width: 5, height: 18, decoration: BoxDecoration(gradient: AppColors.primaryGrad)),
        ),
        const SizedBox(width: 10),
        Text(title.toUpperCase(), style: AppText.h3.copyWith(letterSpacing: 1.4, fontSize: 17)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: AppColors.line)),
        if (action != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppText.label.copyWith(color: AppColors.primaryHi, fontSize: 11)),
          ),
        ],
      ]),
    );
  }
}

/// Square quick-action tile used on Home.
class GtQuickTile extends StatelessWidget {
  const GtQuickTile({super.key, required this.icon, required this.label, required this.onTap, this.color = AppColors.primary, this.badge});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final int? badge;
  @override
  Widget build(BuildContext context) {
    return GtCutCard(
      onTap: onTap,
      cut: 10,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: .38), color.withValues(alpha: .08)]),
              border: Border.all(color: color.withValues(alpha: .55)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          if ((badge ?? 0) > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.bg, width: 1.5)),
                child: Text('$badge', style: AppText.tiny.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(fontSize: 10.5, color: AppColors.text)),
      ]),
    );
  }
}
