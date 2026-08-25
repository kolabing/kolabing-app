/// The attendee feed's filter controls: the scope toggle and the three pickers.
///
/// Split out of `attendee_home_screen.dart` when the feed was rebuilt (#161) —
/// the screen is now three sections of content and these are the chrome around
/// one of them. Nothing here holds state: every control reports a choice and
/// the screen hands it to `discoveryProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/models/community_type.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/city_list_item.dart';
import '../providers/discovery_provider.dart';

// =============================================================================
// Feed scope toggle (#142) — All events / Following
// =============================================================================

/// Two segments, not a chip: the scope is a choice between two feeds, and a
/// filter chip would read as one more optional narrowing of the same list.
class FeedScopeToggle extends StatelessWidget {
  const FeedScopeToggle({
    required this.following,
    required this.onChanged,
    required this.l10n,
  });

  final bool following;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceVariant,
        borderRadius: BorderRadius.circular(KolabingRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: l10n.attendeeHomeScopeAll,
              selected: !following,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.attendeeHomeScopeFollowing,
              selected: following,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.sm),
        child: Container(
          // 44 keeps the segment inside the 48dp touch target with its padding.
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? KolabingColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(KolabingRadius.sm),
          ),
          child: Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? KolabingColors.onSurface
                  : KolabingColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class FeedCityChip extends StatelessWidget {
  const FeedCityChip({
    required this.cityName,
    required this.onTap,
    required this.l10n,
  });

  final String? cityName;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => FeedDropdownChip(
    icon: LucideIcons.mapPin,
    label: cityName ?? l10n.attendeeHomeChooseCity,
    onTap: onTap,
  );
}

// =============================================================================
// Dropdown chip — shared pill (leading icon · label · chevron) used by BOTH
// the city picker and the date/type filters so they match exactly.
// =============================================================================

class FeedDropdownChip extends StatelessWidget {
  const FeedDropdownChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(KolabingRadius.round),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceVariant,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KolabingColors.onSurface),
          const SizedBox(width: 4),
          Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: KolabingColors.onSurface,
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// Date range sheet (#5) — pick one of upcoming/today/week/weekend/month.
// =============================================================================

class FeedDateRangeSheet extends StatelessWidget {
  const FeedDateRangeSheet({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <(String, String)>[
      (DiscoveryDateRange.upcoming, l10n.attendeeHomeFilterUpcoming),
      (DiscoveryDateRange.today, l10n.attendeeHomeFilterToday),
      (DiscoveryDateRange.week, l10n.attendeeHomeFilterThisWeek),
      (DiscoveryDateRange.weekend, l10n.attendeeHomeFilterThisWeekend),
      (DiscoveryDateRange.month, l10n.attendeeHomeFilterThisMonth),
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: KolabingSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KolabingColors.outlineVariant,
              borderRadius: BorderRadius.circular(KolabingRadius.round),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.attendeeHomeFilterDate,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
          ),
          for (final opt in options)
            _TypeRow(
              label: opt.$2,
              selected: selected == opt.$1,
              onTap: () => Navigator.of(context).pop(opt.$1),
            ),
          const SizedBox(height: KolabingSpacing.sm),
        ],
      ),
    );
  }
}

// =============================================================================
// City picker sheet — reuses citiesProvider + CityListItem
// =============================================================================

class FeedCityPickerSheet extends ConsumerStatefulWidget {
  const FeedCityPickerSheet({this.selectedCityId});

  final String? selectedCityId;

  @override
  ConsumerState<FeedCityPickerSheet> createState() =>
      _FeedCityPickerSheetState();
}

class _FeedCityPickerSheetState extends ConsumerState<FeedCityPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = ref.watch(filteredCitiesProvider(_query));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l10n.editProfileCitySearchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: KolabingColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.editProfileNoCitiesFound,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: cities.length,
                    itemBuilder: (_, i) {
                      final city = cities[i];
                      return CityListItem(
                        id: city.id,
                        name: city.name,
                        country: city.country,
                        isSelected: widget.selectedCityId == city.id,
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: KolabingColors.primary,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.editProfileCityLoadError,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(citiesProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Community-type filter sheet — slugs ONLY from communityTypesProvider
// =============================================================================

class FeedTypeSelection {
  const FeedTypeSelection({this.slug, this.name});
  final String? slug;
  final String? name;
}

class FeedTypeFilterSheet extends ConsumerWidget {
  const FeedTypeFilterSheet({this.selectedSlug});

  final String? selectedSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final typesAsync = ref.watch(communityTypesProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Text(
                l10n.attendeeHomeFilterType,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
            Expanded(
              child: typesAsync.when(
                data: (types) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _TypeRow(
                      label: l10n.attendeeHomeFilterTypeAll,
                      selected: selectedSlug == null,
                      onTap: () =>
                          Navigator.of(context).pop(const FeedTypeSelection()),
                    ),
                    for (final CommunityType t in types)
                      _TypeRow(
                        label: t.name,
                        selected: selectedSlug == t.slug,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(FeedTypeSelection(slug: t.slug, name: t.name)),
                      ),
                  ],
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: KolabingColors.primary,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.attendeeHomeFailedToLoadEvents,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(communityTypesProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm + 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: KolabingColors.onSurface,
              ),
            ),
          ),
          if (selected)
            const Icon(
              LucideIcons.check,
              size: 18,
              color: KolabingColors.primaryDark,
            ),
        ],
      ),
    ),
  );
}
