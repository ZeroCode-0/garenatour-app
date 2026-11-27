import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/common.dart';
import '../app_config/app_config_controller.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    final notice = cfg.valueOrNull?.closeNotice ?? 'We are performing maintenance. Please check back soon.';

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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card, border: Border.all(color: AppColors.warning.withValues(alpha: 0.4))),
                  child: const Icon(Icons.construction_rounded, size: 40, color: AppColors.warning),
                ),
                const SizedBox(height: 24),
                const GradientText('UNDER MAINTENANCE', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(notice, style: AppText.bodyM, textAlign: TextAlign.center),
                const SizedBox(height: 30),
                BzButton(
                  label: 'CHECK AGAIN',
                  icon: Icons.refresh_rounded,
                  onPressed: () async {
                    ref.invalidate(appConfigProvider);
                    final fresh = await ref.read(appConfigProvider.future);
                    if (context.mounted && !fresh.isClosed) context.go('/splash');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
