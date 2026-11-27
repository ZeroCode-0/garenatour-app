import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class BzNavItem {
  const BzNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class BzBottomNav extends StatelessWidget {
  const BzBottomNav({super.key, required this.items, required this.index, required this.onTap, this.badges = const {}});
  final List<BzNavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final active = i == index;
    final color = active ? AppColors.primaryHi : AppColors.textMuted;
    final badge = badges[i] ?? 0;
    return InkWell(
      onTap: () => onTap(i),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: active ? 22 : 0,
            decoration: BoxDecoration(gradient: AppColors.primaryGradH, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 7),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: active ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(items[i].icon, size: 22, color: color),
              ),
              if (badge > 0)
                Positioned(
                  right: -7, top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(999)),
                    constraints: const BoxConstraints(minWidth: 15),
                    child: Text('${badge > 9 ? '9+' : badge}',
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: AppText.body),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(items[i].label,
              style: AppText.tiny.copyWith(
                fontSize: 10, color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
