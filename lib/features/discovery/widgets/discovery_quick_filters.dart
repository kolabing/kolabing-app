import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../kolab/enums/deliverable_type.dart';
import '../../kolab/enums/intent_type.dart';
import '../../kolab/enums/need_type.dart';
import '../../kolab/enums/product_type.dart';
import '../../kolab/enums/venue_type.dart';
import '../../kolab/models/kolab.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/discovery_filters.dart';

@immutable
class DiscoveryFilterOption {
  const DiscoveryFilterOption({required this.key, required this.label});

  final String key;
  final String label;
}

abstract final class DiscoveryFilterPresets {
  static const List<DiscoveryFilterOption> communityTypeOptions =
      <DiscoveryFilterOption>[
        DiscoveryFilterOption(key: 'food_drink', label: 'Food & Drink'),
        DiscoveryFilterOption(key: 'sports', label: 'Sports'),
        DiscoveryFilterOption(key: 'wellness', label: 'Wellness'),
        DiscoveryFilterOption(key: 'culture', label: 'Culture'),
        DiscoveryFilterOption(key: 'technology', label: 'Technology'),
        DiscoveryFilterOption(key: 'education', label: 'Education'),
        DiscoveryFilterOption(key: 'entertainment', label: 'Entertainment'),
        DiscoveryFilterOption(key: 'fashion', label: 'Fashion'),
        DiscoveryFilterOption(key: 'music', label: 'Music'),
        DiscoveryFilterOption(key: 'art', label: 'Art'),
        DiscoveryFilterOption(key: 'travel', label: 'Travel'),
        DiscoveryFilterOption(key: 'networking', label: 'Networking'),
        DiscoveryFilterOption(
          key: 'business_coworking',
          label: 'Business / Coworking',
        ),
        DiscoveryFilterOption(key: 'fitness', label: 'Fitness'),
        DiscoveryFilterOption(key: 'social', label: 'Social'),
        DiscoveryFilterOption(key: 'gaming', label: 'Gaming'),
      ];

  static final List<DiscoveryFilterOption> needTypeOptions = NeedType.values
      .map(
        (NeedType item) => DiscoveryFilterOption(
          key: item.toApiValue(),
          label: item.displayName,
        ),
      )
      .toList(growable: false);

  static const List<DiscoveryFilterOption> offerTypeOptions =
      <DiscoveryFilterOption>[
        DiscoveryFilterOption(key: 'venue', label: 'Venue'),
        DiscoveryFilterOption(key: 'food_drink', label: 'Food & Drink'),
        DiscoveryFilterOption(key: 'discount', label: 'Discount'),
        DiscoveryFilterOption(key: 'products', label: 'Products'),
        DiscoveryFilterOption(key: 'social_media', label: 'Social Media'),
        DiscoveryFilterOption(
          key: 'content_creation',
          label: 'Content Creation',
        ),
        DiscoveryFilterOption(key: 'sponsorship', label: 'Sponsorship'),
        DiscoveryFilterOption(key: 'other', label: 'Other'),
      ];

  static final List<DiscoveryFilterOption> deliverableOptions = DeliverableType
      .values
      .map(
        (DeliverableType item) => DiscoveryFilterOption(
          key: item.toApiValue(),
          label: item.displayName,
        ),
      )
      .toList(growable: false);

  static final List<DiscoveryFilterOption> venueTypeOptions = VenueType.values
      .map(
        (VenueType item) => DiscoveryFilterOption(
          key: item.toApiValue(),
          label: item.displayName,
        ),
      )
      .toList(growable: false);

  static final List<DiscoveryFilterOption> productTypeOptions = ProductType
      .values
      .map(
        (ProductType item) => DiscoveryFilterOption(
          key: item.toApiValue(),
          label: item.displayName,
        ),
      )
      .toList(growable: false);

  static final List<DiscoveryFilterOption> venuePreferenceOptions =
      VenuePreference.values
          .map(
            (VenuePreference item) => DiscoveryFilterOption(
              key: item.toApiValue(),
              label: item.displayName,
            ),
          )
          .toList(growable: false);

  static final List<DiscoveryFilterOption> intentTypeOptions =
      <DiscoveryFilterOption>[
        DiscoveryFilterOption(
          key: IntentType.venuePromotion.toApiValue(),
          label: 'Venue Promotion',
        ),
        DiscoveryFilterOption(
          key: IntentType.productPromotion.toApiValue(),
          label: 'Product Promotion',
        ),
      ];

