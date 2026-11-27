import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../models/user.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

final profileStatsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    ref.keepAlive();
    final data = await ref.watch(apiClientProvider).get(
      '/me/stats',
      useCache: true,
      cacheMaxAge: const Duration(minutes: 5),
    );
    return (data as Map).cast<String, dynamic>();
  },
);

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<AppUser> updateName(String name) async {
    final data = await _api.patch('/me', body: {'name': name});
    return AppUser.fromJson(((data as Map)['user'] as Map).cast<String, dynamic>());
  }

  Future<void> changePassword({required String current, required String next}) =>
      _api.post('/me/password', body: {'current_password': current, 'new_password': next});

  Future<String> uploadAvatar(String base64) async {
    final data = await _api.upload('/me/avatar', FormData.fromMap({'image_base64': base64}));
    return (data as Map)['avatar_url'] as String;
  }

  Future<void> registerFcmToken(String token) =>
      _api.post('/me/fcm-token', body: {'fcm_token': token});
}
