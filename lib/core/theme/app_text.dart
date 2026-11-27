import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Rajdhani = condensed display / headings / labels / buttons.
/// Sora     = body + numerals (tabular). Powered by NeXdEvE.
class AppText {
  AppText._();

  static const String display = 'Rajdhani';
  static const String body = 'Sora';

  // ---- display / headings ----
  static const TextStyle h1 = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w700, fontSize: 30,
    letterSpacing: 0.5, height: 1.05, color: AppColors.text,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w700, fontSize: 22,
    letterSpacing: 0.4, height: 1.1, color: AppColors.text,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w600, fontSize: 18,
    letterSpacing: 0.3, color: AppColors.text,
  );
  static const TextStyle title = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w600, fontSize: 16,
    letterSpacing: 0.2, color: AppColors.text,
  );

  /// tiny uppercase section / field labels
  static const TextStyle label = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w600, fontSize: 11.5,
    letterSpacing: 1.4, color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: display, fontWeight: FontWeight.w700, fontSize: 14.5,
    letterSpacing: 1.0,
  );

  // ---- numerals ----
  static const TextStyle numXl = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w700, fontSize: 24,
    color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle numL = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w700, fontSize: 18,
    color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle numM = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w600, fontSize: 14,
    color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()],
  );

  // ---- body ----
  static const TextStyle bodyM = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w400, fontSize: 13.5,
    height: 1.55, color: AppColors.textDim,
  );
  static const TextStyle bodyS = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w400, fontSize: 12,
    height: 1.5, color: AppColors.textMuted,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w600, fontSize: 13.5,
    height: 1.4, color: AppColors.text,
  );
  static const TextStyle tiny = TextStyle(
    fontFamily: body, fontWeight: FontWeight.w500, fontSize: 10.5,
    letterSpacing: 0.3, color: AppColors.textMuted,
  );
}
