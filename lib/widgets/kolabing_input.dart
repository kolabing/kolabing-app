import 'package:flutter/material.dart';
import 'package:kolabing_app/config/constants/radius.dart';
import 'package:kolabing_app/config/theme/color_tokens.dart';
import 'package:kolabing_app/config/theme/typography.dart';

class KolabingInput extends StatelessWidget {
  const KolabingInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onTap,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      textInputAction: textInputAction,
      style: KolabingTextStyles.bodyLg.copyWith(color: colors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.surface,
        hintStyle: KolabingTextStyles.bodyLg.copyWith(color: colors.muted),
        labelStyle: KolabingTextStyles.bodySm.copyWith(color: colors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
    );
  }
}
