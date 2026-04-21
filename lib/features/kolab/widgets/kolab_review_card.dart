import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';

/// Review card that displays a summary of the Kolab before publishing.
///
/// Sections are rendered dynamically based on [Kolab.intentType]. Each section
/// is tappable, calling [onEditSection] with the corresponding step index so
/// the user can jump back and edit.
class KolabReviewCard extends ConsumerWidget {
  const KolabReviewCard({
    required this.kolab,
    required this.onEditSection,
    super.key,
  });

  /// The Kolab to review.
  final Kolab kolab;

  /// Called when a section is tapped, with the step index to navigate to.
  final void Function(int step) onEditSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DecoratedBox(
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusLg,
          border: Border.all(color: KolabingColors.border),
        ),
        child: Column(
          children: _buildSections(),
        ),
      );

  // ---------------------------------------------------------------------------
  // Section dispatcher based on intent type
  // ---------------------------------------------------------------------------

  List<Widget> _buildSections() {
    switch (kolab.intentType) {
      case IntentType.communitySeeking:
        return _buildCommunitySeekingSections();
      case IntentType.venuePromotion:
        return _buildVenuePromotionSections();
      case IntentType.productPromotion:
        return _buildProductPromotionSections();
    }
  }

  // ---------------------------------------------------------------------------
  // Community Seeking sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildCommunitySeekingSections() => [
        // Step 0 -- Title & Description
        _ReviewSection(
          icon: LucideIcons.fileText,
          title: 'Title & Description',
          step: 0,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'Title',
                value: kolab.title.isNotEmpty ? kolab.title : '--',
              ),
              const SizedBox(height: KolabingSpacing.xs),
              _ReviewField(
                label: 'Description',
                value:
                    kolab.description.isNotEmpty ? kolab.description : '--',
              ),
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 1 -- Needs
        _ReviewSection(
          icon: LucideIcons.heart,
          title: 'What You Need',
          step: 1,
          onEdit: onEditSection,
          child: kolab.needs.isNotEmpty
              ? _ChipList(
                  items: kolab.needs.map((n) => n.displayName).toList(),
                )
              : const _EmptyHint(text: 'No needs selected'),
        ),
        const _SectionDivider(),
        // Step 2 -- Community Info
        _ReviewSection(
          icon: LucideIcons.users,
          title: 'Community Info',
          step: 2,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kolab.communityTypes.isNotEmpty)
                _ReviewField(
                  label: 'Types',
                  value: kolab.communityTypes.join(', '),
                ),
              if (kolab.communitySize != null) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Community Size',
                  value: '${kolab.communitySize}',
                ),
              ],
              if (kolab.typicalAttendance != null) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Typical Attendance',
                  value: '${kolab.typicalAttendance}',
                ),
              ],
              if (kolab.communityTypes.isEmpty &&
                  kolab.communitySize == null &&
                  kolab.typicalAttendance == null)
                const _EmptyHint(text: 'No community info provided'),
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 3 -- Offers in Return
        _ReviewSection(
          icon: LucideIcons.gift,
          title: 'Offers in Return',
          step: 3,
          onEdit: onEditSection,
          child: kolab.offersInReturn.isNotEmpty
              ? _ChipList(
                  items: kolab.offersInReturn
                      .map((o) => o.displayName)
                      .toList(),
                )
              : const _EmptyHint(text: 'No offers selected'),
        ),
        const _SectionDivider(),
        // Step 4 -- Location
        _ReviewSection(
          icon: LucideIcons.mapPin,
          title: 'Location',
          step: 4,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'City',
                value: kolab.preferredCity.isNotEmpty
                    ? kolab.preferredCity
                    : '--',
              ),
              if (kolab.area != null && kolab.area!.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(label: 'Area', value: kolab.area!),
              ],
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 5 -- Availability
        _buildAvailabilitySection(5),
      ];

  // ---------------------------------------------------------------------------
  // Venue Promotion sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildVenuePromotionSections() => [
        // Step 0 -- Campaign & Venue
        _ReviewSection(
          icon: LucideIcons.building2,
          title: 'Campaign & Venue',
          step: 0,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'Title',
                value: kolab.title.isNotEmpty ? kolab.title : '--',
              ),
              const SizedBox(height: KolabingSpacing.xs),
              _ReviewField(
                label: 'Description',
                value: kolab.description.isNotEmpty ? kolab.description : '--',
              ),
              const SizedBox(height: KolabingSpacing.xs),
              _ReviewField(
                label: 'Venue',
                value: kolab.venueName ?? '--',
              ),
              if (kolab.venueType != null) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Type',
                  value: kolab.venueType!.displayName,
                ),
              ],
              if (kolab.capacity != null) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Capacity',
                  value: '${kolab.capacity}',
                ),
              ],
              if (kolab.venueAddress != null &&
                  kolab.venueAddress!.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Address',
                  value: kolab.venueAddress!,
                ),
              ],
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 1 -- Media
        _ReviewSection(
          icon: LucideIcons.image,
          title: 'Media',
          step: 1,
          onEdit: onEditSection,
          child: _ReviewField(
            label: 'Photos / Videos',
            value: kolab.media.isNotEmpty
                ? '${kolab.media.length} item${kolab.media.length == 1 ? '' : 's'}'
                : 'No media added',
          ),
        ),
        const _SectionDivider(),
        // Step 2 -- Offering
        _ReviewSection(
          icon: LucideIcons.gift,
          title: 'What You Offer',
          step: 2,
          onEdit: onEditSection,
          child: kolab.offering.isNotEmpty
              ? _ChipList(items: kolab.offering)
              : const _EmptyHint(text: 'No offerings listed'),
        ),
        const _SectionDivider(),
        // Step 3 -- Seeking Communities
        _ReviewSection(
          icon: LucideIcons.users,
          title: 'Seeking Communities',
          step: 3,
          onEdit: onEditSection,
          child: kolab.seekingCommunities.isNotEmpty
              ? _ChipList(items: kolab.seekingCommunities)
              : const _EmptyHint(text: 'No communities selected'),
        ),
        const _SectionDivider(),
        // Step 4 -- Past Events
        _ReviewSection(
          icon: LucideIcons.calendar,
          title: 'Past Events',
          step: 4,
          onEdit: onEditSection,
          child: _ReviewField(
            label: 'Events',
            value: kolab.pastEvents.isNotEmpty
                ? '${kolab.pastEvents.length} event${kolab.pastEvents.length == 1 ? '' : 's'}'
                : 'No past events added',
          ),
        ),
        const _SectionDivider(),
        // Step 5 -- Location
        _ReviewSection(
          icon: LucideIcons.mapPin,
          title: 'Location',
          step: 5,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'City',
                value: kolab.preferredCity.isNotEmpty
                    ? kolab.preferredCity
                    : '--',
              ),
              if (kolab.venueAddress != null &&
                  kolab.venueAddress!.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(label: 'Address', value: kolab.venueAddress!),
              ],
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 6 -- Availability
        _buildAvailabilitySection(6),
      ];

  // ---------------------------------------------------------------------------
  // Product Promotion sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildProductPromotionSections() => [
        // Step 0 -- Product Info
        _ReviewSection(
          icon: LucideIcons.box,
          title: 'Product Info',
          step: 0,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'Name',
                value: kolab.productName ?? '--',
              ),
              if (kolab.productType != null) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(
                  label: 'Type',
                  value: kolab.productType!.displayName,
                ),
              ],
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 1 -- Media
        _ReviewSection(
          icon: LucideIcons.image,
          title: 'Media',
          step: 1,
          onEdit: onEditSection,
          child: _ReviewField(
            label: 'Photos / Videos',
            value: kolab.media.isNotEmpty
                ? '${kolab.media.length} item${kolab.media.length == 1 ? '' : 's'}'
                : 'No media added',
          ),
        ),
        const _SectionDivider(),
        // Step 2 -- Offering
        _ReviewSection(
          icon: LucideIcons.gift,
          title: 'What You Offer',
          step: 2,
          onEdit: onEditSection,
          child: kolab.offering.isNotEmpty
              ? _ChipList(items: kolab.offering)
              : const _EmptyHint(text: 'No offerings listed'),
        ),
        const _SectionDivider(),
        // Step 3 -- Seeking Communities
        _ReviewSection(
          icon: LucideIcons.users,
          title: 'Seeking Communities',
          step: 3,
          onEdit: onEditSection,
          child: kolab.seekingCommunities.isNotEmpty
              ? _ChipList(items: kolab.seekingCommunities)
              : const _EmptyHint(text: 'No communities selected'),
        ),
        const _SectionDivider(),
        // Step 4 -- Past Events
        _ReviewSection(
          icon: LucideIcons.calendar,
          title: 'Past Events',
          step: 4,
          onEdit: onEditSection,
          child: _ReviewField(
            label: 'Events',
            value: kolab.pastEvents.isNotEmpty
                ? '${kolab.pastEvents.length} event${kolab.pastEvents.length == 1 ? '' : 's'}'
                : 'No past events added',
          ),
        ),
        const _SectionDivider(),
        // Step 5 -- Location
        _ReviewSection(
          icon: LucideIcons.mapPin,
          title: 'Location',
          step: 5,
          onEdit: onEditSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewField(
                label: 'City',
                value: kolab.preferredCity.isNotEmpty
                    ? kolab.preferredCity
                    : '--',
              ),
              if (kolab.area != null && kolab.area!.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.xs),
                _ReviewField(label: 'Area', value: kolab.area!),
              ],
            ],
          ),
        ),
        const _SectionDivider(),
        // Step 6 -- Availability
        _buildAvailabilitySection(6),
      ];

  // ---------------------------------------------------------------------------
  // Shared availability section
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilitySection(int step) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    var availabilityText = '--';

    if (kolab.availabilityMode != null) {
      availabilityText = kolab.availabilityMode!.displayName;
      if (kolab.availabilityStart != null) {
        availabilityText +=
            '\nFrom: ${dateFormat.format(kolab.availabilityStart!)}';
      }
      if (kolab.availabilityEnd != null) {
        availabilityText +=
            '\nTo: ${dateFormat.format(kolab.availabilityEnd!)}';
      }
    }

    return _ReviewSection(
      icon: LucideIcons.clock,
      title: 'Availability',
      step: step,
      onEdit: onEditSection,
      child: _ReviewField(
        label: 'Schedule',
        value: availabilityText,
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

/// A single tappable section in the review card.
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.step,
    required this.onEdit,
    required this.child,
  });

  final IconData icon;
  final String title;
  final int step;
  final void Function(int) onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onEdit(step),
        borderRadius: KolabingRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: KolabingColors.textSecondary,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: KolabingColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.sm),
              child,
            ],
          ),
        ),
      );
}

/// Horizontal divider between review sections.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: KolabingColors.border,
      );
}

/// A labelled field in a review section.
class _ReviewField extends StatelessWidget {
  const _ReviewField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textPrimary,
            ),
          ),
        ],
      );
}

/// Row of small chips for displaying lists of items.
class _ChipList extends StatelessWidget {
  const _ChipList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: KolabingSpacing.xxs,
        runSpacing: KolabingSpacing.xxs,
        children: items
            .map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.xs,
                  vertical: KolabingSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: KolabingColors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusXs,
                ),
                child: Text(
                  item,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      );
}

/// Placeholder text for empty sections.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: KolabingColors.textTertiary,
        ),
      );
}