  static const List<DiscoveryFilterOption> audienceSizeBandOptions =
      <DiscoveryFilterOption>[
        DiscoveryFilterOption(key: 'small', label: 'Small'),
        DiscoveryFilterOption(key: 'medium', label: 'Medium'),
        DiscoveryFilterOption(key: 'large', label: 'Large'),
        DiscoveryFilterOption(key: 'xlarge', label: 'XLarge'),
      ];

  static const List<DiscoveryFilterOption> communityRequirementBandOptions =
      <DiscoveryFilterOption>[
        DiscoveryFilterOption(key: 'open', label: 'Open'),
        DiscoveryFilterOption(key: 'small', label: 'Small'),
        DiscoveryFilterOption(key: 'medium', label: 'Medium'),
        DiscoveryFilterOption(key: 'large', label: 'Large'),
        DiscoveryFilterOption(key: 'xlarge', label: 'XLarge'),
      ];

  static String? labelFor(String? key, List<DiscoveryFilterOption> options) {
    if (key == null) return null;
    for (final option in options) {
      if (option.key == key) return option.label;
    }
    return null;
  }
}

class DiscoveryQuickFilters extends StatelessWidget {
  const DiscoveryQuickFilters({
    required this.filters,
    required this.isCommunityViewer,
    required this.onOpenFilters,
    super.key,
  });

  final DiscoveryFilters filters;
  final bool isCommunityViewer;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final chips = isCommunityViewer
        ? <_QuickChipData>[
            _QuickChipData(
              label: _singleValue(filters.city, fallback: 'City'),
              isActive: filters.city != null,
            ),
            _QuickChipData(
              label: _multiValue(
                filters.intentTypes,
                DiscoveryFilterPresets.intentTypeOptions,
                fallback: 'Kolab Type',
              ),
              isActive: filters.intentTypes.isNotEmpty,
            ),
            _QuickChipData(
              label: _multiValue(
                filters.offerTypes,
                DiscoveryFilterPresets.offerTypeOptions,
                fallback: 'What They Offer',
              ),
              isActive: filters.offerTypes.isNotEmpty,
            ),
            _QuickChipData(
              label: _availabilityLabel(filters.availabilityMode),
              isActive: filters.availabilityMode != null,
            ),
          ]
        : <_QuickChipData>[
            _QuickChipData(
              label: _singleValue(filters.city, fallback: 'City'),
              isActive: filters.city != null,
            ),
            _QuickChipData(
              label: _multiValue(
                filters.needTypes,
                DiscoveryFilterPresets.needTypeOptions,
                fallback: 'Need',
              ),
              isActive: filters.needTypes.isNotEmpty,
            ),
            _QuickChipData(
              label: _multiValue(
                filters.communityTypes,
                DiscoveryFilterPresets.communityTypeOptions,
                fallback: 'Community Type',
              ),
              isActive: filters.communityTypes.isNotEmpty,
            ),
            _QuickChipData(
              label:
                  DiscoveryFilterPresets.labelFor(
                    filters.audienceSizeBand,
                    DiscoveryFilterPresets.audienceSizeBandOptions,
                  ) ??
                  'Audience Size',
              isActive: filters.audienceSizeBand != null,
            ),
          ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) =>
            _QuickChip(data: chips[index], onTap: onOpenFilters),
        separatorBuilder: (_, int index) =>
            const SizedBox(width: KolabingSpacing.xs),
        itemCount: chips.length,
      ),
    );
  }

  String _singleValue(String? value, {required String fallback}) =>
      (value == null || value.isEmpty) ? fallback : value;

  String _multiValue(
    List<String> values,
    List<DiscoveryFilterOption> options, {
    required String fallback,
  }) {
    if (values.isEmpty) return fallback;
    final firstLabel =
        DiscoveryFilterPresets.labelFor(values.first, options) ?? values.first;
    if (values.length == 1) return firstLabel;
    return '$firstLabel +${values.length - 1}';
  }

  String _availabilityLabel(String? availabilityMode) {
    if (availabilityMode == null) return 'Availability';
    return AvailabilityMode.fromString(availabilityMode).displayName;
  }
}

class _QuickChipData {
  const _QuickChipData({required this.label, required this.isActive});

  final String label;
  final bool isActive;
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.data, required this.onTap});

  final _QuickChipData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: data.isActive
            ? KolabingColors.softYellow
            : KolabingColors.surface,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: Border.all(
          color: data.isActive ? KolabingColors.primary : KolabingColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            LucideIcons.slidersHorizontal,
            size: 14,
            color: data.isActive
                ? KolabingColors.textPrimary
                : KolabingColors.textTertiary,
          ),
        ],
      ),
    ),
  );
}
