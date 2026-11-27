import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum SnackKind { success, error, info }

void showSnack(BuildContext context, String message, {SnackKind kind = SnackKind.info}) {
  // strip any emoji the server might send so the UI stays clean
  final clean = message.replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}✅❌✔️]', unicode: true), '').trim();

  final (color, icon) = switch (kind) {
    SnackKind.success => (AppColors.success, Icons.check_circle_rounded),
    SnackKind.error => (AppColors.danger, Icons.error_rounded),
    SnackKind.info => (AppColors.info, Icons.info_rounded),
  };

  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(
    duration: const Duration(seconds: 3),
    backgroundColor: AppColors.cardHi,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    ),
    content: Row(children: [
      Icon(icon, color: color, size: 19),
      const SizedBox(width: 11),
      Expanded(child: Text(clean, style: AppText.bodyStrong)),
    ]),
  ));
}
