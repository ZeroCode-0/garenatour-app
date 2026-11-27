import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/router/update_gate_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/app_config/app_config_controller.dart';
import 'features/push/push_controller.dart';

class GarenaTourApp extends ConsumerWidget {
  const GarenaTourApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final gate = ref.watch(updateGateProvider).valueOrNull;

    // Boots FCM: shows pushes, deep-links taps, registers the token after login.
    ref.watch(pushControllerProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0E0C15),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    if (gate != null && gate.forceUpdate) {
      return MaterialApp(
        title: Env.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: UpdateGateScreen(link: gate.link, notice: gate.notice),
      );
    }

    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: child!,
      ),
    );
  }
}
