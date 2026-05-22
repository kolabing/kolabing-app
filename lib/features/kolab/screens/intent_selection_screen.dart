import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: KolabingColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'NEW KOLAB',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textPrimary,
          ),
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
                          ? 'What would you like to do?'
                          : 'What would you like to promote?',
                      style: GoogleFonts.rubik(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      isCommunity
                          ? 'Choose how you want to collaborate with businesses.'
                          : 'Choose what you want to promote to communities.',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: KolabingColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xl),
                    if (isCommunity) ...[
                      _IntentOption(
                        icon: LucideIcons.search,
                        title: 'Find a Venue or Sponsor',
                        subtitle: 'for my community event',
                        badge: 'FREE',
                        badgeColor: KolabingColors.success,
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
                        title: 'Promote my Venue',
                        subtitle:
                            'Get communities to host events at your location',
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
                        title: 'Promote a Product or Service',
                        subtitle:
                            'Get communities to feature your products at their events',
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
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 40,
                        color: KolabingColors.textSecondary,
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      Text(
                        profileState.error ?? 'Unable to load your profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        'Please try again to continue creating a kolab.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.lg),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(profileProvider.notifier).loadProfile();
                        },
                        child: const Text('Retry'),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KolabingSpacing.lg),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: KolabingColors.softYellow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.crown,
            size: 34,
            color: KolabingColors.primary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          'An active subscription is required to create Kolabs.',
          textAlign: TextAlign.center,
          style: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          'Upgrade your business plan to publish venue or product opportunities for communities.',
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            fontSize: 14,
            height: 1.5,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(LucideIcons.crown, size: 18),
            label: const Text('Upgrade to create'),
          ),
        ),
      ],
    ),
  );
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
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            child: Icon(icon, color: KolabingColors.textPrimary, size: 24),
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: KolabingColors.textSecondary,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: KolabingSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? KolabingColors.primary).withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.darkerGrotesque(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: KolabingColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
