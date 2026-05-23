import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/discovery/models/discovery_filters.dart';
import '../features/discovery/providers/discovery_provider.dart';
import '../features/discovery/widgets/discovery_quick_filters.dart';
import '../features/onboarding/models/city.dart';
import '../features/onboarding/providers/onboarding_provider.dart'
    as onboarding;
import '../features/opportunity/models/opportunity.dart';
import 'keyboard_avoiding_content.dart';

class ExploreFilterSheet extends ConsumerStatefulWidget {
  const ExploreFilterSheet({super.key, this.totalResults});

  final int? totalResults;

  static Future<void> show(BuildContext context, {int? totalResults}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) =>
            ExploreFilterSheet(totalResults: totalResults),
      );

  @override
  ConsumerState<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends ConsumerState<ExploreFilterSheet> {
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;
  late final FocusNode _cityFocusNode;
  Timer? _searchDebounce;
  Timer? _cityDebounce;

  bool get _isCommunityViewer =>
      ref.read(authProvider).user?.isCommunity ?? false;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(discoveryFiltersProvider);
    _searchController = TextEditingController(text: filters.searchQuery);
    _cityController = TextEditingController(text: filters.city ?? '');
    _cityFocusNode = FocusNode()..addListener(_handleCityFocusChange);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _cityDebounce?.cancel();
    _cityFocusNode
      ..removeListener(_handleCityFocusChange)
      ..dispose();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleCityFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(discoveryFiltersProvider.notifier).setSearch(value.trim());
    });
  }

  void _onCityChanged(String value) {
    _cityDebounce?.cancel();
    _cityDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(discoveryFiltersProvider.notifier).setCity(value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    ref.read(discoveryFiltersProvider.notifier).setSearch('');
  }

  void _clearCity() {
    _cityController.clear();
    _cityDebounce?.cancel();
    ref.read(discoveryFiltersProvider.notifier).setCity(null);
  }

  void _selectCity(String cityName) {
    _cityDebounce?.cancel();
    _cityController.value = TextEditingValue(
      text: cityName,
      selection: TextSelection.collapsed(offset: cityName.length),
    );
    ref.read(discoveryFiltersProvider.notifier).setCity(cityName);
    _cityFocusNode.unfocus();
    setState(() {});
  }

  void _clearAll() {
    _searchController.clear();
    _cityController.clear();
    _searchDebounce?.cancel();
    _cityDebounce?.cancel();
    ref.read(discoveryFiltersProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoveryFiltersProvider);

    return KeyboardAvoidingContent(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KolabingRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderRow(
                      hasActiveFilters: filters.hasActiveFilters,
                      onClearAll: _clearAll,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: KolabingSpacing.md),
                    _FilterTextField(
                      controller: _searchController,
                      hintText: 'Search by title, description, or creator...',
                      icon: LucideIcons.search,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: KolabingSpacing.md),
                    const _SectionLabel(label: 'City'),
                    const SizedBox(height: KolabingSpacing.xs),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _cityController,
                      builder:
                          (BuildContext context, TextEditingValue value, _) {
                            final cityQuery = value.text.trim();

                            return Column(
                              children: [
                                _FilterTextField(
                                  controller: _cityController,
                                  focusNode: _cityFocusNode,
                                  hintText: 'Type a city',
                                  icon: LucideIcons.mapPin,
                                  onChanged: _onCityChanged,
                                  onClear: _clearCity,
                                ),
                                if (_cityFocusNode.hasFocus &&
                                    cityQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: KolabingSpacing.xs,
                                    ),
                                    child: _CityAutocompleteResults(
                                      query: cityQuery,
                                      selectedCity: filters.city,
                                      onSelected: _selectCity,
                                    ),
                                  ),
                              ],
                            );
                          },
                    ),
                    const SizedBox(height: KolabingSpacing.lg),
                    const _SectionLabel(label: 'Availability'),
                    const SizedBox(height: KolabingSpacing.xs),
                    _SingleSelectChipGroup(
                      options: AvailabilityMode.values
                          .map(
                            (AvailabilityMode item) => DiscoveryFilterOption(
                              key: item.toApiValue(),
                              label: item.displayName,
                            ),
                          )
                          .toList(growable: false),
                      selectedValue: filters.availabilityMode,
                      onSelected: (String? value) => ref
                          .read(discoveryFiltersProvider.notifier)
                          .setAvailabilityMode(value),
                    ),
                    const SizedBox(height: KolabingSpacing.lg),
                    if (_isCommunityViewer)
                      _CommunitySections(filters: filters)
                    else
                      _BusinessSections(filters: filters),
                    if (widget.totalResults != null) ...[
                      const SizedBox(height: KolabingSpacing.lg),
                      _ResultsCount(total: widget.totalResults!),
                      const SizedBox(height: KolabingSpacing.md),
                    ],
                    SizedBox(
                      height:
                          MediaQuery.of(context).viewPadding.bottom +
                          KolabingSpacing.md,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySections extends ConsumerWidget {
  const _CommunitySections({required this.filters});

  final DiscoveryFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(discoveryFiltersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Collab Type'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.intentTypeOptions,
          selectedValues: filters.intentTypes,
          onToggle: notifier.toggleIntentType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'What They Offer'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.offerTypeOptions,
          selectedValues: filters.offerTypes,
          onToggle: notifier.toggleOfferType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Venue Type'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.venueTypeOptions,
          selectedValues: filters.venueTypes,
          onToggle: notifier.toggleVenueType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Product Type'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.productTypeOptions,
          selectedValues: filters.productTypes,
          onToggle: notifier.toggleProductType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Expected Deliverables'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.deliverableOptions,
          selectedValues: filters.expectedDeliverables,
          onToggle: notifier.toggleExpectedDeliverable,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Minimum Community Size Requirement'),
        const SizedBox(height: KolabingSpacing.xs),
        _SingleSelectChipGroup(
          options: DiscoveryFilterPresets.communityRequirementBandOptions,
          selectedValue: filters.communityRequirementBand,
          onSelected: notifier.setCommunityRequirementBand,
        ),
      ],
    );
  }
}

