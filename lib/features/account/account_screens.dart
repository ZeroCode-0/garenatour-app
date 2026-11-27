import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/gt_shapes.dart';
import '../auth/auth_controller.dart';
import '../extras/extras_repository.dart';

/// Forgot password: email → 6-digit OTP → new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _pass = TextEditingController();
  bool _sent = false, _busy = false, _hide = true;

  Future<void> _sendCode() async {
    if (!_email.text.contains('@')) {
      showSnack(context, 'Enter your account email.', kind: SnackKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(extrasRepoProvider).forgot(_email.text.trim());
      setState(() => _sent = true);
      if (mounted) showSnack(context, '${r['message']}', kind: SnackKind.success);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_otp.text.length != 6 || _pass.text.length < 8) {
      showSnack(context, 'Enter the 6-digit code and a new password (8+ characters).', kind: SnackKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(extrasRepoProvider).reset(email: _email.text.trim(), otp: _otp.text, password: _pass.text);
      if (!mounted) return;
      showSnack(context, 'Password changed. Sign in now.', kind: SnackKind.success);
      context.go('/login');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: BzBackground(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primaryHi),
          const SizedBox(height: 12),
          MetalText('FORGOT PASSWORD?', textAlign: TextAlign.center, style: AppText.h1.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text(_sent ? 'Enter the 6-digit code we emailed you.' : 'We will email you a 6-digit code.',
              textAlign: TextAlign.center, style: AppText.bodyM),
          const SizedBox(height: 24),
          BzField(controller: _email, label: 'EMAIL', hint: 'you@example.com', icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress, enabled: !_sent),
          if (_sent) ...[
            const SizedBox(height: 14),
            BzField(controller: _otp, label: 'CODE', hint: '6 digits', icon: Icons.pin_rounded, maxLength: 6,
                keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 6),
            BzField(controller: _pass, label: 'NEW PASSWORD', hint: '8+ characters', icon: Icons.lock_rounded,
                obscure: _hide, onToggleObscure: () => setState(() => _hide = !_hide)),
            const SizedBox(height: 20),
            BzButton(label: 'CHANGE PASSWORD', loading: _busy, onPressed: _busy ? null : _reset),
            TextButton(onPressed: _busy ? null : _sendCode, child: const Text('Send the code again')),
          ] else ...[
            const SizedBox(height: 20),
            BzButton(label: 'SEND CODE', icon: Icons.send_rounded, loading: _busy, onPressed: _busy ? null : _sendCode),
          ],
        ]),
      ),
    );
  }
}

/// Delete account (Play Store requirement).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _pass = TextEditingController();
  bool _agree = false, _busy = false;

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref.read(extrasRepoProvider).deleteAccount(_pass.text);
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      showSnack(context, 'Your account has been deleted.', kind: SnackKind.success);
      context.go('/login');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: BzBackground(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          GtCutCard(
            border: AppColors.danger.withValues(alpha: .5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                const SizedBox(width: 8),
                Text('This cannot be undone', style: AppText.bodyStrong.copyWith(color: AppColors.danger)),
              ]),
              const SizedBox(height: 10),
              Text('• Your profile, name, email and phone are removed.\n'
                  '• Remaining deposit & winning balance and coins are lost.\n'
                  '• Withdraw your winnings first.\n'
                  '• Pending withdrawals, orders or upcoming matches must finish first.',
                  style: AppText.bodyM.copyWith(height: 1.7)),
            ]),
          ),
          const SizedBox(height: 20),
          BzField(controller: _pass, label: 'PASSWORD', hint: 'Confirm with your password', icon: Icons.lock_rounded, obscure: true),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            activeColor: AppColors.danger,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('I understand, delete my account permanently.', style: AppText.bodyM),
          ),
          const SizedBox(height: 10),
          BzButton(label: 'DELETE MY ACCOUNT', kind: BzBtn.danger, loading: _busy,
              onPressed: _agree && _pass.text.isNotEmpty && !_busy ? _delete : null),
        ]),
      ),
    );
  }
}

/// Privacy / Terms (text managed by admin).
class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.slug});
  final String slug;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(legalPageProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(slug == 'terms' ? 'Terms & Conditions' : 'Privacy Policy')),
      body: BzBackground(
        child: page.when(
          loading: () => const BzLoader(),
          error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(legalPageProvider(slug))),
          data: (p) => ListView(padding: const EdgeInsets.all(20), children: [
            Text('${p['body']}'.isEmpty ? 'Coming soon.' : '${p['body']}', style: AppText.bodyM.copyWith(height: 1.7)),
          ]),
        ),
      ),
    );
  }
}
