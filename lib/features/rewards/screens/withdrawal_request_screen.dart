import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
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

    final success = await ref.read(walletProvider.notifier).requestWithdrawal(
          iban: _ibanController.text.trim(),
          accountHolder: _accountHolderController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      final error = ref.read(walletProvider).error;
      setState(() => _errorMessage = error ?? 'Withdrawal request failed');
    }
  }

  String? _validateIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IBAN is required';
    }
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 15 || cleaned.length > 34) {
      return 'Please enter a valid IBAN (15-34 characters)';
    }
    return null;
  }

  String? _validateAccountHolder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account holder name is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);
    final wallet = state.wallet;
    final eurValue = wallet?.eurValue ?? 0.0;

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'WITHDRAW',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: _isSuccess ? _buildSuccessState() : _buildForm(state, eurValue),
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
        color: KolabingColors.surface,
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
            decoration: const BoxDecoration(
              color: KolabingColors.activeBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              size: 40,
              color: KolabingColors.activeText,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            'Request Submitted',
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'Your withdrawal request has been submitted successfully. Processing within 5-7 business days.',
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'BACK TO WALLET',
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
              color: KolabingColors.surface,
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
                    color: KolabingColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    color: KolabingColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: KolabingSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available to withdraw',
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EUR ${eurValue.toStringAsFixed(2)}',
                        style: GoogleFonts.rubik(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: KolabingColors.textPrimary,
                        ),
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
            'IBAN',
            style: KolabingTextStyles.labelMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextFormField(
            controller: _ibanController,
            maxLength: 34,
            textCapitalization: TextCapitalization.characters,
            validator: _validateIban,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. DE89 3704 0044 0532 0130 00',
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textTertiary,
              ),
              filled: true,
              fillColor: KolabingColors.surface,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide:
                    const BorderSide(color: KolabingColors.borderFocus),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide:
                    const BorderSide(color: KolabingColors.borderError),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Account Holder Name field
          Text(
            'ACCOUNT HOLDER NAME',
            style: KolabingTextStyles.labelMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextFormField(
            controller: _accountHolderController,
            textCapitalization: TextCapitalization.words,
            validator: _validateAccountHolder,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Full name on bank account',
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textTertiary,
              ),
              filled: true,
              fillColor: KolabingColors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide:
                    const BorderSide(color: KolabingColors.borderFocus),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide:
                    const BorderSide(color: KolabingColors.borderError),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _isFormValid && !state.isWithdrawing ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                disabledBackgroundColor:
                    KolabingColors.primary.withValues(alpha: 0.4),
                disabledForegroundColor:
                    KolabingColors.onPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: state.isWithdrawing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KolabingColors.onPrimary,
                      ),
                    )
                  : Text(
                      'WITHDRAW EUR ${eurValue.toStringAsFixed(2)}',
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
                color: KolabingColors.error,
              ),
            ),
          ],
        ],
      ),
    );
}
