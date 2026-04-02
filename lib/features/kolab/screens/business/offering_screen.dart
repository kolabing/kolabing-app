import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../enums/intent_type.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 2 (venue / product flows): "WHAT YOU'RE OFFERING"
///
/// Toggle cards for each offering type. "Venue" is auto-selected and locked
/// when the intent is venuePromotion.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class OfferingScreen extends ConsumerWidget {
  const OfferingScreen({super.key});

  static const List<_OfferingOption> _options = [
    _OfferingOption(
      value: 'venue',
      title: 'Venue',
      subtitle: 'Provide your space for the collaboration',
      icon: LucideIcons.building2,
    ),
    _OfferingOption(
      value: 'food_drink',
      title: 'Food & Drink included',
      subtitle: 'Meals or beverages for community members',
      icon: LucideIcons.utensils,
    ),
    _OfferingOption(
      value: 'discount',
      title: 'Discount for community members',
      subtitle: 'Exclusive pricing for participants',
      icon: LucideIcons.percent,
    ),
    _OfferingOption(
      value: 'products',
      title: 'Products / Samples',
      subtitle: 'Free product samples or giveaways',
      icon: LucideIcons.gift,
    ),
    _OfferingOption(
      value: 'social_media',
      title: 'Social Media Exposure',
      subtitle: 'Feature on your channels',
      icon: LucideIcons.share2,
    ),
    _OfferingOption(
      value: 'content_creation',
      title: 'Content Creation',
      subtitle: 'Professional photos/video',
      icon: LucideIcons.camera,
    ),
    _OfferingOption(
      value: 'sponsorship',
      title: 'Sponsorship budget',
      subtitle: 'Financial support for the collaboration',
      icon: LucideIcons.banknote,
    ),
    _OfferingOption(
      value: 'other',
      title: 'Other',
      subtitle: 'Something else to offer',
      icon: LucideIcons.moreHorizontal,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    final isVenueFlow = formState.intentType == IntentType.venuePromotion;
    final offerings = kolab.offering;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          "WHAT YOU'RE OFFERING",
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          'Select all that apply',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Error
        if (errors.containsKey('offering'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['offering']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),

        // -- Toggle cards
        ..._options.map((option) {
          final isSelected = offerings.contains(option.value);
          final isVenueLocked = isVenueFlow && option.value == 'venue';

          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: _ToggleCard(
              title: option.title,
              subtitle: option.subtitle,
              icon: option.icon,
              isSelected: isVenueLocked || isSelected,
              isLocked: isVenueLocked,
              onTap: isVenueLocked
                  ? null
                  : () => notifier.toggleOffering(option.value),
            ),
          );
        }),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

// =============================================================================
// Data class for offering options
// =============================================================================

class _OfferingOption {
  const _OfferingOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

// =============================================================================
// Toggle Card
// =============================================================================

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isLocked = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? KolabingColors.softYellow
              : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? KolabingColors.primary
                : KolabingColors.border,
          ),
        ),
        child: Row(
          children: [
            // Checkbox / Locked indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? KolabingColors.primary
                    : Colors.transparent,
                borderRadius: KolabingRadius.borderRadiusXs,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      isLocked ? LucideIcons.lock : LucideIcons.check,
                      size: 14,
                      color: KolabingColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Icon
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? KolabingColors.textPrimary
                  : KolabingColors.textSecondary,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
