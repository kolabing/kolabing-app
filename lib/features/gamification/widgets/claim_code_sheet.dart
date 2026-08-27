import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../providers/encounter_provider.dart';
import '../services/encounter_service.dart';

/// Redeeming an invite code (kolabing-v2#246).
///
/// This exists because **a Universal Link does not survive an install.** The
/// link handles the case where the app was already there; this handles the case
/// the feature is actually for — someone who had to walk through the App Store,
/// where no link can carry a token.
///
/// Opened two ways: from the deep-link handler with the code pre-filled, and
/// from a plain entry point where somebody types it in.
class ClaimCodeSheet extends ConsumerStatefulWidget {
  const ClaimCodeSheet({super.key, this.initialCode});

  /// Pre-filled when we arrived from `/i/{code}`, so the person never has to
  /// read their own link back to themselves.
  final String? initialCode;

  static Future<bool?> open(BuildContext context, {String? initialCode}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimCodeSheet(initialCode: initialCode),
    );
  }

  @override
  ConsumerState<ClaimCodeSheet> createState() => _ClaimCodeSheetState();
}

class _ClaimCodeSheetState extends ConsumerState<ClaimCodeSheet> {
  late final TextEditingController _code = TextEditingController(
    text: widget.initialCode ?? '',
  );

  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final code = _code.text.trim();
    if (code.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context);
    try {
      final encounter = await ref.read(encounterServiceProvider).claim(code);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success = l10n.claimCodeSuccess(
          encounter.displayName,
          encounter.pendingPoints,
        );
      });
      // The wallet and the "people you've met" list both just moved.
      ref.invalidate(myEncountersProvider);
    } on EncounterException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = _messageFor(e, l10n);
      });
    }
  }

  /// Localized off the classified reason, never off the backend's English.
  String _messageFor(EncounterException e, AppLocalizations l10n) {
    if (e.invalidClaimCode) return l10n.claimCodeInvalid;
    if (e.claimExpired) return l10n.claimCodeExpired;
    if (e.claimNotNewAccount) return l10n.claimCodeNotNewAccount;
    if (e.claimSelf) return l10n.claimCodeSelf;
    return l10n.claimCodeFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final success = _success;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                success == null ? l10n.claimCodeTitle : l10n.claimCodeClaimed,
                style: KolabingTextStyles.titleLarge.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                success ?? l10n.claimCodeBody,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: success == null
                      ? context.colors.onSurfaceVariant
                      : context.colors.xpGreen,
                ),
              ),
              if (success == null) ...[
                const SizedBox(height: KolabingSpacing.lg),
                TextField(
                  controller: _code,
                  autofocus: widget.initialCode == null,
                  textCapitalization: TextCapitalization.characters,
                  // The codes are drawn from an unambiguous alphabet, so
                  // anything else is a typo rather than something to preserve.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                    _UpperCaseFormatter(),
                  ],
                  decoration: InputDecoration(labelText: l10n.claimCodeLabel),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _claim(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: KolabingSpacing.sm),
                  Text(
                    _error!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: KolabingSpacing.lg),
                KolabingButton(
                  label: l10n.claimCodeSubmit,
                  onPressed: _code.text.trim().isEmpty || _sending
                      ? null
                      : _claim,
                  isLoading: _sending,
                  variant: KolabingButtonVariant.primary,
                ),
              ] else ...[
                const SizedBox(height: KolabingSpacing.lg),
                KolabingButton(
                  label: l10n.commonDone,
                  onPressed: () => Navigator.of(context).pop(true),
                  variant: KolabingButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Codes are stored upper-case; typing them lower-case should still work, and
/// seeing them change under your fingers is the clearest way to say so.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
