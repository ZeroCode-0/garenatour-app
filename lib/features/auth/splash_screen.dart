import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/common.dart';
import '../app_config/app_config_controller.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    ref.read(appConfigProvider);
    _tryRoute();
  }

  void _performRoute(AuthPhase phase) {
    if (_navigated || !mounted) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(appConfigProvider).valueOrNull?.isClosed == true) {
        context.go("/maintenance");
        return;
      }
      if (phase == AuthPhase.authenticated) {
        context.go("/home");
      } else {
        context.go("/login");
      }
    });
  }

  Future<void> _tryRoute() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _navigated) return;
    final phase = ref.read(authControllerProvider).phase;
    _performRoute(phase == AuthPhase.unknown ? AuthPhase.unauthenticated : phase);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.phase != AuthPhase.unknown && !_navigated) {
        _performRoute(next.phase);
      }
    });

    return Scaffold(
      body: BzBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/icons/emblem.svg', width: 104)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1400.ms, color: Colors.white24),
              const SizedBox(height: 24),
              const GradientText('Garena Tour')
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text('ELITE ESPORTS ARENA', style: AppText.label.copyWith(letterSpacing: 3.4))
                  .animate().fadeIn(delay: 450.ms, duration: 500.ms),
              const SizedBox(height: 44),
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.cyan),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 60),
              Text('POWERED BY NeXdEvE',
                      style: AppText.tiny.copyWith(color: AppColors.textFaint, letterSpacing: 2.5))
                  .animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
