import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _refer = TextEditingController();
  bool _obscure = true, _loading = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _refer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text, email: _email.text, phone: _phone.text,
            password: _pass.text, referCode: _refer.text,
          );
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation && e.fieldErrors.isNotEmpty) {
        setState(() => _serverErrors = e.fieldErrors);
      } else {
        showSnack(context, e.message, kind: SnackKind.error);
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Registration failed. Try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('CREATE ACCOUNT', style: AppText.h1),
                    const SizedBox(height: 6),
                    Text('Join the arena — win real cash', style: AppText.bodyM),
                    const SizedBox(height: 26),
                    BzField(
                      controller: _name, label: 'Full Name', hint: 'Your name',
                      icon: Icons.person_outline_rounded, textCapitalization: TextCapitalization.words,
                      errorText: _serverErrors['name'], validator: (v) => BzValidators.required(v, 'Name'),
                    ),
                    const SizedBox(height: 14),
                    BzField(
                      controller: _email, label: 'Email', hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress,
                      errorText: _serverErrors['email'], validator: BzValidators.email,
                    ),
                    const SizedBox(height: 14),
                    BzField(
                      controller: _phone, label: 'Phone (bKash/Nagad Number)', hint: '01XXXXXXXXX',
                      icon: Icons.smartphone_rounded, keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                      errorText: _serverErrors['phone'], validator: BzValidators.phoneBD,
                    ),
                    const SizedBox(height: 14),
                    BzField(
                      controller: _pass, label: 'Password', hint: 'At least 8 characters',
                      icon: Icons.lock_outline_rounded, obscure: _obscure,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      errorText: _serverErrors['password'], validator: (v) => BzValidators.password(v, min: 8),
                    ),
                    const SizedBox(height: 14),
                    BzField(
                      controller: _refer, label: 'Referral Code (Optional)', hint: "Friend's code for bonus",
                      icon: Icons.redeem_rounded, textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(12)],
                      errorText: _serverErrors['refer_code'],
                    ),
                    const SizedBox(height: 24),
                    BzButton(label: 'CREATE ACCOUNT', loading: _loading, onPressed: _submit),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: AppText.bodyM),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text('Sign in', style: AppText.bodyStrong.copyWith(color: AppColors.primaryHi)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
