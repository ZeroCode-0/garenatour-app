import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'network/api_client.dart';
import 'storage/token_store.dart';

/// Broadcasts "the refresh token is dead — log the user out".
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    ref.watch(tokenStoreProvider),
    onSessionExpired: () {
      // bump the counter — the router / app listens and redirects to login
      ref.read(sessionExpiredProvider.notifier).state++;
      if (kDebugMode) debugPrint('[auth] session expired -> logout');
    },
  );
  return client;
});
