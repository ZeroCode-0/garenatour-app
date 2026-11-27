import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'bz_button.dart';

class BzLoader extends StatelessWidget {
  const BzLoader({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46, height: 46,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primaryHi),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2400.ms),
            if (label != null) ...[
              const SizedBox(height: 14),
              Text(label!, style: AppText.bodyS),
            ],
          ],
        ),
      );
}

class BzSkeletonList extends StatelessWidget {
  const BzSkeletonList({super.key, this.itemHeight = 150, this.count = 4, this.padding = const EdgeInsets.all(16)});
  final double itemHeight;
  final int count;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardHi,
      period: const Duration(milliseconds: 1400),
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: itemHeight,
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class BzEmpty extends StatelessWidget {
  const BzEmpty({super.key, required this.title, this.message, this.icon = Icons.inbox_rounded, this.onRetry});
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(icon, size: 32, color: AppColors.textMuted),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 18),
              Text(title, style: AppText.h3, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!, style: AppText.bodyM, textAlign: TextAlign.center),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                BzButton(label: 'Retry', icon: Icons.refresh_rounded, kind: BzBtn.ghost, expand: false, onPressed: onRetry),
              ],
            ],
          ),
        ),
      );
}

class BzError extends StatelessWidget {
  const BzError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) =>
      BzEmpty(title: 'Something went wrong', message: message, icon: Icons.wifi_off_rounded, onRetry: onRetry);
}
