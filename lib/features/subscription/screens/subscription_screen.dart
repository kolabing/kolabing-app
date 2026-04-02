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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).refreshSubscription();
    });
  }

  Future<void> _handleSubscribe() async {
    if (Platform.isIOS) {
      // iOS: Use Apple IAP
      await ref.read(iapProvider.notifier).purchase();
    } else {
      // Android: Use Stripe
      final url = await ref.read(profileProvider.notifier).getCheckoutUrl();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (mounted) {
          await Future<void>.delayed(const Duration(seconds: 2));
          ref.read(profileProvider.notifier).refreshSubscription();
        }
      }
    }
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
      final url = await ref.read(profileProvider.notifier).getBillingPortalUrl();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (mounted) {
          await Future<void>.delayed(const Duration(seconds: 2));
          ref.read(profileProvider.notifier).refreshSubscription();
        }
      }
    }
  }

  Future<void> _handleReactivate() async {
    setState(() => _isReactivating = true);
    final success = await ref.read(profileProvider.notifier).reactivateSubscription();
    if (mounted) {
      setState(() => _isReactivating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription reactivated successfully'),
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
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will remain active until the end of the current billing period. You can resubscribe at any time.\n\nAre you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      final success =
          await ref.read(profileProvider.notifier).cancelSubscription();
      if (mounted) {
        setState(() => _isCancelling = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Subscription will cancel at the end of billing period'),
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

    ref.listen<ProfileState>(profileProvider, (previous, next) {
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
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textPrimary,
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
        child: state.isLoading && !state.isInitialized
            ? _buildLoadingState()
            : _buildContent(state.subscription, state.isSubscribed),
      ),
    );
  }

  Widget _buildLoadingState() => SingleChildScrollView(
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

  Widget _buildContent(Subscription? subscription, bool isSubscribed) {
    final isActive = isSubscribed;
    final isPastDue = subscription?.status == SubscriptionStatus.pastDue;
    final isCancelPending = subscription?.cancelAtPeriodEnd ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          _buildStatusCard(subscription, isActive, isPastDue, isCancelPending),
          const SizedBox(height: KolabingSpacing.lg),

          // Benefits section
          if (!isActive) ...[
            _buildBenefitsSection(),
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
          _buildActions(subscription, isActive, isPastDue, isCancelPending),

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
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    String title;
    String subtitle;

    if (isActive && !isCancelPending) {
      icon = LucideIcons.crown;
      iconColor = KolabingColors.primary;
      iconBgColor = KolabingColors.softYellow;
      title = 'Premium Business';
      subtitle = 'Your subscription is active';
    } else if (isActive && isCancelPending) {
      icon = LucideIcons.clock;
      iconColor = KolabingColors.warning;
      iconBgColor = KolabingColors.warning.withValues(alpha: 0.1);
      title = 'Subscription Ending';
      subtitle = 'Active until end of billing period';
    } else if (isPastDue) {
      icon = LucideIcons.alertTriangle;
      iconColor = KolabingColors.error;
      iconBgColor = KolabingColors.errorBg;
      title = 'Payment Failed';
      subtitle = 'Please update your payment method';
    } else {
      icon = LucideIcons.sparkles;
      iconColor = KolabingColors.textTertiary;
      iconBgColor = KolabingColors.surfaceVariant;
      title = 'No Active Plan';
      subtitle = 'Subscribe to publish opportunities';
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
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            subtitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Benefits Section (shown when no active subscription)
  // ---------------------------------------------------------------------------

  Widget _buildBenefitsSection() => Container(
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
              'Premium Benefits',
              style: KolabingTextStyles.titleMedium.copyWith(
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            _BenefitItem(
              icon: LucideIcons.megaphone,
              title: 'Publish Opportunities',
              description: 'Create and publish collaboration offers',
            ),
            _BenefitItem(
              icon: LucideIcons.users,
              title: 'Connect with Communities',
              description: 'Reach local communities and creators',
            ),
            _BenefitItem(
              icon: LucideIcons.inbox,
              title: 'Receive Applications',
              description: 'Get applications from interested communities',
            ),
            _BenefitItem(
              icon: LucideIcons.barChart2,
              title: 'Track Performance',
              description: 'Monitor your collaboration metrics',
            ),
            const SizedBox(height: KolabingSpacing.md),
            const Divider(height: 1, color: KolabingColors.border),
            const SizedBox(height: KolabingSpacing.md),
            Center(
              child: Platform.isIOS
                  ? Consumer(
                      builder: (context, ref, _) {
                        final price = ref.watch(iapProvider).priceString;
                        return Text(
                          '$price/month',
                          style: KolabingTextStyles.displaySmall.copyWith(
                            color: KolabingColors.textPrimary,
                          ),
                        );
                      },
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '29 ',
                            style: KolabingTextStyles.displaySmall.copyWith(
                              color: KolabingColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'EUR/month',
                            style: KolabingTextStyles.bodyLarge.copyWith(
                              color: KolabingColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Plan Details (shown when active)
  // ---------------------------------------------------------------------------

  Widget _buildPlanDetails(Subscription subscription) => Container(
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
              'Plan Details',
              style: KolabingTextStyles.titleMedium.copyWith(
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            _DetailRow(
              label: 'Plan',
              value: 'Premium Business',
              icon: LucideIcons.crown,
            ),
            _DetailRow(
              label: 'Price',
              value: '29 EUR/month',
              icon: LucideIcons.creditCard,
            ),
            if (subscription.currentPeriodStart != null)
              _DetailRow(
                label: 'Current Period',
                value: _formatDate(subscription.currentPeriodStart!),
                icon: LucideIcons.calendarCheck,
              ),
            if (subscription.currentPeriodEnd != null)
              _DetailRow(
                label: 'Renews On',
                value: _formatDate(subscription.currentPeriodEnd!),
                icon: LucideIcons.calendarClock,
              ),
            if (subscription.daysRemaining != null)
              _DetailRow(
                label: 'Days Remaining',
                value: '${subscription.daysRemaining} days',
                icon: LucideIcons.clock,
              ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Warning Banners
  // ---------------------------------------------------------------------------

  Widget _buildPastDueWarning() => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.errorBg,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: KolabingColors.error.withValues(alpha: 0.3),
          ),
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
                    'Payment Failed',
                    style: KolabingTextStyles.titleSmall.copyWith(
                      color: KolabingColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your last payment failed. Update your payment method to continue publishing opportunities.',
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

  Widget _buildCancelPendingWarning(Subscription subscription) {
    final endDate = subscription.currentPeriodEnd != null
        ? _formatDate(subscription.currentPeriodEnd!)
        : 'end of billing period';

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
          const Icon(
            LucideIcons.info,
            color: KolabingColors.warning,
            size: 24,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation Scheduled',
                  style: KolabingTextStyles.titleSmall.copyWith(
                    color: KolabingColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your subscription is active until $endDate. After that, you will not be able to publish new opportunities.',
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
  ) {
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
                'REACTIVATE SUBSCRIPTION',
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
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _handleSubscribe,
              icon: const Icon(LucideIcons.sparkles, size: 20),
              label: Text(
                Platform.isIOS ? 'SUBSCRIBE' : 'SUBSCRIBE FOR 29 EUR/MONTH',
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

        // Update Payment Method (past due)
        if (isPastDue) ...[
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _handleManageBilling,
              icon: const Icon(LucideIcons.creditCard, size: 20),
              label: Text(
                'UPDATE PAYMENT METHOD',
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
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
                'MANAGE BILLING',
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
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
                      'Cancel Subscription',
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textSecondary,
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
                  color: KolabingColors.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
