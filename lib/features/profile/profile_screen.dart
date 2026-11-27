import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/launch.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_snack.dart';
import '../app_config/app_config_controller.dart';
import '../auth/auth_controller.dart';
import 'profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final stats = ref.watch(profileStatsProvider);
    final cfg = ref.watch(appConfigProvider).valueOrNull;

    if (user == null) return const Scaffold(body: BzBackground(child: SizedBox()));

    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.cardHi,
            onRefresh: () async => ref.invalidate(profileStatsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                Row(children: [
                  Text('Profile', style: AppText.h1.copyWith(fontSize: 26)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.notifications_none_rounded, size: 20),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                BzCard(
                  glow: AppColors.primary,
                  borderColor: AppColors.primary.withValues(alpha: 0.35),
                  child: Row(children: [
                    _Avatar(url: user.avatarUrl),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppText.h2.copyWith(fontSize: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(user.email, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4))),
                          child: Text('CODE  ${user.referCode}', style: AppText.label.copyWith(fontSize: 9.5, color: AppColors.cyan)),
                        ),
                      ],
                    )),
                    GestureDetector(
                      onTap: () => context.push('/profile/edit'),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primaryHi, size: 20),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                stats.valueOrNull != null
                    ? BzCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Row(children: [
                          _stat('MATCHES', '${stats.value!['matches_played'] ?? 0}'),
                          _div(),
                          _stat('WINS', '${stats.value!['wins'] ?? 0}'),
                          _div(),
                          _stat('KILLS', '${stats.value!['total_kills'] ?? 0}'),
                          _div(),
                          _stat('EARNINGS', Fmt.takaShort(stats.value!['prize_won'] ?? 0), color: AppColors.gold),
                        ]),
                      )
                    : stats.when(
                        loading: () => const SizedBox(height: 70),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (s) => BzCard(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Row(children: [
                            _stat('MATCHES', '${s['matches_played'] ?? 0}'),
                            _div(),
                            _stat('WINS', '${s['wins'] ?? 0}'),
                            _div(),
                            _stat('KILLS', '${s['total_kills'] ?? 0}'),
                            _div(),
                            _stat('EARNINGS', Fmt.takaShort(s['prize_won'] ?? 0), color: AppColors.gold),
                          ]),
                        ),
                      ),
                const SizedBox(height: 18),
                _MenuGroup(items: [
                  _MI(Icons.workspace_premium_rounded, 'VIP Membership & Tier', () => context.push('/vip')),
                  _MI(Icons.casino_rounded, 'Lucky Spin & Win Wheel', () => context.push('/spin')),
                  _MI(Icons.shopping_bag_rounded, 'My Shop Orders', () => context.push('/shop/orders')),
                  _MI(Icons.monetization_on_rounded, 'Earn Coins', () => context.push('/earn')),
                  _MI(Icons.swap_horiz_rounded, 'Balance Share', () => context.push('/share')),
                  _MI(Icons.card_giftcard_rounded, 'Promo Code', () => context.push('/promo')),
                ]),
                const SizedBox(height: 12),
                _MenuGroup(items: [
                  _MI(Icons.receipt_long_rounded, 'Transaction History', () => context.push('/transactions')),
                  _MI(Icons.emoji_events_rounded, 'Leaderboard', () => context.push('/leaderboard')),
                  _MI(Icons.redeem_rounded, 'Refer & Earn', () => context.push('/refer')),
                  _MI(Icons.sports_esports_rounded, 'My Matches', () => context.push('/matches')),
                ]),
                const SizedBox(height: 12),
                _MenuGroup(items: [
                  _MI(Icons.support_agent_rounded, 'Help & Support', () => context.push('/support')),
                  if (cfg?.links.telegram != null) _MI(Icons.telegram_rounded, 'Telegram', () => openLink(context, cfg!.links.telegram!)),
                  _MI(Icons.code_rounded, 'Developer', () => context.push('/developer')),
                  _MI(Icons.lock_reset_rounded, 'Change Password', () => context.push('/profile/edit')),
                ]),
                const SizedBox(height: 12),
                _MenuGroup(items: [
                  _MI(Icons.privacy_tip_rounded, 'Privacy Policy', () => context.push('/legal/privacy')),
                  _MI(Icons.gavel_rounded, 'Terms & Conditions', () => context.push('/legal/terms')),
                  _MI(Icons.person_remove_rounded, 'Delete Account', () => context.push('/account/delete'), danger: true),
                  _MI(Icons.logout_rounded, 'Log Out', () => _logout(context, ref), danger: true),
                ]),
                const SizedBox(height: 20),
                Center(child: Text('v${cfg?.android.version ?? '1.0.0'}   ·   POWERED BY NeXdEvE',
                    style: AppText.tiny.copyWith(color: AppColors.textFaint, letterSpacing: 1.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String l, String v, {Color? color}) => Expanded(
        child: Column(children: [
          Text(v, style: AppText.numXl.copyWith(fontSize: 17, color: color ?? AppColors.text)),
          const SizedBox(height: 2),
          Text(l, style: AppText.label.copyWith(fontSize: 8.5)),
        ]),
      );
  Widget _div() => Container(width: 1, height: 30, color: AppColors.line);

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(d);
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends ConsumerStatefulWidget {
  const _Avatar({this.url});
  final String? url;
  @override
  ConsumerState<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends ConsumerState<_Avatar> {
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(profileRepositoryProvider).uploadAvatar('data:image/jpeg;base64,${base64Encode(bytes)}');
      final u = ref.read(authControllerProvider).user;
      if (u != null) ref.read(authControllerProvider.notifier).patchUser(u.copyWith(avatarUrl: url));
      if (mounted) showSnack(context, 'Profile photo updated', kind: SnackKind.success);
    } catch (_) {
      if (mounted) showSnack(context, 'Upload failed', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _pick,
      child: Stack(children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGrad),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.cardHi,
            backgroundImage: widget.url != null ? CachedNetworkImageProvider(widget.url!) : null,
            child: widget.url == null ? const Icon(Icons.person_rounded, size: 30, color: AppColors.textMuted) : null,
          ),
        ),
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
            child: _busy
                ? const SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _MI {
  _MI(this.icon, this.label, this.onTap, {this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MI> items;
  @override
  Widget build(BuildContext context) {
    return BzCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < items.length; i++) ...[
          ListTile(
            onTap: items[i].onTap,
            leading: Icon(items[i].icon, size: 19, color: items[i].danger ? AppColors.danger : AppColors.primaryHi),
            title: Text(items[i].label, style: AppText.bodyM.copyWith(color: items[i].danger ? AppColors.danger : AppColors.text)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint, size: 19),
          ),
          if (i != items.length - 1) const Divider(height: 1, indent: 52),
        ],
      ]),
    );
  }
}
