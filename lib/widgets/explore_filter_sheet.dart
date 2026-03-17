import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/opportunity/models/opportunity.dart';
import '../features/opportunity/providers/opportunity_provider.dart';

/// Modal bottom sheet for searching and filtering opportunities in the
/// Explore tab. Reads and writes to [opportunityFiltersProvider].
class ExploreFilterSheet extends ConsumerStatefulWidget {
  const ExploreFilterSheet({
    super.key,
    this.totalResults,
  });

  /// Total number of opportunities matching the current filters.
  /// When `null` the results count row is hidden.
  final int? totalResults;

  /// Convenience method to present the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, {int? totalResults}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExploreFilterSheet(totalResults: totalResults),
      );

  @override
  ConsumerState<ExploreFilterSheet> createState() =>
      _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends ConsumerState<ExploreFilterSheet> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final currentQuery =
        ref.read(opportunityFiltersProvider).searchQuery;
    _searchController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Debounced search
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(opportunityFiltersProvider.notifier).setSearch(value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(opportunityFiltersProvider.notifier).setSearch('');
  }

  // ---------------------------------------------------------------------------
  // Filter helpers
  // ---------------------------------------------------------------------------

  void _onVenueModeSelected(VenueMode mode) {
    ref
        .read(opportunityFiltersProvider.notifier)
        .setVenueMode(mode.toApiValue());
  }

  void _onAvailabilitySelected(AvailabilityMode mode) {
    ref
        .read(opportunityFiltersProvider.notifier)
        .setAvailabilityMode(mode.toApiValue());
  }

  void _clearAll() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(opportunityFiltersProvider.notifier).clearAll();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(opportunityFiltersProvider);
    final hasFilters = filters.hasActiveFilters;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
          // Drag handle
          const _DragHandle(),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  _HeaderRow(
                    hasActiveFilters: hasFilters,
                    onClearAll: _clearAll,
                    onClose: () => Navigator.of(context).pop(),
                  ),

                  const SizedBox(height: KolabingSpacing.md),

                  // Search field
                  _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Venue Type section
                  const _SectionLabel(label: 'Venue Type'),
                  const SizedBox(height: KolabingSpacing.xs),
                  _ChipGroup<VenueMode>(
                    values: VenueMode.values,
                    selectedValue: filters.venueMode,
                    labelOf: (mode) => mode.displayName,
                    apiValueOf: (mode) => mode.toApiValue(),
                    onSelected: _onVenueModeSelected,
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Availability section
                  const _SectionLabel(label: 'Availability'),
                  const SizedBox(height: KolabingSpacing.xs),
                  _ChipGroup<AvailabilityMode>(
                    values: AvailabilityMode.values,
                    selectedValue: filters.availabilityMode,
                    labelOf: (mode) => mode.displayName,
                    apiValueOf: (mode) => mode.toApiValue(),
                    onSelected: _onAvailabilitySelected,
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Results count
                  if (widget.totalResults != null) ...[
                    _ResultsCount(total: widget.totalResults!),
                    const SizedBox(height: KolabingSpacing.md),
                  ],

                  // Bottom safe area padding
                  SizedBox(
                    height: MediaQuery.of(context).viewPadding.bottom +
                        KolabingSpacing.md,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private sub-widgets
// =============================================================================

/// Gray drag handle at the top of the sheet.
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

/// Header with title, optional "Clear all" button, and close icon.
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
          // Title
          Text(
            'Search & Filter',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),

          const Spacer(),

          // Clear all (visible only when filters are active)
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

          // Close button
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

/// Search text field with debounced input and a clear suffix icon.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;

          return TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by title, description, or creator...',
              hintStyle: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textTertiary,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
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

/// Section label text ("Venue Type", "Availability", etc.).
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

/// A horizontal wrap of selectable filter chips.
///
/// [T] is the enum type (e.g. [VenueMode], [AvailabilityMode]).
/// [selectedValue] is the current filter value as the API string (or `null`).
class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup({
    required this.values,
    required this.selectedValue,
    required this.labelOf,
    required this.apiValueOf,
    required this.onSelected,
  });

  final List<T> values;
  final String? selectedValue;
  final String Function(T) labelOf;
  final String Function(T) apiValueOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: KolabingSpacing.xs,
        runSpacing: KolabingSpacing.xs,
        children: values.map((value) {
          final isSelected = selectedValue == apiValueOf(value);

          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? KolabingColors.primary
                    : KolabingColors.surface,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
                border: isSelected
                    ? null
                    : Border.all(color: KolabingColors.border),
              ),
              child: Text(
                labelOf(value),
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
        }).toList(),
      );
}

/// Displays the total results count at the bottom of the filter sheet.
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
