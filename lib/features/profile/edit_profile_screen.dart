import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_controller.dart';
import 'profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _S();
}

class _S extends ConsumerState<EditProfileScreen> {
  late final _name = TextEditingController(text: ref.read(authControllerProvider).user?.name ?? '');
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  bool _savingName = false, _savingPass = false, _o1 = true, _o2 = true;

  @override
  void dispose() {
    for (final c in [_name, _cur, _new, _new2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_name.text.trim().length < 2) return showSnack(context, 'Name too short', kind: SnackKind.error);
    setState(() => _savingName = true);
    try {
      final u = await ref.read(profileRepositoryProvider).updateName(_name.text.trim());
      ref.read(authControllerProvider.notifier).patchUser(u);
      if (mounted) showSnack(context, 'Name updated', kind: SnackKind.success);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePass() async {
    if (_new.text.length < 8) return showSnack(context, 'New password must be at least 8 characters', kind: SnackKind.error);
    if (_new.text != _new2.text) return showSnack(context, 'Passwords do not match', kind: SnackKind.error);
    setState(() => _savingPass = true);
    try {
      await ref.read(profileRepositoryProvider).changePassword(current: _cur.text, next: _new.text);
      if (mounted) {
        showSnack(context, 'Password changed. Please sign in again.', kind: SnackKind.success);
        await ref.read(authControllerProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SectionHeader('Account'),
              BzField(controller: _name, label: 'Display Name', icon: Icons.person_outline_rounded, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 10),
              _ReadOnly(label: 'Email', value: user?.email ?? ''),
              const SizedBox(height: 10),
              _ReadOnly(label: 'Phone', value: user?.phone ?? ''),
              const SizedBox(height: 14),
              BzButton(label: 'SAVE NAME', loading: _savingName, onPressed: _saveName),
              const SizedBox(height: 28),
              const SectionHeader('Change Password'),
              BzField(controller: _cur, label: 'Current Password', obscure: _o1, icon: Icons.lock_outline_rounded, onToggleObscure: () => setState(() => _o1 = !_o1)),
              const SizedBox(height: 12),
              BzField(controller: _new, label: 'New Password', obscure: _o2, icon: Icons.lock_rounded, onToggleObscure: () => setState(() => _o2 = !_o2)),
              const SizedBox(height: 12),
              BzField(controller: _new2, label: 'Confirm New Password', obscure: _o2, icon: Icons.lock_rounded),
              const SizedBox(height: 8),
              Text('For security, changing the password logs out all devices.', style: AppText.bodyS),
              const SizedBox(height: 14),
              BzButton(label: 'CHANGE PASSWORD', kind: BzBtn.ghost, loading: _savingPass, onPressed: _savePass),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnly extends StatelessWidget {
  const _ReadOnly({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 3, bottom: 7), child: Text(label.toUpperCase(), style: AppText.label.copyWith(fontSize: 10.5))),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line)),
            child: Text(value, style: AppText.bodyM.copyWith(color: AppColors.textMuted)),
          ),
        ],
      );
}
