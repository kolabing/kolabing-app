import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
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

    return result == true;
  }

  @override
  ConsumerState<SubscriptionPaywall> createState() =>
      _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends ConsumerState<SubscriptionPaywall> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    if (Platform.isIOS) {
      await _handleAppleSubscribe();
    } else {
      await _handleStripeSubscribe();
    }
  }

  /// iOS: Use Apple IAP
  Future<void> _handleAppleSubscribe() async {
    final iapNotifier = ref.read(iapProvider.notifier);
    await iapNotifier.purchase();
    // Purchase result handled by listener in build method
  }

  /// Android/Other: Use Stripe (existing flow)
  Future<void> _handleStripeSubscribe() async {
    setState(() => _isLoading = true);

    final url = await ref.read(profileProvider.notifier).getCheckoutUrl();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await ref.read(profileProvider.notifier).refreshSubscription();
        final subscription = ref.read(profileProvider).subscription;
        if (mounted) {
          Navigator.of(context).pop(subscription?.isActive ?? false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always watch/listen unconditionally (Riverpod hooks must be stable)
    final iapState = ref.watch(iapProvider);

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

    // Use IAP loading state on iOS
    if (Platform.isIOS && (iapState.isPurchasing || iapState.isRestoring)) {
      _isLoading = true;
    }

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
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
                decoration: BoxDecoration(
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
                'You\'ve used your 1 free kollab request. Subscribe to create unlimited requests and connect with more communities.',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Benefits
              _buildBenefitRow(
                LucideIcons.infinity,
                'Publish unlimited kollab requests',
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
                    Text(
                      Platform.isIOS
                          ? ref.watch(iapProvider).priceString
                          : '29 EUR',
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
                  ],
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
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
                  onPressed: _isLoading
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

              // IAP error message
              if (Platform.isIOS) ...[
                Builder(builder: (context) {
                  final iapError = ref.watch(iapProvider).error;
                  if (iapError == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: KolabingSpacing.xs),
                    child: Text(
                      iapError,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
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
