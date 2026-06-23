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
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/referral_code_field.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../providers/iap_provider.dart';
import '../services/iap_service.dart';

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
    // BUSINESS-ONLY gate (golden rule: communities & attendees are NEVER
    // paywalled). No-op/allow for any non-business viewer so an accidental call
    // from a community/attendee path can never block them or demand premium.
    final userType = ref.read(authProvider).user?.userType;
    if (userType != UserType.business) return true;

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
  // 3-month plan is preselected (best value).
  SubscriptionPlan _selectedPlan = SubscriptionPlan.threeMonths;
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
    // Fall back to monthly if the selected plan's product didn't load.
    final iapState = ref.read(iapProvider);
    final plan = iapState.productFor(_selectedPlan) != null
        ? _selectedPlan
        : SubscriptionPlan.monthly;
    try {
      final result = await iapNotifier.purchase(
        plan: plan,
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).subscriptionPaywallAppleError,
          ),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).subscriptionPaywallCheckoutError,
          ),
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
                  color: KolabingColors.darkBorder,
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
                l10n.subscriptionPaywallTitle,
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                l10n.subscriptionPaywallDescription,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.onSurfaceVariant,
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

              // Plan picker (iOS: selectable cards; other: single monthly box)
              _buildPlanPicker(l10n, iapState),
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
              KolabingButton(
                label: l10n.subscriptionPaywallSubscribeButton,
                onPressed: isLoading || !canStartApplePurchase
                    ? null
                    : _handleSubscribe,
                variant: KolabingButtonVariant.primary,
                isLoading: isLoading,
                isDisabled: !canStartApplePurchase,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Not now button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.subscriptionPaywallNotNowButton,
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
                    l10n.subscriptionRestorePurchasesButton,
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

  /// Builds the plan picker. On iOS, renders selectable plan cards when the
  /// store products are loaded; otherwise (Android/Stripe) a single monthly box.
  Widget _buildPlanPicker(AppLocalizations l10n, IAPState iapState) {
    if (!Platform.isIOS) {
      return _buildSinglePriceBox(
        price: '€39.99',
        suffix: l10n.subscriptionPaywallPerMonth,
      );
    }

    final monthly = iapState.monthlyProduct;
    final threeMonths = iapState.threeMonthsProduct;

    // Nothing loaded yet — loading / unavailable message.
    if (monthly == null && threeMonths == null) {
      return _buildSinglePriceBox(
        message: iapState.isLoadingProducts
            ? l10n.subscriptionLoadingApplePrice
            : l10n.subscriptionUnavailable,
      );
    }

    // EUR-forced prices (Kolabing is euro-priced; never show the storefront's $).
    final monthlyPrice =
        iapState.eurPriceFor(SubscriptionPlan.monthly) ?? '€39.99';
    final threeMonthsPrice =
        iapState.eurPriceFor(SubscriptionPlan.threeMonths) ?? '€99.99';

    // Only one plan available — single box, no choice to make.
    if (threeMonths == null) {
      return _buildSinglePriceBox(
        price: monthlyPrice,
        suffix: l10n.subscriptionPaywallPerMonth,
      );
    }
    if (monthly == null) {
      return _buildSinglePriceBox(
        price: threeMonthsPrice,
        suffix: l10n.subscriptionPlanPer3Months,
      );
    }

    return Column(
      children: [
        _buildPlanCard(
          l10n: l10n,
          plan: SubscriptionPlan.threeMonths,
          label: l10n.subscriptionPlanThreeMonthsLabel,
          price: threeMonthsPrice,
          suffix: l10n.subscriptionPlanPer3Months,
          perMonthEq: iapState.perMonthEquivalent(SubscriptionPlan.threeMonths),
          savingsPercent: iapState.savingsPercent(SubscriptionPlan.threeMonths),
          badge: l10n.subscriptionPlanBestValueBadge,
          selected: _selectedPlan == SubscriptionPlan.threeMonths,
        ),
        const SizedBox(height: KolabingSpacing.sm),
        _buildPlanCard(
          l10n: l10n,
          plan: SubscriptionPlan.monthly,
          label: l10n.subscriptionPlanMonthlyLabel,
          price: monthlyPrice,
          suffix: l10n.subscriptionPaywallPerMonth,
          selected: _selectedPlan == SubscriptionPlan.monthly,
        ),
      ],
    );
  }

  /// Single non-selectable price box (Android, single-product, or status text).
  Widget _buildSinglePriceBox({
    String? price,
    String? suffix,
    String? message,
  }) => Container(
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
        if (price != null) ...[
          Text(
            price,
            style: KolabingTextStyles.headlineLarge.copyWith(
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            suffix ?? '',
            style: KolabingTextStyles.bodyLarge.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ] else
          Text(
            message ?? '',
            style: KolabingTextStyles.titleMedium.copyWith(
              color: KolabingColors.onSurface,
            ),
          ),
      ],
    ),
  );

  /// A selectable plan card.
  Widget _buildPlanCard({
    required AppLocalizations l10n,
    required SubscriptionPlan plan,
    required String label,
    required String price,
    required String suffix,
    required bool selected,
    String? perMonthEq,
    int? savingsPercent,
    String? badge,
  }) => GestureDetector(
    onTap: () => setState(() => _selectedPlan = plan),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: selected ? KolabingColors.softYellow : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: selected
              ? KolabingColors.primary
              : KolabingColors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: selected
                ? KolabingColors.primary
                : KolabingColors.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: KolabingTextStyles.titleMedium.copyWith(
                          color: KolabingColors.onSurface,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: KolabingSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KolabingColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: KolabingColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (perMonthEq != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.subscriptionPlanPerMonthEq(perMonthEq),
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: KolabingTextStyles.titleLarge.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              Text(
                suffix,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              if (savingsPercent != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.subscriptionPlanSavePercent(savingsPercent),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

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
              color: KolabingColors.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
