import 'package:flutter/material.dart';

/// Premium red-black esports palette — matches the product mockup.
/// Powered by NeXdEvE.
class AppColors {
  AppColors._();

  // base
  static const Color bg = Color(0xFF0A0507);
  static const Color bg2 = Color(0xFF100709);
  static const Color card = Color(0xFF180B0F);
  static const Color cardHi = Color(0xFF221014);
  static const Color field = Color(0xFF13090C);
  static const Color line = Color(0xFF3A1A20);
  static const Color lineSoft = Color(0x14FFFFFF);

  // brand
  static const Color primary = Color(0xFFFF1F2D);
  static const Color primaryHi = Color(0xFFFF5A4E);
  static const Color primaryLo = Color(0xFFC40012);
  static const Color cyan = Color(0xFFFFC233);
  static const Color gold = Color(0xFFFBB03B);

  // text
  static const Color text = Color(0xFFFFF4F4);
  static const Color textDim = Color(0xFFC4AEB2);
  static const Color textMuted = Color(0xFF8F767B);
  static const Color textFaint = Color(0xFF5E4549);

  // status
  static const Color live = Color(0xFFFF4D5E);
  static const Color success = Color(0xFF38D18B);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A6E);
  static const Color info = Color(0xFF4DA3FF);

  // gradients
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFFFF3B3B), Color(0xFFC1000F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradH = LinearGradient(
    colors: [Color(0xFFFF3B3B), Color(0xFFC1000F)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldGrad = LinearGradient(
    colors: [Color(0xFFFFCB6B), Color(0xFFE8912A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGrad = LinearGradient(
    colors: [Color(0xFFFFD45C), Color(0xFFE89A12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGrad = LinearGradient(
    colors: [Color(0xFF1C0C10), Color(0xFF12080B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// bottom-of-image scrim so text stays readable over match art
  static const LinearGradient imageScrim = LinearGradient(
    colors: [Color(0x00000000), Color(0x33000000), Color(0xE60A0507)],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// ambient page glow
  static const RadialGradient pageGlowTop = RadialGradient(
    center: Alignment(-0.85, -1.05),
    radius: 1.35,
    colors: [Color(0x3DFF1F2D), Color(0x0FFF1F2D), Color(0x00000000)],
    stops: [0.0, 0.4, 1.0],
  );

  static const RadialGradient pageGlowBottom = RadialGradient(
    center: Alignment(1.1, 1.15),
    radius: 1.1,
    colors: [Color(0x2EFF6A00), Color(0x00000000)],
    stops: [0.0, 1.0],
  );
}
