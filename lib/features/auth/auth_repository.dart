import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/storage/device_info.dart';
import '../../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? referCode,
  }) async {
    final d = await DeviceInfo.load();
    final data = await _api.post('/auth/register', auth: false, body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'device_id': d.id,
      'device_name': d.name,
      if (referCode != null && referCode.isNotEmpty) 'refer_code': referCode,
    });
    return AuthResult.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final d = await DeviceInfo.load();
    final data = await _api.post('/auth/login', auth: false, body: {
      'email': email,
      'password': password,
      'device_id': d.id,
      'device_name': d.name,
    });
    return AuthResult.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _api.post('/auth/logout', body: {'refresh_token': refreshToken});
    } catch (_) {/* best effort */}
  }

  Future<AppUser> me() async {
    final data = await _api.get('/me');
    return AppUser.fromJson(((data as Map)['user'] as Map).cast<String, dynamic>());
  }
}
