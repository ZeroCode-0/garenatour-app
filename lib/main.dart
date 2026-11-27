import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/network/api_cache.dart';
import 'core/push/push_service.dart';
import 'core/storage/device_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize critical local cache and orientations in parallel
  await Future.wait([
    ApiCache.init(),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    initializeDateFormatting('en'),
    DeviceInfo.load(),
  ]);

  // Non-blocking background push handler registration so runApp is never delayed
  unawaited(() async {
    try {
      if (await initFirebase().timeout(const Duration(milliseconds: 300), onTimeout: () => false)) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }
    } catch (_) {}
  }());

  runApp(const ProviderScope(child: GarenaTourApp()));
}
