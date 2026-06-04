import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../../widgets/referral_code_field.dart';
import '../../auth/models/auth_response.dart';
import '../../business/models/subscription.dart';
import '../../business/providers/profile_provider.dart';
import '../providers/iap_provider.dart';

/// Subscription management screen for business users.
///
/// Shows subscription status with different states:
/// - No subscription: benefits + subscribe CTA
/// - Active: plan details + manage/cancel options
/// - Cancelled/pending cancel: active-until date + resubscribe
/// - Past due: payment failed warning + update payment
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isCancelling = false;
  bool _isReactivating = false;
  bool _isSubscribing = false;
  final _referralCodeController = TextEditingController();
  String? _referralCodeApiError;
  String? _referralCodeHelperText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).refreshSubscription();
      if (Platform.isIOS) {
        ref.read(iapProvider.notifier).refreshProducts();
      }
    });
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
      try {
        final result = await ref
            .read(iapProvider.notifier)
            .purchase(referralCode: _referralCodeController.text);
        if (!mounted) return;
        if (result.validatedReferralCode != null) {
          _setValidatedReferralCode(result.validatedReferralCode!);
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _referralCodeApiError = e.error.getFriendlyFieldError(
            'referral_code',
          );
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).subscriptionScreenAppleError,
            ),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
    } else {
      // Android: Use Stripe
      setState(() => _isSubscribing = true);
      try {
        final url = await ref
            .read(profileServiceProvider)
            .createCheckoutSession(
              successUrl: 'kolabing://subscription/success',
              cancelUrl: 'kolabing://subscription/cancel',
              referralCode: _referralCodeController.text,
            );

        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() => _isSubscribing = false);
          await Future<void>.delayed(const Duration(seconds: 2));
          await ref.read(profileProvider.notifier).refreshSubscription();
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubscribing = false;
          _referralCodeApiError = e.error.getFriendlyFieldError(
            'referral_code',
          );
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
        setState(() => _isSubscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: KolabingColors.error,
          ),
        );
      } on Exception {
        if (!mounted) return;
        setState(() => _isSubscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).subscriptionScreenCheckoutError,
            ),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
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

  Future<void> _handleManageBilling() async {
    if (Platform.isIOS) {
      // iOS: Open iOS Settings > Subscriptions (Apple-approved method)
      await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      // Android: Open Stripe billing portal
      final url = await ref
          .read(profileProvider.notifier)
          .getBillingPortalUrl();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (mounted) {
          await Future<void>.delayed(const Duration(seconds: 2));
          await ref.read(profileProvider.notifier).refreshSubscription();
        }
      }
    }
  }

  Future<void> _handleReactivate() async {
    setState(() => _isReactivating = true);
    final success = await ref
        .read(profileProvider.notifier)
        .reactivateSubscription();
    if (mounted) {
      setState(() => _isReactivating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).subscriptionReactivateSuccess,
            ),
            backgroundColor: KolabingColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    final subscription = ref.read(profileProvider).subscription;

    // iOS with Apple IAP: redirect to App Store subscriptions
    if (Platform.isIOS && (subscription?.isAppleIAP ?? false)) {
      await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // Android / Stripe: cancel via API
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).subscriptionCancelDialogTitle),
        content: Text(
          AppLocalizations.of(context).subscriptionCancelDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).subscriptionKeepButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: Text(
              AppLocalizations.of(context).subscriptionCancelButton,
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      setState(() => _isCancelling = true);
      final success = await ref
          .read(profileProvider.notifier)
          .cancelSubscription();
      if (mounted) {
        setState(() => _isCancelling = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).subscriptionCancelScheduledToast,
              ),
              backgroundColor: KolabingColors.success,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final iapState = Platform.isIOS ? ref.watch(iapProvider) : null;

    ref
      ..listen<ProfileState>(profileProvider, (previous, next) {
        if (next.error != null && previous?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: KolabingColors.error,
            ),
          );
        }
      })
      ..listen<IAPState>(iapProvider, (previous, next) {
        if (!Platform.isIOS) return;
        if (next.error != null && previous?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: KolabingColors.error,
            ),
          );
        }
      });

    return Scaffold(
      backgroundColor: KolabingColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).subscriptionScreenTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
        ),
        backgroundColor: KolabingColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: KeyboardAvoidingContent(
          child: state.isLoading && !state.isInitialized
              ? _buildLoadingState()
              : _buildContent(state.subscription, state.isSubscribed, iapState),
        ),
      ),
    );
  }

  Widget _buildLoadingState() => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.all(KolabingSpacing.md),
    child: Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: KolabingSpacing.md),
          child: Shimmer.fromColors(
            baseColor: KolabingColors.surfaceVariant,
            highlightColor: KolabingColors.surface,
            child: Container(
              height: index == 0 ? 200 : 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KolabingRadius.borderRadiusLg,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent(
    Subscription? subscription,
    bool isSubscribed,
    IAPState? iapState,
  ) {
    final isActive = isSubscribed;
    final isPastDue = subscription?.status == SubscriptionStatus.pastDue;
    final isCancelPending = subscription?.cancelAtPeriodEnd ?? false;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          _buildStatusCard(subscription, isActive, isPastDue, isCancelPending),
          const SizedBox(height: KolabingSpacing.lg),

          // Benefits section
          if (!isActive) ...[
            _buildBenefitsSection(iapState),
            const SizedBox(height: KolabingSpacing.lg),
          ],

          // Plan details (when active)
          if (isActive) ...[
            _buildPlanDetails(subscription!),
            const SizedBox(height: KolabingSpacing.lg),
          ],

          // Past due warning
          if (isPastDue) ...[
            _buildPastDueWarning(),
            const SizedBox(height: KolabingSpacing.lg),
          ],

          // Cancel pending warning
          if (isCancelPending && isActive) ...[
            _buildCancelPendingWarning(subscription!),
            const SizedBox(height: KolabingSpacing.lg),
          ],

          // Action buttons
          _buildActions(
            subscription,
            isActive,
            isPastDue,
            isCancelPending,
            iapState,
          ),

          const SizedBox(height: KolabingSpacing.xxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status Card
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard(
    Subscription? subscription,
    bool isActive,
    bool isPastDue,
    bool isCancelPending,
  ) {
    final l10n = AppLocalizations.of(context);
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    String title;
    String subtitle;

    if (isActive && !isCancelPending) {
      icon = LucideIcons.crown;
      iconColor = KolabingColors.primary;
      iconBgColor = KolabingColors.softYellow;
      title = l10n.subscriptionStatusPremiumTitle;
      subtitle = l10n.subscriptionStatusActiveSubtitle;
    } else if (isActive && isCancelPending) {
      icon = LucideIcons.clock;
      iconColor = KolabingColors.warning;
      iconBgColor = KolabingColors.warning.withValues(alpha: 0.1);
      title = l10n.subscriptionStatusEndingTitle;
      subtitle = l10n.subscriptionStatusEndingSubtitle;
    } else if (isPastDue) {
      icon = LucideIcons.alertTriangle;
      iconColor = KolabingColors.error;
      iconBgColor = KolabingColors.errorBg;
      title = l10n.subscriptionStatusPastDueTitle;
      subtitle = l10n.subscriptionStatusPastDueSubtitle;
    } else {
      icon = LucideIcons.sparkles;
      iconColor = KolabingColors.textTertiary;
      iconBgColor = KolabingColors.surfaceVariant;
      title = l10n.subscriptionStatusNoPlanTitle;
      subtitle = l10n.subscriptionStatusNoPlanSubtitle;
    }

    return Container(
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
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 36),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            title,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            subtitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benefits Section (shown when no active subscription)
  // ---------------------------------------------------------------------------

  Widget _buildBenefitsSection(IAPState? iapState) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionBenefitsTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),
        _BenefitItem(
          icon: LucideIcons.megaphone,
          title: l10n.subscriptionBenefitPublishTitle,
          description: l10n.subscriptionBenefitPublishDesc,
        ),
        _BenefitItem(
          icon: LucideIcons.users,
          title: l10n.subscriptionBenefitConnectTitle,
          description: l10n.subscriptionBenefitConnectDesc,
        ),
        _BenefitItem(
          icon: LucideIcons.inbox,
          title: l10n.subscriptionBenefitApplicationsTitle,
          description: l10n.subscriptionBenefitApplicationsDesc,
        ),
        _BenefitItem(
          icon: LucideIcons.barChart2,
          title: l10n.subscriptionBenefitTrackTitle,
          description: l10n.subscriptionBenefitTrackDesc,
        ),
        const SizedBox(height: KolabingSpacing.md),
        const Divider(height: 1, color: KolabingColors.darkBorder),
        const SizedBox(height: KolabingSpacing.md),
        Center(
          child: Platform.isIOS
              ? _buildApplePriceLabel(iapState)
              : RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '29 ',
                        style: KolabingTextStyles.displaySmall.copyWith(
                          color: KolabingColors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: l10n.subscriptionPerMonthUnit,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
  }

  // ---------------------------------------------------------------------------
  // Plan Details (shown when active)
  // ---------------------------------------------------------------------------

  Widget _buildPlanDetails(Subscription subscription) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionPlanDetailsTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),
        _DetailRow(
          label: l10n.subscriptionDetailPlanLabel,
          value: l10n.subscriptionStatusPremiumTitle,
          icon: LucideIcons.crown,
        ),
        _DetailRow(
          label: l10n.subscriptionDetailPriceLabel,
          value: l10n.subscriptionPriceMonthly,
          icon: LucideIcons.creditCard,
        ),
        if (subscription.currentPeriodStart != null)
          _DetailRow(
            label: l10n.subscriptionDetailCurrentPeriodLabel,
            value: _formatDate(subscription.currentPeriodStart!),
            icon: LucideIcons.calendarCheck,
          ),
        if (subscription.currentPeriodEnd != null)
          _DetailRow(
            label: l10n.subscriptionDetailRenewsOnLabel,
            value: _formatDate(subscription.currentPeriodEnd!),
            icon: LucideIcons.calendarClock,
          ),
        if (subscription.daysRemaining != null)
          _DetailRow(
            label: l10n.subscriptionDetailDaysRemainingLabel,
            value: l10n.subscriptionDaysValue(subscription.daysRemaining!),
            icon: LucideIcons.clock,
          ),
      ],
    ),
  );
  }

  // ---------------------------------------------------------------------------
  // Warning Banners
  // ---------------------------------------------------------------------------

  Widget _buildPastDueWarning() {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: KolabingColors.errorBg,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: KolabingColors.error.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.alertTriangle,
          color: KolabingColors.error,
          size: 24,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.subscriptionStatusPastDueTitle,
                style: KolabingTextStyles.titleSmall.copyWith(
                  color: KolabingColors.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.subscriptionPastDueWarningBody,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildCancelPendingWarning(Subscription subscription) {
    final l10n = AppLocalizations.of(context);
    final endDate = subscription.currentPeriodEnd != null
        ? _formatDate(subscription.currentPeriodEnd!)
        : l10n.subscriptionEndOfBillingPeriod;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.warning.withValues(alpha: 0.1),
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: KolabingColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: KolabingColors.warning, size: 24),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.subscriptionCancelPendingTitle,
                  style: KolabingTextStyles.titleSmall.copyWith(
                    color: KolabingColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.subscriptionCancelPendingBody(endDate),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Buttons
  // ---------------------------------------------------------------------------

  Widget _buildActions(
    Subscription? subscription,
    bool isActive,
    bool isPastDue,
    bool isCancelPending,
    IAPState? iapState,
  ) {
    final l10n = AppLocalizations.of(context);
    final canStartApplePurchase =
        !Platform.isIOS || (iapState?.canPurchase ?? false);
    final isSubscribeBusy =
        _isSubscribing ||
        (Platform.isIOS &&
            ((iapState?.isPurchasing ?? false) ||
                (iapState?.isRestoring ?? false)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Reactivate button (active but scheduled to cancel)
        if (isCancelPending) ...[
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isReactivating ? null : _handleReactivate,
              icon: _isReactivating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KolabingColors.onPrimary,
                      ),
                    )
                  : const Icon(LucideIcons.rotateCcw, size: 20),
              label: Text(
                l10n.subscriptionReactivateButton,
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // Subscribe button (no active subscription)
        if (!isActive) ...[
          ReferralCodeField(
            controller: _referralCodeController,
            enabled: !isSubscribeBusy,
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
          const SizedBox(height: KolabingSpacing.md),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canStartApplePurchase && !isSubscribeBusy
                  ? _handleSubscribe
                  : null,
              icon: isSubscribeBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KolabingColors.onPrimary,
                      ),
                    )
                  : const Icon(LucideIcons.sparkles, size: 20),
              label: Text(
                Platform.isIOS
                    ? l10n.subscriptionSubscribeButton
                    : l10n.subscriptionSubscribePricedButton,
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (Platform.isIOS &&
              (iapState?.purchaseAvailabilityMessage != null)) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              iapState!.purchaseAvailabilityMessage!,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: iapState.isLoadingProducts
                    ? KolabingColors.textTertiary
                    : KolabingColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],

        // Update Payment Method (past due)
        if (isPastDue) ...[
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleManageBilling,
              icon: const Icon(LucideIcons.creditCard, size: 20),
              label: Text(
                l10n.subscriptionUpdatePaymentButton,
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.onSurface,
                side: const BorderSide(color: KolabingColors.darkBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // Manage Billing (active, not cancelling)
        if (isActive && !isCancelPending) ...[
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleManageBilling,
              icon: const Icon(LucideIcons.settings, size: 20),
              label: Text(
                l10n.subscriptionManageBillingButton,
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.onSurface,
                side: const BorderSide(color: KolabingColors.darkBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),

          // Cancel button
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _isCancelling ? null : _handleCancel,
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.subscriptionCancelButton,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: KolabingColors.error,
                        decoration: TextDecoration.underline,
                        decorationColor: KolabingColors.error,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApplePriceLabel(IAPState? iapState) {
    final l10n = AppLocalizations.of(context);
    final state = iapState ?? const IAPState();

    if (state.monthlyProduct == null) {
      return Text(
        state.isLoadingProducts
            ? l10n.subscriptionLoadingApplePrice
            : l10n.subscriptionUnavailable,
        style: KolabingTextStyles.titleMedium.copyWith(
          color: KolabingColors.onSurface,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Text(
      l10n.subscriptionPricePerMonth(state.priceString),
      style: KolabingTextStyles.displaySmall.copyWith(
        color: KolabingColors.onSurface,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// -----------------------------------------------------------------------------
// Benefit Item
// -----------------------------------------------------------------------------

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.md),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: KolabingColors.primary.withValues(alpha: 0.1),
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
          child: Icon(icon, color: KolabingColors.primary, size: 20),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KolabingTextStyles.titleSmall.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              Text(
                description,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// -----------------------------------------------------------------------------
// Detail Row
// -----------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
    child: Row(
      children: [
        Icon(icon, size: 18, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
