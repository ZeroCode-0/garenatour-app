import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../models/misc.dart';

final _apiProvider = apiClientProvider;

final unreadCountProvider = FutureProvider<int>((ref) async {
  ref.keepAlive();
  final ApiClient api = ref.watch(_apiProvider);
  ref.watch(notificationsRefreshProvider);
  try {
    final data = await api.get('/notifications/unread-count', useCache: true, cacheMaxAge: const Duration(minutes: 1));
    return (data as Map)['unread'] as int? ?? 0;
  } catch (_) {
    return 0;
  }
});

/// bump to force a refresh (after opening the notifications screen, etc.)
final notificationsRefreshProvider = StateProvider<int>((ref) => 0);

final notificationsListProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  ref.keepAlive();
  final ApiClient api = ref.watch(_apiProvider);
  ref.watch(notificationsRefreshProvider);
  final data = await api.get('/notifications', query: {'page': 1}, useCache: true, cacheMaxAge: const Duration(minutes: 2));
  final list = ((data as Map)['notifications'] as List).cast<Map<String, dynamic>>();
  return list.map(AppNotification.fromJson).toList();
});

final notificationsRepoProvider = Provider<NotificationsRepo>(
  (ref) => NotificationsRepo(ref.watch(apiClientProvider)),
);

class NotificationsRepo {
  NotificationsRepo(this._api);
  final ApiClient _api;

  Future<void> markAllRead() => _api.post('/notifications/read', body: {});
}
