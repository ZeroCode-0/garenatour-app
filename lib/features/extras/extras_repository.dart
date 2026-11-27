import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

/// API calls for the Garena Tour extras: Shop, Earn Coins, Balance Share,
/// Promo, Support, password reset, account deletion, legal pages.
/// Powered by NeXdEvE.
typedef J = Map<String, dynamic>;

J _m(dynamic v) => (v as Map).cast<String, dynamic>();

String newIdem() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

final extrasRepoProvider = Provider<ExtrasRepository>((ref) => ExtrasRepository(ref.watch(apiClientProvider)));

/// bump to refetch shop / earn / share / support data after an action
final extrasRefreshProvider = StateProvider<int>((ref) => 0);

final shopProvider = FutureProvider.family<J, String>((ref, kind) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).shop(kind);
});
final shopOrdersProvider = FutureProvider<List<J>>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).orders();
});
final earnProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).earn();
});
final shareInfoProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).shareInfo();
});
final ticketsProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).tickets();
});
final ticketProvider = FutureProvider.family<J, int>((ref, id) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).ticket(id);
});
final legalPageProvider = FutureProvider.family<J, String>(
  (ref, slug) => ref.watch(extrasRepoProvider).page(slug),
);
final supportUnreadProvider = FutureProvider<int>((ref) async {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  try {
    return (_m(await ref.watch(apiClientProvider).get('/support/unread'))['unread'] as num).toInt();
  } catch (_) {
    return 0;
  }
});

final spinProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).spinStatus();
});

final vipStatusProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).vipStatus();
});

final vipPlansProvider = FutureProvider<J>((ref) {
  ref.keepAlive();
  ref.watch(extrasRefreshProvider);
  return ref.watch(extrasRepoProvider).vipPlans();
});

class ExtrasRepository {
  ExtrasRepository(this._api);
  final ApiClient _api;

  // ---- shop
  Future<J> shop(String kind) async =>
      _m(await _api.get('/shop', query: {'kind': kind}, useCache: true, cacheMaxAge: const Duration(minutes: 5)));
  Future<List<J>> orders() async =>
      ((_m(await _api.get('/shop/orders', useCache: true, cacheMaxAge: const Duration(minutes: 2)))['orders'] as List)).map(_m).toList();
  Future<J> order(J body) async => _m(await _api.post('/shop/order', body: body));

  // ---- earn coins
  Future<J> earn() async =>
      _m(await _api.get('/earn', useCache: true, cacheMaxAge: const Duration(minutes: 5)));
  Future<J> adSession() async => _m(await _api.post('/earn/ad-session', body: {}));
  Future<J> adStatus(String nonce) async => _m(await _api.get('/earn/ad-session/$nonce'));
  Future<J> redeem(int coins) async => _m(await _api.post('/earn/redeem', body: {'coins': coins}));

  // ---- lucky spin
  Future<J> spinStatus() async => _m(await _api.get('/spin/status'));
  Future<J> spinPlay() async => _m(await _api.post('/spin/play', body: {}));

  // ---- vip & tier
  Future<J> vipPlans() async => _m(await _api.get('/vip/plans'));
  Future<J> vipStatus() async => _m(await _api.get('/vip/status'));
  Future<J> vipSubscribe(int planId) async => _m(await _api.post('/vip/subscribe', body: {'plan_id': planId}));

  // ---- wallet pin
  Future<J> setWalletPin({required String pin, required String password}) async =>
      _m(await _api.post('/wallet/pin/set', body: {'pin': pin, 'password': password}));
  Future<J> verifyWalletPin(String pin) async =>
      _m(await _api.post('/wallet/pin/verify', body: {'pin': pin}));

  // ---- share / promo
  Future<J> shareInfo() async =>
      _m(await _api.get('/share', useCache: true, cacheMaxAge: const Duration(minutes: 5)));
  Future<J> shareLookup(String to) async => _m(await _api.post('/share/lookup', body: {'to': to}));
  Future<J> shareSend({required String to, required String amount, required String password, String? note}) async =>
      _m(await _api.post('/share/send', body: {'to': to, 'amount': amount, 'password': password, if (note != null && note.isNotEmpty) 'note': note}));
  Future<J> promo(String code) async => _m(await _api.post('/promo/redeem', body: {'code': code}));

  // ---- support
  Future<J> tickets() async =>
      _m(await _api.get('/support/tickets', useCache: true, cacheMaxAge: const Duration(minutes: 2)));
  Future<J> ticket(int id) async => _m(await _api.get('/support/tickets/$id'));
  Future<J> newTicket({required String subject, required String category, required String message, String? imageB64}) async =>
      _m(await _api.post('/support/tickets', body: {
        'subject': subject, 'category': category, 'message': message,
        if (imageB64 != null) 'image_base64': imageB64,
      }));
  Future<J> reply(int id, {String body = '', String? imageB64}) async =>
      _m(await _api.post('/support/tickets/$id/messages', body: {'body': body, if (imageB64 != null) 'image_base64': imageB64}));
  Future<void> closeTicket(int id) async => _api.post('/support/tickets/$id/close', body: {});

  // ---- account
  Future<J> forgot(String email) async => _m(await _api.post('/auth/forgot', body: {'email': email}, auth: false));
  Future<J> reset({required String email, required String otp, required String password}) async =>
      _m(await _api.post('/auth/reset', body: {'email': email, 'otp': otp, 'new_password': password}, auth: false));
  Future<void> deleteAccount(String password) async =>
      _api.post('/me/delete', body: {'password': password, 'confirm': 'DELETE'});
  Future<J> page(String slug) async => _m(await _api.get('/pages/$slug', auth: false));
}
