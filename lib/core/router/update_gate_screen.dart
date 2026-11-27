import 'package:flutter/material.dart';

import '../launch.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/bz_background.dart';
import '../widgets/bz_button.dart';
import '../widgets/common.dart';

class UpdateGateScreen extends StatelessWidget {
  const UpdateGateScreen({super.key, this.link, this.notice});
  final String? link;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card, border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
                  child: const Icon(Icons.rocket_launch_rounded, size: 38, color: AppColors.primaryHi),
                ),
                const SizedBox(height: 24),
                const GradientText('UPDATE REQUIRED', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  notice ?? 'A new version of Garena Tour is available. Please update to keep playing.',
                  style: AppText.bodyM,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (link != null && link!.isNotEmpty)
                  BzButton(
                    label: 'UPDATE NOW',
                    icon: Icons.download_rounded,
                    onPressed: () => openLink(context, link),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
