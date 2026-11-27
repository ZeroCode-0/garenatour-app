import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/common.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text, _pass.text);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (_) {
      if (mounted) showSnack(context, 'Login failed. Try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BzBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Center(child: SvgPicture.asset('assets/icons/emblem.svg', width: 68)),
                      const SizedBox(height: 14),
                      const Center(child: GradientText('Garena Tour', style: AppText.h2)),
                      Center(
                        child: Text('POWERED BY NeXdEvE',
                            style: AppText.tiny.copyWith(color: AppColors.textFaint, letterSpacing: 2.4)),
                      ),
                      const SizedBox(height: 34),
                      Text('WELCOME BACK', style: AppText.h1),
                      const SizedBox(height: 6),
                      Text('Sign in to jump back into the arena', style: AppText.bodyM),
                      const SizedBox(height: 30),
                      BzField(
                        controller: _email,
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: BzValidators.email,
                      ),
                      const SizedBox(height: 16),
                      BzField(
                        controller: _pass,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                        suffixText: 'Forgot?',
                        onSuffixTap: () => context.push('/forgot'),
                        validator: (v) => BzValidators.password(v, min: 1),
                      ),
                      const SizedBox(height: 28),
                      BzButton(label: 'SIGN IN', loading: _loading, onPressed: _submit),
                      const SizedBox(height: 18),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('New here? ', style: AppText.bodyM),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text('Create account', style: AppText.bodyStrong.copyWith(color: AppColors.primaryHi)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
