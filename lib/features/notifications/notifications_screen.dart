import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _S();
}

class _S extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationsRepoProvider).markAllRead();
      ref.read(notificationsRefreshProvider.notifier).state++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: list.when(
            loading: () => const BzSkeletonList(itemHeight: 76),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(notificationsListProvider)),
            data: (items) => items.isEmpty
                ? const BzEmpty(title: 'No notifications yet', message: 'Match alerts, results and payouts show up here.', icon: Icons.notifications_none_rounded)
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardHi,
                    onRefresh: () async => ref.invalidate(notificationsListProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return BzCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          borderColor: n.isRead ? AppColors.line : AppColors.primary.withValues(alpha: 0.5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: AppColors.cardHi, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryHi, size: 19),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: AppText.bodyStrong),
                                const SizedBox(height: 3),
                                Text(n.body, style: AppText.bodyM),
                                const SizedBox(height: 6),
                                Text(Fmt.relative(n.createdAt), style: AppText.bodyS),
                              ],
                            )),
                          ]),
                        ).stagger(i);
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
