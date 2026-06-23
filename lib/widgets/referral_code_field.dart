import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kolabing_app/config/theme/color_tokens.dart';

import '../l10n/app_localizations.dart';
import 'kolabing_input.dart';

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
  Widget build(BuildContext context) => KolabingInput(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    label: AppLocalizations.of(context).referralCodeFieldLabel,
    hint: AppLocalizations.of(context).referralCodeFieldHint,
    errorText: errorText,
    helperText: errorText == null ? helperText : null,
    helperStyle: TextStyle(color: context.colors.success),
    prefix: const Icon(Icons.card_giftcard_outlined),
    inputFormatters: const <TextInputFormatter>[_UppercaseTextFormatter()],
    autocorrect: false,
    textCapitalization: TextCapitalization.characters,
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
