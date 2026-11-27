import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../notifications/notifications_controller.dart';

/// Shell with the Garena Tour nav: Home · Shop · [PLAY] · Wallet · Profile.
/// Branch order matches app_router: 0 home, 1 shop, 2 matches, 3 wallet, 4 profile.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    void go(int i) {
      HapticFeedback.selectionClick();
      shell.goBranch(i, initialLocation: i == shell.currentIndex);
    }

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: _GtNav(index: shell.currentIndex, onTap: go, profileBadge: unread),
    );
  }
}

class _GtNav extends StatelessWidget {
  const _GtNav({required this.index, required this.onTap, this.profileBadge = 0});
  final int index;
  final ValueChanged<int> onTap;
  final int profileBadge;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 74 + bottom,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        // bar
        Positioned.fill(
          top: 14,
          child: Container(
            padding: EdgeInsets.only(bottom: bottom),
            decoration: BoxDecoration(
              color: AppColors.bg2.withValues(alpha: .97),
              border: const Border(top: BorderSide(color: AppColors.line)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: Row(children: [
              _item(0, Icons.home_rounded, 'Home'),
              _item(1, Icons.storefront_rounded, 'Shop'),
              const Expanded(child: SizedBox()),
              _item(3, Icons.account_balance_wallet_rounded, 'Wallet'),
              _item(4, Icons.person_rounded, 'Profile', badge: profileBadge),
            ]),
          ),
        ),
        // raised PLAY button
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => onTap(2),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFFF4B3E), Color(0xFFC1000F)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  border: Border.all(color: AppColors.bg, width: 4),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: index == 2 ? .75 : .45), blurRadius: index == 2 ? 26 : 16)],
                ),
                child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 1),
              Text('PLAY', style: AppText.tiny.copyWith(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                  color: index == 2 ? AppColors.primaryHi : AppColors.textMuted)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _item(int i, IconData icon, String label, {int badge = 0}) {
    final active = i == index;
    final c = active ? AppColors.primaryHi : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedScale(scale: active ? 1.12 : 1, duration: const Duration(milliseconds: 200), child: Icon(icon, color: c, size: 23)),
            if (badge > 0)
              Positioned(
                right: -7, top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(99)),
                  child: Text(badge > 9 ? '9+' : '$badge', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: AppText.tiny.copyWith(fontSize: 10, color: c, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(top: 3),
            width: active ? 16 : 0, height: 2.5,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
        ]),
      ),
    );
  }
}