class _BusinessSections extends ConsumerWidget {
  const _BusinessSections({required this.filters});

  final DiscoveryFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(discoveryFiltersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Need'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.needTypeOptions,
          selectedValues: filters.needTypes,
          onToggle: notifier.toggleNeedType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Community Type'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.communityTypeOptions,
          selectedValues: filters.communityTypes,
          onToggle: notifier.toggleCommunityType,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Audience Size'),
        const SizedBox(height: KolabingSpacing.xs),
        _SingleSelectChipGroup(
          options: DiscoveryFilterPresets.audienceSizeBandOptions,
          selectedValue: filters.audienceSizeBand,
          onSelected: notifier.setAudienceSizeBand,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Offers In Return'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.deliverableOptions,
          selectedValues: filters.offersInReturn,
          onToggle: notifier.toggleOfferInReturn,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        const _SectionLabel(label: 'Venue Preference'),
        const SizedBox(height: KolabingSpacing.xs),
        _MultiSelectChipGroup(
          options: DiscoveryFilterPresets.venuePreferenceOptions,
          selectedValues: filters.venuePreferences,
          onToggle: notifier.toggleVenuePreference,
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KolabingSpacing.sm),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: KolabingColors.border,
          borderRadius: BorderRadius.circular(KolabingRadius.round),
        ),
      ),
    ),
  );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.hasActiveFilters,
    required this.onClearAll,
    required this.onClose,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Search & Filter',
        style: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      ),
      const Spacer(),
      if (hasActiveFilters)
        GestureDetector(
          onTap: onClearAll,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.xs,
              vertical: KolabingSpacing.xxs,
            ),
            child: Text(
              'Clear all',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KolabingColors.primary,
              ),
            ),
          ),
        ),
      const SizedBox(width: KolabingSpacing.xs),
      GestureDetector(
        onTap: onClose,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.all(KolabingSpacing.xxs),
          child: Icon(
            LucideIcons.x,
            size: 22,
            color: KolabingColors.textTertiary,
          ),
        ),
      ),
    ],
  );
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (BuildContext context, TextEditingValue value, _) {
          final hasText = value.text.isNotEmpty;

          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textTertiary,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: KolabingColors.textTertiary,
              ),
              suffixIcon: hasText
                  ? GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: KolabingColors.textTertiary,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: KolabingColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: const BorderSide(
                  color: KolabingColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      );
}

