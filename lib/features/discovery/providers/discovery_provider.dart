import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../models/discovery_filters.dart';
import '../models/explore_feed_item.dart';
import '../services/discovery_service.dart';

final discoveryServiceProvider = Provider<DiscoveryService>(
  (ref) => DiscoveryService(authService: ref.watch(authServiceProvider)),
);

class DiscoveryFiltersNotifier extends Notifier<DiscoveryFilters> {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();

  void setFeed(DiscoveryFeed feed) {
    if (state.feed == feed) return;
    state = state.copyWith(feed: feed);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCity(String? city) {
    if (city == null || city.isEmpty) {
      state = state.copyWith(clearCity: true);
      return;
    }
    state = state.copyWith(city: city);
  }

  void setAvailabilityMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      state = state.copyWith(clearAvailabilityMode: true);
      return;
    }
    state = state.copyWith(availabilityMode: mode);
  }

  void setAvailabilityRange({DateTime? start, DateTime? end}) {
    if (start == null && end == null) {
      state = state.copyWith(clearAvailabilityRange: true);
      return;
    }
    state = state.copyWith(availabilityFrom: start, availabilityTo: end);
  }

  void setSort(String? sort) {
    if (sort == null || sort.isEmpty) {
      state = state.copyWith(clearSort: true);
      return;
    }
    state = state.copyWith(sort: sort);
  }

  void toggleIntentType(String value) =>
      state = state.copyWith(intentTypes: _toggle(state.intentTypes, value));

  void toggleOfferType(String value) =>
      state = state.copyWith(offerTypes: _toggle(state.offerTypes, value));

  void toggleNeedType(String value) =>
      state = state.copyWith(needTypes: _toggle(state.needTypes, value));

  void toggleCommunityType(String value) => state = state.copyWith(
    communityTypes: _toggle(state.communityTypes, value),
  );

  void setAudienceSizeBand(String? value) {
    if (state.audienceSizeBand == value) {
      state = state.copyWith(clearAudienceSizeBand: true);
      return;
    }
    state = state.copyWith(audienceSizeBand: value);
  }

  void setCommunityRequirementBand(String? value) {
    if (state.communityRequirementBand == value) {
      state = state.copyWith(clearCommunityRequirementBand: true);
      return;
    }
    state = state.copyWith(communityRequirementBand: value);
  }

  void toggleVenueType(String value) =>
      state = state.copyWith(venueTypes: _toggle(state.venueTypes, value));

  void toggleProductType(String value) =>
      state = state.copyWith(productTypes: _toggle(state.productTypes, value));

  void toggleExpectedDeliverable(String value) => state = state.copyWith(
    expectedDeliverables: _toggle(state.expectedDeliverables, value),
  );

  void toggleOfferInReturn(String value) => state = state.copyWith(
    offersInReturn: _toggle(state.offersInReturn, value),
  );

  void toggleVenuePreference(String value) => state = state.copyWith(
    venuePreferences: _toggle(state.venuePreferences, value),
  );

  void clearAll() {
    state = state.clearAll();
  }

  static List<String> _toggle(List<String> current, String value) {
    final updated = List<String>.from(current);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    return updated;
  }
}

final discoveryFiltersProvider =
    NotifierProvider<DiscoveryFiltersNotifier, DiscoveryFilters>(
      DiscoveryFiltersNotifier.new,
    );

@immutable
class DiscoveryListState {
  const DiscoveryListState({
    this.items = const <ExploreFeedItem>[],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<ExploreFeedItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty && !isLoading;

  DiscoveryListState copyWith({
    List<ExploreFeedItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) => DiscoveryListState(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    total: total ?? this.total,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : (error ?? this.error),
  );
}

class DiscoveryListNotifier extends Notifier<DiscoveryListState>
    with AuthScopeGuard<DiscoveryListState> {
  late DiscoveryService _service;
  int _activeRequestGeneration = 0;

  @override
  DiscoveryListState build() {
    _service = ref.read(discoveryServiceProvider);
    final filters = ref.watch(discoveryFiltersProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: refresh,
        onSessionInvalidated: _invalidateActiveRequests,
      );
    });

    Future<void>.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: () => _load(filters),
      );
    });

    return const DiscoveryListState(isLoading: true);
  }

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const DiscoveryListState();
  }

  Future<void> _load(DiscoveryFilters filters) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }

    final requestGeneration = ++_activeRequestGeneration;
    final sessionVersion = activeAuthSessionVersion;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getOpportunities(filters: filters, page: 1);
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = DiscoveryListState(
        items: result.data,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } on AuthException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } on ApiException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.error.message);
    } on NetworkException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load discovery opportunities',
      );
    }
  }

  Future<void> refresh() async {
    await _load(ref.read(discoveryFiltersProvider));
  }

  Future<void> loadMore() async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final requestGeneration = _activeRequestGeneration;
    final sessionVersion = activeAuthSessionVersion;

    try {
      final result = await _service.getOpportunities(
        filters: ref.read(discoveryFiltersProvider),
        page: state.currentPage + 1,
      );
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }

      state = state.copyWith(
        items: <ExploreFeedItem>[...state.items, ...result.data],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoadingMore: false,
      );
    } on Exception {
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final discoveryListProvider =
    NotifierProvider<DiscoveryListNotifier, DiscoveryListState>(
      DiscoveryListNotifier.new,
    );
