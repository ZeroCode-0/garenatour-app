import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../models/app_config.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final data = await api.get('/config', auth: false, useCache: true, cacheMaxAge: const Duration(minutes: 5));
  return AppConfig.fromJson((data as Map).cast<String, dynamic>());
});

class UpdateGate {
  UpdateGate({required this.forceUpdate, required this.optionalUpdate, this.link, this.notice});
  final bool forceUpdate;
  final bool optionalUpdate;
  final String? link;
  final String? notice;
}

final updateGateProvider = FutureProvider<UpdateGate>((ref) async {
  final cfg = await ref.watch(appConfigProvider.future);
  final info = await PackageInfo.fromPlatform();
  final current = int.tryParse(info.buildNumber) ?? 1;
  final target = defaultTargetPlatform == TargetPlatform.iOS ? cfg.ios : cfg.android;

  final behind = current < target.build;
  return UpdateGate(
    forceUpdate: behind && target.forceUpdate,
    optionalUpdate: behind && !target.forceUpdate,
    link: target.updateLink,
    notice: target.updateNotice,
  );
});
