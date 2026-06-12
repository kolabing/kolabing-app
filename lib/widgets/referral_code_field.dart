import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme/colors.dart';
import '../l10n/app_localizations.dart';

class ReferralCodeField extends StatelessWidget {
  const ReferralCodeField({
    required this.controller,
    required this.enabled,
    super.key,
    this.focusNode,
    this.errorText,
    this.helperText,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    autocorrect: false,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: const <TextInputFormatter>[_UppercaseTextFormatter()],
    decoration: InputDecoration(
      labelText: AppLocalizations.of(context).referralCodeFieldLabel,
      hintText: AppLocalizations.of(context).referralCodeFieldHint,
      errorText: errorText,
      helperText: errorText == null ? helperText : null,
      helperStyle: TextStyle(color: context.colors.success),
      prefixIcon: const Icon(Icons.card_giftcard_outlined),
      filled: true,
      fillColor: context.colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.error, width: 2),
      ),
    ),
    onChanged: onChanged,
  );
}

class _UppercaseTextFormatter extends TextInputFormatter {
  const _UppercaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final uppercased = newValue.text.toUpperCase();
    return newValue.copyWith(text: uppercased);
  }
}
