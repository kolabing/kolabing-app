import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collab_request.dart';
import '../services/explore_service.dart';

/// Provider for the ExploreService instance
final exploreServiceProvider = Provider<ExploreService>(
  (ref) => ExploreService.instance,
);

/// State class for explore screen filters
@immutable
class ExploreFilters {
  const ExploreFilters({
    this.searchQuery = '',
    this.selectedType,
    this.selectedLocation,
  });

  final String searchQuery;
  final CollabType? selectedType;
  final String? selectedLocation;

  ExploreFilters copyWith({
    String? searchQuery,
    CollabType? selectedType,
    String? selectedLocation,
    bool clearType = false,
    bool clearLocation = false,
  }) =>
      ExploreFilters(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedType: clearType ? null : (selectedType ?? this.selectedType),
        selectedLocation:
            clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      );

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedType != null ||
      selectedLocation != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreFilters &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedType == other.selectedType &&
          selectedLocation == other.selectedLocation;

  @override
  int get hashCode =>
      searchQuery.hashCode ^ selectedType.hashCode ^ selectedLocation.hashCode;
}

/// Provider for managing explore filters state using Riverpod 3.x Notifier
final exploreFiltersProvider =
    NotifierProvider<ExploreFiltersNotifier, ExploreFilters>(
        ExploreFiltersNotifier.new);

/// Notifier for explore filters using Riverpod 3.x pattern
class ExploreFiltersNotifier extends Notifier<ExploreFilters> {
  @override
  ExploreFilters build() => const ExploreFilters();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCollabType(CollabType? type) {
    if (type == state.selectedType) {
      // Deselect if already selected
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(selectedType: type);
    }
  }

  void setLocation(String? location) {
    if (location == state.selectedLocation) {
      state = state.copyWith(clearLocation: true);
    } else {
      state = state.copyWith(selectedLocation: location);
    }
  }

  void clearAllFilters() {
    state = const ExploreFilters();
  }
}

/// Provider for fetching collaboration requests based on current filters
final collabRequestsProvider =
    AsyncNotifierProvider<CollabRequestsNotifier, List<CollabRequest>>(
        CollabRequestsNotifier.new);

/// Notifier for collaboration requests with AsyncNotifier pattern
class CollabRequestsNotifier extends AsyncNotifier<List<CollabRequest>> {
  @override
  Future<List<CollabRequest>> build() async {
    // Watch the filters and refetch when they change
    final filters = ref.watch(exploreFiltersProvider);
    return _fetchCollabRequests(filters);
  }

  Future<List<CollabRequest>> _fetchCollabRequests(
      ExploreFilters filters) async {
    final service = ref.read(exploreServiceProvider);

    return service.getCollabRequests(
      query: filters.searchQuery.isEmpty ? null : filters.searchQuery,
      collabType: filters.selectedType,
      location: filters.selectedLocation,
    );
  }

  /// Manually refresh the list
  Future<void> refresh() async {
    state = const AsyncLoading();
    final filters = ref.read(exploreFiltersProvider);
    state = await AsyncValue.guard(() => _fetchCollabRequests(filters));
  }
}

/// Provider for available locations for filtering
final availableLocationsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(exploreServiceProvider);
  return service.getAvailableLocations();
});
