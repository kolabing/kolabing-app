import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(iapProvider.notifier).refreshProducts();
      });
    }
  }

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
            backgroundColor: context.colors.error,
          ),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.colors.error,
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).subscriptionPaywallAppleError,
          ),
          backgroundColor: context.colors.error,
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
            backgroundColor: context.colors.error,
          ),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.colors.error,
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).subscriptionPaywallCheckoutError,
          ),
          backgroundColor: context.colors.error,
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
      _referralCodeHelperText = AppLocalizations.of(
        context,
      ).subscriptionReferralCodeApplied;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      decoration: BoxDecoration(
        color: context.colors.surface,
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
                  color: context.colors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.colors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.crown,
                  color: context.colors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Title
              Text(
                l10n.subscriptionPaywallTitle,
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                l10n.subscriptionPaywallDescription,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Benefits
              _buildBenefitRow(
                LucideIcons.infinity,
                l10n.subscriptionPaywallBenefitUnlimited,
              ),
              _buildBenefitRow(
                LucideIcons.users,
                l10n.subscriptionPaywallBenefitConnect,
              ),
              _buildBenefitRow(
                LucideIcons.inbox,
                l10n.subscriptionPaywallBenefitApplications,
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: context.colors.softYellowBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!Platform.isIOS || iapState.monthlyProduct != null) ...[
                      Text(
                        Platform.isIOS ? iapState.priceString : '29 EUR',
                        style: KolabingTextStyles.headlineLarge.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Text(
                        l10n.subscriptionPaywallPerMonth,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ] else
                      Text(
                        iapState.isLoadingProducts
                            ? l10n.subscriptionLoadingApplePrice
                            : l10n.subscriptionUnavailable,
                        style: KolabingTextStyles.titleMedium.copyWith(
                          color: context.colors.onSurface,
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
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor: context.colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.onPrimary,
                          ),
                        )
                      : Text(
                          l10n.subscriptionPaywallSubscribeButton,
                          style: KolabingTextStyles.button.copyWith(
                            color: context.colors.onPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Not now button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.subscriptionPaywallNotNowButton,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: context.colors.textTertiary,
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
                    l10n.subscriptionRestorePurchasesButton,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
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
                        ? context.colors.error
                        : context.colors.textTertiary;

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
            color: context.colors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.colors.success, size: 16),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
