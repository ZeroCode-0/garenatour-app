import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A visual identity for each game mode — used for the mode grid and as the
/// art fallback on match cards when no banner image is set.
class ModeVisual {
  const ModeVisual(this.glyph, this.icon, this.c1, this.c2);
  final String glyph;
  final IconData icon;
  final Color c1;
  final Color c2;

  LinearGradient get gradient => LinearGradient(
        colors: [c1, c2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ModeVisual of(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'BATTLE_ROYAL':
        return const ModeVisual('BR', Icons.public_rounded, Color(0xFFFF1F2D), Color(0xFF3A1E8A));
      case 'CLASH_SQUAD':
        return const ModeVisual('CS', Icons.groups_2_rounded, Color(0xFF1FB6C9), Color(0xFF0E5A75));
      case 'CS_2V2':
        return const ModeVisual('2V2', Icons.sports_mma_rounded, Color(0xFFFF6BAA), Color(0xFF8E2E63));
      case 'LONE_WOLF':
        return const ModeVisual('LW', Icons.gps_fixed_rounded, Color(0xFFFBB03B), Color(0xFF8A5A12));
      case 'LUDO':
        return const ModeVisual('LD', Icons.casino_rounded, Color(0xFF4D8BFF), Color(0xFF23407F));
      case 'FREE_MATCH':
        return const ModeVisual('FR', Icons.bolt_rounded, Color(0xFF38D18B), Color(0xFF176B47));
      default:
        return const ModeVisual('GM', Icons.sports_esports_rounded, Color(0xFFFF5A4E), Color(0xFFC40012));
    }
  }
}

/// The painted "cover art" used when a match has no banner image — a diagonal
/// gradient, a soft light streak, and the giant mode glyph ghosted in.
class ModeArt extends StatelessWidget {
  const ModeArt({super.key, required this.code, this.glyphOpacity = 0.16});
  final String? code;
  final double glyphOpacity;

  @override
  Widget build(BuildContext context) {
    final v = ModeVisual.of(code);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: v.gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // light streak
          Transform.rotate(
            angle: -0.5,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              alignment: Alignment.topLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -14,
            bottom: -22,
            child: Text(
              v.glyph,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 118,
                height: 1,
                color: Colors.white.withValues(alpha: glyphOpacity),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.imageScrim)),
          ),
        ],
      ),
    );
  }
}
