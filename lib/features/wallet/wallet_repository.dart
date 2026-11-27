import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../models/wallet.dart';
import 'withdrawal_intent_store.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

/// Force wallet-related providers to refetch after a money action.
final walletRefreshProvider = StateProvider<int>((ref) => 0);

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) {
  ref.keepAlive();
  ref.watch(walletRefreshProvider);
  return ref.watch(walletRepositoryProvider).summary();
});

final depositInfoProvider = FutureProvider<DepositInfo>((ref) {
  ref.keepAlive();
  ref.watch(walletRefreshProvider);
  return ref.watch(walletRepositoryProvider).depositInfo();
});

final withdrawInfoProvider = FutureProvider<WithdrawInfo>((ref) {
  ref.keepAlive();
  ref.watch(walletRefreshProvider);
  return ref.watch(walletRepositoryProvider).withdrawInfo();
});

final recentTxnProvider = FutureProvider<List<Txn>>((ref) async {
  ref.keepAlive();
  ref.watch(walletRefreshProvider);
  final r = await ref.watch(walletRepositoryProvider).transactions(type: 'all', page: 1);
  return r.txns.take(5).toList();
});

class WalletRepository {
  WalletRepository(this._api);
  final ApiClient _api;

  Future<WalletSummary> summary() async =>
      WalletSummary.fromJson((await _api.get('/wallet', useCache: true, cacheMaxAge: const Duration(minutes: 2)) as Map).cast<String, dynamic>());

  Future<DepositInfo> depositInfo() async =>
      DepositInfo.fromJson((await _api.get('/wallet/deposit-info', useCache: true, cacheMaxAge: const Duration(hours: 1)) as Map).cast<String, dynamic>());

  Future<Map<String, dynamic>> deposit({required String provider, required String trxId}) async {
    final data = await _api.post('/wallet/deposit', body: {'provider': provider, 'trx_id': trxId});
    return (data as Map).cast<String, dynamic>();
  }

  Future<WithdrawInfo> withdrawInfo() async =>
      WithdrawInfo.fromJson((await _api.get('/wallet/withdraw-info', useCache: true, cacheMaxAge: const Duration(hours: 1)) as Map).cast<String, dynamic>());

  Future<Map<String, dynamic>> withdraw({
    required int userId,
    required String provider,
    required String accountNumber,
    required double amount,
    String? pin,
    String? idempotencyKey,
  }) async {
    final key = (idempotencyKey != null && idempotencyKey.isNotEmpty)
        ? idempotencyKey
        : WithdrawalIntentStore.generateKey(userId);

    final intent = WithdrawalIntent(
      userId: userId,
      idempotencyKey: key,
      provider: provider,
      accountNumber: accountNumber,
      amount: amount,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Persist intent before dispatching so it survives app crashes / termination
    await WithdrawalIntentStore.save(intent);

    try {
      final body = <String, dynamic>{
        'provider': provider,
        'account_number': accountNumber,
        'amount': amount,
        'idempotency_key': key,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      };
      final data = await _api.post('/wallet/withdraw', body: body);
      final res = (data as Map).cast<String, dynamic>();

      // Definitive server response -> clear persisted intent
      await WithdrawalIntentStore.clearForUser(userId);
      return res;
    } on ApiException catch (e) {
      // Definitive rejection from server (e.g. 402 INSUFFICIENT_WINNING, 422, 429)
      // means the withdrawal did not commit on the server. Clear the pending intent.
      final status = e.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await WithdrawalIntentStore.clearForUser(userId);
      }
      rethrow;
    } catch (_) {
      // Socket exception, network timeout, connection drop:
      // The state on server is ambiguous. Keep intent persisted for safe retry.
      rethrow;
    }
  }

  Future<({List<Txn> txns, bool hasMore})> transactions({String type = 'all', int page = 1}) async {
    final data = await _api.get(
      '/wallet/transactions',
      query: {'type': type, 'page': page},
      useCache: page == 1,
      cacheMaxAge: const Duration(minutes: 2),
    ) as Map<String, dynamic>;
    final list = (data['transactions'] as List).cast<Map<String, dynamic>>();
    return (txns: list.map(Txn.fromJson).toList(), hasMore: data['has_more'] == true);
  }
}
