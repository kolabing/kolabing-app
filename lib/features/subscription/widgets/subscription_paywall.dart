import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/referral_code_field.dart';
import '../../auth/models/auth_response.dart';
import '../../business/providers/profile_provider.dart';
import '../providers/iap_provider.dart';

/// Subscription paywall shown when business users try to publish
/// without an active subscription.
///
/// Usage:
/// ```dart
/// final canPublish = await SubscriptionPaywall.checkAndShow(context, ref);
/// if (canPublish) { /* proceed with publish */ }
/// ```
class SubscriptionPaywall extends ConsumerStatefulWidget {
  const SubscriptionPaywall({super.key});

  /// Check subscription status and show paywall if not active.
  /// Returns true if user has an active subscription and can publish.
  static Future<bool> checkAndShow(BuildContext context, WidgetRef ref) async {
    final profileState = ref.read(profileProvider);
    if (profileState.isSubscribed) return true;

    // Show paywall
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPaywall(),
    );

    return result ?? false;
  }

  @override
  ConsumerState<SubscriptionPaywall> createState() =>
      _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends ConsumerState<SubscriptionPaywall> {
  bool _isLoading = false;
  final _referralCodeController = TextEditingController();
  String? _referralCodeApiError;
  String? _referralCodeHelperText;

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubscribe() async {
    setState(() {
      _referralCodeApiError = null;
      _referralCodeHelperText = null;
    });
    if (Platform.isIOS) {
      await _handleAppleSubscribe();
    } else {
      await _handleStripeSubscribe();
    }
  }

  /// iOS: Use Apple IAP
  Future<void> _handleAppleSubscribe() async {
    final iapNotifier = ref.read(iapProvider.notifier);
    try {
      final result = await iapNotifier.purchase(
        referralCode: _referralCodeController.text,
      );
      if (!mounted) return;
      if (result.validatedReferralCode != null) {
        _setValidatedReferralCode(result.validatedReferralCode!);
      }
      // Purchase result handled by listener in build method
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _referralCodeApiError = e.error.getFriendlyFieldError('referral_code');
      });
      if (_referralCodeApiError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.error.message),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: KolabingColors.error,
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start App Store purchase'),
          backgroundColor: KolabingColors.error,
        ),
      );
    }
  }

  /// Android/Other: Use Stripe (existing flow)
  Future<void> _handleStripeSubscribe() async {
    setState(() => _isLoading = true);

    try {
      final url = await ref
          .read(profileServiceProvider)
          .createCheckoutSession(
            successUrl: 'kolabing://subscription/success',
            cancelUrl: 'kolabing://subscription/cancel',
            referralCode: _referralCodeController.text,
          );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await ref.read(profileProvider.notifier).refreshSubscription();
        final subscription = ref.read(profileProvider).subscription;
        if (mounted) {
          Navigator.of(context).pop(subscription?.isActive ?? false);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _referralCodeApiError = e.error.getFriendlyFieldError('referral_code');
      });
      if (_referralCodeApiError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.error.message),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: KolabingColors.error,
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create checkout session'),
          backgroundColor: KolabingColors.error,
        ),
      );
    }
  }

  void _setValidatedReferralCode(String validatedReferralCode) {
    _referralCodeController.value = TextEditingValue(
      text: validatedReferralCode,
      selection: TextSelection.collapsed(offset: validatedReferralCode.length),
    );
    setState(() {
      _referralCodeApiError = null;
      _referralCodeHelperText = 'Referral code applied.';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always watch/listen unconditionally (Riverpod hooks must be stable)
    final iapState = ref.watch(iapProvider);
    final isLoading = Platform.isIOS
        ? iapState.isPurchasing || iapState.isRestoring
        : _isLoading;
    final canStartApplePurchase = !Platform.isIOS || iapState.canPurchase;
    final purchaseStatusMessage =
        iapState.error ??
        (Platform.isIOS ? iapState.purchaseAvailabilityMessage : null);

    ref.listen<IAPState>(iapProvider, (prev, next) {
      if (!Platform.isIOS) return;
      if ((prev?.isPurchasing ?? false) &&
          !next.isPurchasing &&
          next.error == null) {
        // Purchase succeeded — close paywall
        final subscription = ref.read(profileProvider).subscription;
        if (mounted) {
          Navigator.of(context).pop(subscription?.isActive ?? true);
        }
      }
    });

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: KolabingColors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.crown,
                  color: KolabingColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Title
              Text(
                'Upgrade to Premium',
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                "You've used your 1 free kolab request. Subscribe to create unlimited requests and connect with more communities.",
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Benefits
              _buildBenefitRow(
                LucideIcons.infinity,
                'Publish unlimited kolab requests',
              ),
              _buildBenefitRow(
                LucideIcons.users,
                'Connect with local communities',
              ),
              _buildBenefitRow(
                LucideIcons.inbox,
                'Receive and manage applications',
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: KolabingColors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: KolabingColors.softYellowBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!Platform.isIOS || iapState.monthlyProduct != null) ...[
                      Text(
                        Platform.isIOS ? iapState.priceString : '29 EUR',
                        style: KolabingTextStyles.headlineLarge.copyWith(
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Text(
                        '/ month',
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                    ] else
                      Text(
                        iapState.isLoadingProducts
                            ? 'Loading App Store price...'
                            : 'Subscription unavailable',
                        style: KolabingTextStyles.titleMedium.copyWith(
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              ReferralCodeField(
                controller: _referralCodeController,
                enabled: !isLoading,
                errorText: _referralCodeApiError,
                helperText: _referralCodeHelperText,
                onChanged: (_) {
                  if (_referralCodeApiError != null ||
                      _referralCodeHelperText != null) {
                    setState(() {
                      _referralCodeApiError = null;
                      _referralCodeHelperText = null;
                    });
                  }
                },
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading || !canStartApplePurchase
                      ? null
                      : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor: KolabingColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KolabingColors.onPrimary,
                          ),
                        )
                      : Text(
                          'SUBSCRIBE NOW',
                          style: KolabingTextStyles.button.copyWith(
                            color: KolabingColors.onPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Not now button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Not Now',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ),

              // Restore Purchases (iOS only — Apple requires this)
              if (Platform.isIOS) ...[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(iapProvider.notifier).restore(),
                  child: Text(
                    'Restore Purchases',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              // IAP status / error message
              if (Platform.isIOS) ...[
                Builder(
                  builder: (context) {
                    if (purchaseStatusMessage == null) {
                      return const SizedBox.shrink();
                    }

                    final messageColor =
                        iapState.error != null ||
                            (!iapState.isLoadingProducts &&
                                !iapState.canPurchase)
                        ? KolabingColors.error
                        : KolabingColors.textTertiary;

                    return Padding(
                      padding: const EdgeInsets.only(top: KolabingSpacing.xs),
                      child: Text(
                        purchaseStatusMessage,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: messageColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: KolabingColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KolabingColors.success, size: 16),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
