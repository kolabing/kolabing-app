import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolabing_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../providers/wallet_provider.dart';

/// Withdrawal request screen where users enter IBAN and request a payout.
///
/// Route: /community/wallet/withdraw
class WithdrawalRequestScreen extends ConsumerStatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  ConsumerState<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState
    extends ConsumerState<WithdrawalRequestScreen> {
  final _ibanController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ibanController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _ibanController.text.trim().isNotEmpty &&
      _accountHolderController.text.trim().isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final success = await ref
        .read(walletProvider.notifier)
        .requestWithdrawal(
          iban: _ibanController.text.trim(),
          accountHolder: _accountHolderController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      final error = ref.read(walletProvider).error;
      setState(
        () => _errorMessage =
            error ?? AppLocalizations.of(context).withdrawalRequestFailed,
      );
    }
  }

  String? _validateIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).withdrawalIbanRequired;
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 15 || cleaned.length > 34) {
      return AppLocalizations.of(context).withdrawalIbanInvalid;
    }
    return null;
  }

  String? _validateAccountHolder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).withdrawalAccountHolderRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    const eurValue = 75.0; // fixed referral cash milestone

    return Scaffold(
      backgroundColor: context.colors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context).withdrawalScreenTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, letterSpacing: 1.0),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: KeyboardAvoidingContent(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: _isSuccess
              ? _buildSuccessState()
              : _buildForm(state, eurValue),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Success State
  // ---------------------------------------------------------------------------

  Widget _buildSuccessState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.activeBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.checkCircle,
            size: 40,
            color: context.colors.activeText,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          AppLocalizations.of(context).withdrawalSuccessTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          AppLocalizations.of(context).withdrawalSuccessMessage,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.onSurface,
              side: BorderSide(color: context.colors.darkBorder),
            ),
            child: Text(
              AppLocalizations.of(context).withdrawalBackToWallet,
              style: KolabingTextStyles.button,
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  Widget _buildForm(WalletState state, double eurValue) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.wallet,
                  color: context.colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: KolabingSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).withdrawalAvailableLabel,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EUR ${eurValue.toStringAsFixed(2)}',
                      style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: context.colors.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: KolabingSpacing.lg),

        // IBAN field
        Text(
          AppLocalizations.of(context).withdrawalIbanLabel,
          style: KolabingTextStyles.labelMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _ibanController,
          maxLength: 34,
          textCapitalization: TextCapitalization.characters,
          validator: _validateIban,
          onChanged: (_) => setState(() {}),
          hint: AppLocalizations.of(context).withdrawalIbanHint,
          counterText: '',
        ),

        const SizedBox(height: KolabingSpacing.md),

        // Account Holder Name field
        Text(
          AppLocalizations.of(context).withdrawalAccountHolderLabel,
          style: KolabingTextStyles.labelMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _accountHolderController,
          textCapitalization: TextCapitalization.words,
          validator: _validateAccountHolder,
          onChanged: (_) => setState(() {}),
          hint: AppLocalizations.of(context).withdrawalAccountHolderHint,
        ),

        const SizedBox(height: KolabingSpacing.lg),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isFormValid && !state.isWithdrawing
                ? _handleSubmit
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              disabledBackgroundColor: context.colors.primary.withValues(
                alpha: 0.4,
              ),
              disabledForegroundColor: context.colors.onPrimary.withValues(
                alpha: 0.5,
              ),
            ),
            child: state.isWithdrawing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onPrimary,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).withdrawalSubmitButton(
                      eurValue.toStringAsFixed(2),
                    ),
                    style: KolabingTextStyles.button,
                  ),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            _errorMessage!,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
      ],
    ),
  );
}
