import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/models/user_model.dart';
import '../../business/providers/profile_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../enums/intent_type.dart';
import '../providers/kolab_form_provider.dart';

/// Unified entry screen for creating a new Kolab.
/// Shows different options based on user type (community vs business).
class IntentSelectionScreen extends ConsumerStatefulWidget {
  const IntentSelectionScreen({super.key, this.recipientCommunityId});

  /// When set, the resulting Kolab is targeted at this specific community
  /// (Send-Kolab CTA from a community public profile, C9 follow-up).
  final String? recipientCommunityId;

  @override
  ConsumerState<IntentSelectionScreen> createState() =>
      _IntentSelectionScreenState();
}

class _IntentSelectionScreenState extends ConsumerState<IntentSelectionScreen> {
  @override
  void initState() {
    super.initState();
    final recipient = widget.recipientCommunityId;
    if (recipient != null && recipient.isNotEmpty) {
      // Stash on the form state immediately so downstream steps see it even
      // if the user backs out and re-enters the intent picker.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(kolabFormProvider.notifier).setRecipientCommunityId(recipient);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileState = ref.watch(profileProvider);
    final userType = profileState.profile?.userType;
    final isProfileTypeResolved = userType != null;
    final isProfileStillResolving =
        !isProfileTypeResolved &&
        (profileState.isLoading || !profileState.isInitialized);
    // Enum-safe role detection. Comparing the raw enum value (not its `.name`
    // string) avoids any casing mismatch: previously `userType?.name ==
    // 'community'` could silently fail if the parsed enum's name differed in
    // case, dropping a COMMUNITY into the business `else` branch and wrongly
    // gating it (ROLES-BACKEND-DB-MAP.md §3, "community blocked from creating").
    // UserType.fromString already normalizes API casing on parse.
    final isCommunity = userType == UserType.community;
    final isBusiness = userType == UserType.business;
    final businessRequiresSubscription =
        isBusiness && !profileState.isSubscribed;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: context.colors.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.intentSelectionAppBarTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isProfileStillResolving
            ? const Center(child: CircularProgressIndicator())
            : businessRequiresSubscription
            ? _LockedBusinessCreateState(
                onUpgrade: () async {
                  final allowed = await SubscriptionPaywall.checkAndShow(
                    context,
                    ref,
                  );
                  if (allowed) {
                    await ref
                        .read(profileProvider.notifier)
                        .refreshSubscription();
                  }
                },
              )
            : isProfileTypeResolved
            ? Padding(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: KolabingSpacing.lg),
                    Text(
                      isCommunity
                          ? l10n.intentSelectionCommunityTitle
                          : l10n.intentSelectionBusinessTitle,
                      style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: context.colors.onSurface),
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      isCommunity
                          ? l10n.intentSelectionCommunitySubtitle
                          : l10n.intentSelectionBusinessSubtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: KolabingSpacing.xl),
                    if (isCommunity) ...[
                      _IntentOption(
                        icon: LucideIcons.search,
                        title: l10n.intentSelectionFindVenueTitle,
                        subtitle: l10n.intentSelectionFindVenueSubtitle,
                        badge: l10n.intentSelectionBadgeFree,
                        badgeColor: context.colors.success,
                        onTap: () {
                          ref
                              .read(kolabFormProvider.notifier)
                              .selectIntent(IntentType.communitySeeking);
                          context.push('/kolab/flow');
                        },
                      ),
                    ] else ...[
                      _IntentOption(
                        icon: LucideIcons.building2,
                        title: l10n.intentSelectionPromoteVenueTitle,
                        subtitle: l10n.intentSelectionPromoteVenueSubtitle,
                        onTap: () {
                          ref
                              .read(kolabFormProvider.notifier)
                              .selectIntent(IntentType.venuePromotion);
                          context.push('/kolab/flow');
                        },
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      _IntentOption(
                        icon: LucideIcons.package,
                        title: l10n.intentSelectionPromoteProductTitle,
                        subtitle: l10n.intentSelectionPromoteProductSubtitle,
                        onTap: () {
                          ref
                              .read(kolabFormProvider.notifier)
                              .selectIntent(IntentType.productPromotion);
                          context.push('/kolab/flow');
                        },
                      ),
                    ],
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(KolabingSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 40,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      Text(
                        profileState.error ?? l10n.intentSelectionProfileLoadError,
                        textAlign: TextAlign.center,
                        style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        l10n.intentSelectionProfileLoadErrorHint,
                        textAlign: TextAlign.center,
                        style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: KolabingSpacing.lg),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(profileProvider.notifier).loadProfile();
                        },
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// A single intent option card
class _LockedBusinessCreateState extends StatelessWidget {
  const _LockedBusinessCreateState({required this.onUpgrade});

  final Future<void> Function() onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.crown,
              size: 34,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            l10n.intentSelectionLockedTitle,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: context.colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            l10n.intentSelectionLockedSubtitle,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: KolabingSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(LucideIcons.crown, size: 18),
              label: Text(l10n.intentSelectionUpgradeButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single intent option card
class _IntentOption extends StatelessWidget {
  const _IntentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            child: Icon(icon, color: context.colors.onSurface, size: 24),
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
                ),
                if (badge != null) ...[
                  const SizedBox(height: KolabingSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? context.colors.primary).withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    child: Text(
                      badge!,
                      style: KolabingTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: context.colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