class _CityAutocompleteResults extends ConsumerWidget {
  const _CityAutocompleteResults({
    required this.query,
    required this.selectedCity,
    required this.onSelected,
  });

  final String query;
  final String? selectedCity;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(onboarding.filteredCitiesProvider(query));

    return citiesAsync.when(
      data: (List<OnboardingCity> cities) {
        final visibleCities = cities.take(6).toList(growable: false);

        if (visibleCities.isEmpty) {
          return const _CityAutocompleteMessage(
            message: 'No matching cities found',
          );
        }

        final listHeight = visibleCities.length > 4
            ? 224.0
            : visibleCities.length * 56.0;

        return Container(
          height: listHeight,
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: KolabingColors.border),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: visibleCities.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1, color: KolabingColors.border),
            itemBuilder: (BuildContext context, int index) {
              final city = visibleCities[index];
              final isSelected = selectedCity == city.name;

              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.mapPin,
                  size: 18,
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.textTertiary,
                ),
                title: Text(
                  city.name,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                subtitle: city.country == null
                    ? null
                    : Text(
                        city.country!,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                onTap: () => onSelected(city.name),
              );
            },
          ),
        );
      },
      loading: () => const _CityAutocompleteMessage(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KolabingColors.primary,
          ),
        ),
      ),
      error: (Object error, StackTrace stackTrace) =>
          const _CityAutocompleteMessage(
            message: 'Could not load city suggestions',
          ),
    );
  }
}

class _CityAutocompleteMessage extends StatelessWidget {
  const _CityAutocompleteMessage({this.message, this.child})
    : assert(
        message != null || child != null,
        'Provide either a message or a child widget.',
      );

  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.md,
      vertical: KolabingSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: KolabingColors.border),
    ),
    child: Center(
      child:
          child ??
          Text(
            message!,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
            ),
          ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.openSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: KolabingColors.textSecondary,
    ),
  );
}

class _SingleSelectChipGroup extends StatelessWidget {
  const _SingleSelectChipGroup({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<DiscoveryFilterOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KolabingSpacing.xs,
    runSpacing: KolabingSpacing.xs,
    children: options.map((DiscoveryFilterOption option) {
      final isSelected = selectedValue == option.key;

      return _SheetChip(
        label: option.label,
        isSelected: isSelected,
        onTap: () => onSelected(option.key),
      );
    }).toList(),
  );
}

class _MultiSelectChipGroup extends StatelessWidget {
  const _MultiSelectChipGroup({
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final List<DiscoveryFilterOption> options;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KolabingSpacing.xs,
    runSpacing: KolabingSpacing.xs,
    children: options.map((DiscoveryFilterOption option) {
      final isSelected = selectedValues.contains(option.key);

      return _SheetChip(
        label: option.label,
        isSelected: isSelected,
        onTap: () => onToggle(option.key),
      );
    }).toList(),
  );
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? KolabingColors.primary : KolabingColors.surface,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: isSelected ? null : Border.all(color: KolabingColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected
              ? KolabingColors.onPrimary
              : KolabingColors.textPrimary,
        ),
      ),
    ),
  );
}

class _ResultsCount extends StatelessWidget {
  const _ResultsCount({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      total > 0
          ? '$total result${total == 1 ? '' : 's'} found'
          : 'Showing all opportunities',
      style: GoogleFonts.openSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: KolabingColors.textTertiary,
      ),
    ),
  );
}
