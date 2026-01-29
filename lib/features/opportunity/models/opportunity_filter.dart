import 'package:flutter/foundation.dart';

/// Filter state for browsing opportunities
@immutable
class OpportunityFilters {
  const OpportunityFilters({
    this.searchQuery = '',
    this.creatorType,
    this.selectedCategories = const [],
    this.selectedCity,
    this.venueMode,
    this.availabilityMode,
    this.availabilityFrom,
    this.availabilityTo,
  });

  final String searchQuery;
  final String? creatorType;
  final List<String> selectedCategories;
  final String? selectedCity;
  final String? venueMode;
  final String? availabilityMode;
  final DateTime? availabilityFrom;
  final DateTime? availabilityTo;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      creatorType != null ||
      selectedCategories.isNotEmpty ||
      selectedCity != null ||
      venueMode != null ||
      availabilityMode != null ||
      availabilityFrom != null ||
      availabilityTo != null;

  int get activeFilterCount {
    var count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (creatorType != null) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (selectedCity != null) count++;
    if (venueMode != null) count++;
    if (availabilityMode != null) count++;
    if (availabilityFrom != null || availabilityTo != null) count++;
    return count;
  }

  OpportunityFilters copyWith({
    String? searchQuery,
    String? creatorType,
    List<String>? selectedCategories,
    String? selectedCity,
    String? venueMode,
    String? availabilityMode,
    DateTime? availabilityFrom,
    DateTime? availabilityTo,
    bool clearCreatorType = false,
    bool clearCity = false,
    bool clearVenueMode = false,
    bool clearAvailabilityMode = false,
    bool clearDateRange = false,
  }) =>
      OpportunityFilters(
        searchQuery: searchQuery ?? this.searchQuery,
        creatorType:
            clearCreatorType ? null : (creatorType ?? this.creatorType),
        selectedCategories: selectedCategories ?? this.selectedCategories,
        selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
        venueMode: clearVenueMode ? null : (venueMode ?? this.venueMode),
        availabilityMode: clearAvailabilityMode
            ? null
            : (availabilityMode ?? this.availabilityMode),
        availabilityFrom: clearDateRange
            ? null
            : (availabilityFrom ?? this.availabilityFrom),
        availabilityTo:
            clearDateRange ? null : (availabilityTo ?? this.availabilityTo),
      );

  /// Reset all filters
  static const OpportunityFilters empty = OpportunityFilters();

  /// Convert to API query parameters
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (searchQuery.isNotEmpty) params['search'] = searchQuery;
    if (creatorType != null) params['creator_type'] = creatorType!;
    if (selectedCity != null) params['city'] = selectedCity!;
    if (venueMode != null) params['venue_mode'] = venueMode!;
    if (availabilityMode != null) {
      params['availability_mode'] = availabilityMode!;
    }
    if (availabilityFrom != null) {
      params['availability_from'] =
          availabilityFrom!.toIso8601String().split('T').first;
    }
    if (availabilityTo != null) {
      params['availability_to'] =
          availabilityTo!.toIso8601String().split('T').first;
    }
    return params;
  }

  /// Category query parameters need special handling (array)
  List<MapEntry<String, String>> toCategoryParams() =>
      selectedCategories
          .map((c) => MapEntry('categories[]', c))
          .toList();
}
