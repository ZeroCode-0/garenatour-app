import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text.dart';

class BzField extends StatelessWidget {
  const BzField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onToggleObscure,
    this.errorText,
    this.maxLength,
    this.enabled = true,
    this.trailing,
    this.suffixText,
    this.onSuffixTap,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;
  final String? errorText;
  final int? maxLength;
  final bool enabled;
  final Widget? trailing;
  final String? suffixText;
  final VoidCallback? onSuffixTap;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Row(
            children: [
              Text(label.toUpperCase(), style: AppText.label.copyWith(fontSize: 10.5)),
              const Spacer(),
              if (suffixText != null)
                GestureDetector(
                  onTap: onSuffixTap,
                  child: Text(suffixText!, style: AppText.bodyS.copyWith(color: const Color(0xFFFF5A4E), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: AppText.bodyStrong.copyWith(fontSize: 14),
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: icon == null ? null : Icon(icon, size: 19),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 19),
                  )
                : trailing,
          ),
        ),
      ],
    );
  }
}

class BzValidators {
  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? phoneBD(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim()) ? null : 'Enter a valid 11-digit number';
  }

  static String? password(String? v, {int min = 8}) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < min ? 'At least $min characters' : null;
  }

  static String? amount(String? v, {double? min, double? max}) {
    final n = double.tryParse(v ?? '');
    if (n == null || n <= 0) return 'Enter a valid amount';
    if (min != null && n < min) return 'Minimum is ৳${min.toStringAsFixed(0)}';
    if (max != null && n > max) return 'Maximum is ৳${max.toStringAsFixed(0)}';
    return null;
  }
}
