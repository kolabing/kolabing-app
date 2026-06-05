import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(children: _buildSections(l10n)),
    );
  }

  // ---------------------------------------------------------------------------
  // Section dispatcher based on intent type
  // ---------------------------------------------------------------------------

  List<Widget> _buildSections(AppLocalizations l10n) {
    switch (kolab.intentType) {
      case IntentType.communitySeeking:
        return _buildCommunitySeekingSections(l10n);
      case IntentType.venuePromotion:
        return _buildVenuePromotionSections(l10n);
      case IntentType.productPromotion:
        return _buildProductPromotionSections(l10n);
    }
  }

  // ---------------------------------------------------------------------------
  // Community Seeking sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildCommunitySeekingSections(AppLocalizations l10n) => [
    // Step 0 -- Title & Description
    _ReviewSection(
      icon: LucideIcons.fileText,
      title: l10n.kolabReviewSectionTitleDescription,
      step: 0,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldTitle,
            value: kolab.title.isNotEmpty ? kolab.title : '--',
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _ReviewField(
            label: l10n.kolabReviewFieldDescription,
            value: kolab.description.isNotEmpty ? kolab.description : '--',
          ),
        ],
      ),
    ),
    const _SectionDivider(),
    // Step 1 -- Needs
    _ReviewSection(
      icon: LucideIcons.heart,
      title: l10n.kolabReviewSectionWhatYouNeed,
      step: 1,
      onEdit: onEditSection,
      child: kolab.needs.isNotEmpty
          ? _ChipList(items: kolab.needs.map((n) => n.displayName).toList())
          : _EmptyHint(text: l10n.kolabReviewEmptyNeeds),
    ),
    const _SectionDivider(),
    // Step 2 -- Community Info
    _ReviewSection(
      icon: LucideIcons.users,
      title: l10n.kolabReviewSectionCommunityInfo,
      step: 2,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kolab.communityTypes.isNotEmpty)
            _ReviewField(
              label: l10n.kolabReviewFieldTypes,
              value: kolab.communityTypeLabels.join(', '),
            ),
          if (kolab.communitySize != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldCommunitySize,
              value: '${kolab.communitySize}',
            ),
          ],
          if (kolab.typicalAttendance != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldTypicalAttendance,
              value: '${kolab.typicalAttendance}',
            ),
          ],
          if (kolab.communityTypes.isEmpty &&
              kolab.communitySize == null &&
              kolab.typicalAttendance == null)
            _EmptyHint(text: l10n.kolabReviewEmptyCommunityInfo),
        ],
      ),
    ),
    const _SectionDivider(),
    // Step 3 -- Offers in Return
    _ReviewSection(
      icon: LucideIcons.gift,
      title: l10n.kolabReviewSectionOffersInReturn,
      step: 3,
      onEdit: onEditSection,
      child: kolab.offersInReturn.isNotEmpty
          ? _ChipList(
              items: kolab.offersInReturn.map((o) => o.displayName).toList(),
            )
          : _EmptyHint(text: l10n.kolabReviewEmptyOffers),
    ),
    const _SectionDivider(),
    // Step 4 -- Location
    _ReviewSection(
      icon: LucideIcons.mapPin,
      title: l10n.kolabReviewSectionLocation,
      step: 4,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldCity,
            value: kolab.preferredCity.isNotEmpty ? kolab.preferredCity : '--',
          ),
          if (kolab.area != null && kolab.area!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(label: l10n.kolabReviewFieldArea, value: kolab.area!),
          ],
        ],
      ),
    ),
    const _SectionDivider(),
    // Step 5 -- Availability
    _buildAvailabilitySection(l10n, 5),
  ];

  // ---------------------------------------------------------------------------
  // Venue Promotion sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildVenuePromotionSections(AppLocalizations l10n) => [
    // Step 0 -- Campaign & Venue
    _ReviewSection(
      icon: LucideIcons.building2,
      title: l10n.kolabReviewSectionCampaignVenue,
      step: 0,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldTitle,
            value: kolab.title.isNotEmpty ? kolab.title : '--',
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _ReviewField(
            label: l10n.kolabReviewFieldDescription,
            value: kolab.description.isNotEmpty ? kolab.description : '--',
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _ReviewField(
            label: l10n.kolabReviewFieldVenue,
            value: kolab.venueName ?? '--',
          ),
          if (kolab.venueType != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldType,
              value: kolab.venueType!.displayName,
            ),
          ],
          if (kolab.capacity != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldCapacity,
              value: '${kolab.capacity}',
            ),
          ],
          if (kolab.venueAddress != null && kolab.venueAddress!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldAddress,
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
      title: l10n.kolabReviewSectionMedia,
      step: 1,
      onEdit: onEditSection,
      child: _ReviewField(
        label: l10n.kolabReviewFieldPhotosVideos,
        value: kolab.media.isNotEmpty
            ? l10n.kolabReviewMediaCount(kolab.media.length)
            : l10n.kolabReviewNoMedia,
      ),
    ),
    const _SectionDivider(),
    // Step 2 -- Offering
    _ReviewSection(
      icon: LucideIcons.gift,
      title: l10n.kolabReviewSectionWhatYouOffer,
      step: 2,
      onEdit: onEditSection,
      child: kolab.offering.isNotEmpty
          ? _ChipList(items: kolab.offering)
          : _EmptyHint(text: l10n.kolabReviewEmptyOfferings),
    ),
    const _SectionDivider(),
    // Step 3 -- Seeking Communities
    _ReviewSection(
      icon: LucideIcons.users,
      title: l10n.kolabReviewSectionSeekingCommunities,
      step: 3,
      onEdit: onEditSection,
      child: kolab.seekingCommunities.isNotEmpty
          ? _ChipList(items: kolab.seekingCommunities)
          : _EmptyHint(text: l10n.kolabReviewEmptyCommunities),
    ),
    const _SectionDivider(),
    // Step 4 -- Past Events
    _ReviewSection(
      icon: LucideIcons.calendar,
      title: l10n.kolabReviewSectionPastEvents,
      step: 4,
      onEdit: onEditSection,
      child: _ReviewField(
        label: l10n.kolabReviewFieldEvents,
        value: kolab.pastEvents.isNotEmpty
            ? l10n.kolabReviewEventsCount(kolab.pastEvents.length)
            : l10n.kolabReviewNoPastEvents,
      ),
    ),
    const _SectionDivider(),
    // Step 5 -- Location
    _ReviewSection(
      icon: LucideIcons.mapPin,
      title: l10n.kolabReviewSectionLocation,
      step: 5,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldCity,
            value: kolab.preferredCity.isNotEmpty ? kolab.preferredCity : '--',
          ),
          if (kolab.venueAddress != null && kolab.venueAddress!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldAddress,
              value: kolab.venueAddress!,
            ),
          ],
        ],
      ),
    ),
    const _SectionDivider(),
    // Step 6 -- Availability
    _buildAvailabilitySection(l10n, 6),
  ];

  // ---------------------------------------------------------------------------
  // Product Promotion sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildProductPromotionSections(AppLocalizations l10n) => [
    // Step 0 -- Product Info
    _ReviewSection(
      icon: LucideIcons.box,
      title: l10n.kolabReviewSectionProductInfo,
      step: 0,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldName,
            value: kolab.productName ?? '--',
          ),
          if (kolab.productType != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(
              label: l10n.kolabReviewFieldType,
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
      title: l10n.kolabReviewSectionMedia,
      step: 1,
      onEdit: onEditSection,
      child: _ReviewField(
        label: l10n.kolabReviewFieldPhotosVideos,
        value: kolab.media.isNotEmpty
            ? l10n.kolabReviewMediaCount(kolab.media.length)
            : l10n.kolabReviewNoMedia,
      ),
    ),
    const _SectionDivider(),
    // Step 2 -- Offering
    _ReviewSection(
      icon: LucideIcons.gift,
      title: l10n.kolabReviewSectionWhatYouOffer,
      step: 2,
      onEdit: onEditSection,
      child: kolab.offering.isNotEmpty
          ? _ChipList(items: kolab.offering)
          : _EmptyHint(text: l10n.kolabReviewEmptyOfferings),
    ),
    const _SectionDivider(),
    // Step 3 -- Seeking Communities
    _ReviewSection(
      icon: LucideIcons.users,
      title: l10n.kolabReviewSectionSeekingCommunities,
      step: 3,
      onEdit: onEditSection,
      child: kolab.seekingCommunities.isNotEmpty
          ? _ChipList(items: kolab.seekingCommunities)
          : _EmptyHint(text: l10n.kolabReviewEmptyCommunities),
    ),
    const _SectionDivider(),
    // Step 4 -- Past Events
    _ReviewSection(
      icon: LucideIcons.calendar,
      title: l10n.kolabReviewSectionPastEvents,
      step: 4,
      onEdit: onEditSection,
      child: _ReviewField(
        label: l10n.kolabReviewFieldEvents,
        value: kolab.pastEvents.isNotEmpty
            ? l10n.kolabReviewEventsCount(kolab.pastEvents.length)
            : l10n.kolabReviewNoPastEvents,
      ),
    ),
    const _SectionDivider(),
    // Step 5 -- Location
    _ReviewSection(
      icon: LucideIcons.mapPin,
      title: l10n.kolabReviewSectionLocation,
      step: 5,
      onEdit: onEditSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewField(
            label: l10n.kolabReviewFieldCity,
            value: kolab.preferredCity.isNotEmpty ? kolab.preferredCity : '--',
          ),
          if (kolab.area != null && kolab.area!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ReviewField(label: l10n.kolabReviewFieldArea, value: kolab.area!),
          ],
        ],
      ),
    ),
    const _SectionDivider(),
    // Step 6 -- Availability
    _buildAvailabilitySection(l10n, 6),
  ];

  // ---------------------------------------------------------------------------
  // Shared availability section
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilitySection(AppLocalizations l10n, int step) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    var availabilityText = '--';

    if (kolab.availabilityMode != null) {
      availabilityText = kolab.availabilityMode!.displayName;
      if (kolab.availabilityStart != null) {
        availabilityText +=
            '\n${l10n.kolabReviewAvailabilityFrom(dateFormat.format(kolab.availabilityStart!))}';
      }
      if (kolab.availabilityEnd != null) {
        availabilityText +=
            '\n${l10n.kolabReviewAvailabilityTo(dateFormat.format(kolab.availabilityEnd!))}';
      }
    }

    return _ReviewSection(
      icon: LucideIcons.clock,
      title: l10n.kolabReviewSectionAvailability,
      step: step,
      onEdit: onEditSection,
      child: _ReviewField(
        label: l10n.kolabReviewFieldSchedule,
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
              Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                ),
              ),
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: context.colors.textTertiary,
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
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.colors.darkBorder);
}

/// A labelled field in a review section.
class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textTertiary),
      ),
      const SizedBox(height: KolabingSpacing.xxxs),
      Text(
        value,
        style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurface),
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
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusXs,
            ),
            child: Text(
              item,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.onSurface),
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
    style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.textTertiary, fontStyle: FontStyle.italic),
  );
}
