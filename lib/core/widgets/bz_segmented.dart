import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Sliding segmented control (Overview · Players · Rules · Rewards).
class BzSegmented extends StatelessWidget {
  const BzSegmented({super.key, required this.tabs, required this.index, required this.onChanged});
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final seg = (c.maxWidth - 8) / tabs.length;
      return Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: seg * index,
              top: 0,
              bottom: 0,
              width: seg,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradH,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          tabs[i].toUpperCase(),
                          style: AppText.label.copyWith(
                            fontSize: 11, letterSpacing: 0.6,
                            color: i == index ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
