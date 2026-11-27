import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The app's signature backdrop — near-black with a purple glow top-left
/// and a faint magenta bloom bottom-right.
class BzBackground extends StatelessWidget {
  const BzBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        const Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.pageGlowTop)),
        ),
        const Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.pageGlowBottom)),
        ),
        child,
      ],
    );
  }
}
