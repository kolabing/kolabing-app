import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../business/providers/profile_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../enums/intent_type.dart';
import '../providers/kolab_form_provider.dart';

/// Unified entry screen for creating a new Kolab.
/// Shows different options based on user type (community vs business).
class IntentSelectionScreen extends ConsumerWidget {
  const IntentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final userType = profileState.profile?.userType;
    final isCommunity = userType?.name == 'community';

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: KolabingColors.textPrimary),
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
        child: Padding(
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
                    ref.read(kolabFormProvider.notifier).selectIntent(IntentType.communitySeeking);
                    context.push('/kolab/flow');
                  },
                ),
                const SizedBox(height: KolabingSpacing.md),
                _IntentOption(
                  icon: LucideIcons.megaphone,
                  title: 'Promote a Venue, Product or Service',
                  subtitle: 'Act as a business within your community account',
                  badge: 'SUBSCRIPTION REQUIRED',
                  badgeColor: KolabingColors.primary,
                  onTap: () => _handleCommunityPromote(context, ref),
                ),
              ] else ...[
                _IntentOption(
                  icon: LucideIcons.building2,
                  title: 'Promote my Venue',
                  subtitle: 'Get communities to host events at your location',
                  onTap: () {
                    ref.read(kolabFormProvider.notifier).selectIntent(IntentType.venuePromotion);
                    context.push('/kolab/flow');
                  },
                ),
                const SizedBox(height: KolabingSpacing.md),
                _IntentOption(
                  icon: LucideIcons.package,
                  title: 'Promote a Product or Service',
                  subtitle: 'Get communities to feature your products at their events',
                  onTap: () {
                    ref.read(kolabFormProvider.notifier).selectIntent(IntentType.productPromotion);
                    context.push('/kolab/flow');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleCommunityPromote(BuildContext context, WidgetRef ref) async {
    final profileState = ref.read(profileProvider);
    final isSubscribed = profileState.isSubscribed;

    if (isSubscribed) {
      // Show venue/product choice
      _showPromotionTypeChoice(context, ref);
    } else {
      // Show paywall
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SubscriptionPaywall(),
      );
      if (result == true && context.mounted) {
        // Refresh subscription status
        await ref.read(profileProvider.notifier).refreshSubscription();
        final updated = ref.read(profileProvider);
        if (updated.isSubscribed) {
          if (context.mounted) _showPromotionTypeChoice(context, ref);
        }
      }
    }
  }

  void _showPromotionTypeChoice(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              'What would you like to promote?',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            _IntentOption(
              icon: LucideIcons.building2,
              title: 'A Venue',
              subtitle: 'Get communities to host events at your location',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(kolabFormProvider.notifier).selectIntent(IntentType.venuePromotion);
                context.push('/kolab/flow');
              },
            ),
            const SizedBox(height: KolabingSpacing.md),
            _IntentOption(
              icon: LucideIcons.package,
              title: 'A Product or Service',
              subtitle: 'Get communities to feature your products at their events',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(kolabFormProvider.notifier).selectIntent(IntentType.productPromotion);
                context.push('/kolab/flow');
              },
            ),
            const SizedBox(height: KolabingSpacing.lg),
          ],
        ),
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
  Widget build(BuildContext context) {
    return GestureDetector(
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
                        color: (badgeColor ?? KolabingColors.primary).withValues(alpha: 0.2),
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
            Icon(
              LucideIcons.chevronRight,
              color: KolabingColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
