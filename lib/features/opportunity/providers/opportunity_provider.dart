import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../../onboarding/models/city.dart';
import '../models/opportunity.dart';
import '../models/opportunity_filter.dart';
import '../services/opportunity_service.dart';

// =============================================================================
// Service Provider
// =============================================================================

/// Provider for OpportunityService instance — uses the shared AuthService
/// so token cache stays in sync after login/logout.
final opportunityServiceProvider = Provider<OpportunityService>(
  (ref) => OpportunityService(authService: ref.watch(authServiceProvider)),
);

// =============================================================================
// Cities Provider
// =============================================================================

/// Provider for cities dropdown data
final citiesProvider = FutureProvider<List<OnboardingCity>>((ref) async {
  final service = ref.watch(opportunityServiceProvider);
  return service.getCities();
});

// =============================================================================
// Browse Filters
// =============================================================================

/// Notifier for browse filter state
class OpportunityFiltersNotifier extends Notifier<OpportunityFilters> {
  @override
  OpportunityFilters build() => OpportunityFilters.empty;

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCreatorType(String? type) {
    if (state.creatorType == type) {
      state = state.copyWith(clearCreatorType: true);
    } else {
      state = state.copyWith(creatorType: type);
    }
  }

  /// Sets creator type without toggling — used when the filter is locked (e.g. community explore)
  void setCreatorTypeLocked(String type) {
    state = state.copyWith(creatorType: type);
  }

  void toggleCategory(String category) {
    final current = List<String>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  void setCity(String? city) {
    if (state.selectedCity == city) {
      state = state.copyWith(clearCity: true);
    } else {
      state = state.copyWith(selectedCity: city);
    }
  }

  void setVenueMode(String? mode) {
    if (state.venueMode == mode) {
      state = state.copyWith(clearVenueMode: true);
    } else {
      state = state.copyWith(venueMode: mode);
    }
  }

  void setAvailabilityMode(String? mode) {
    if (state.availabilityMode == mode) {
      state = state.copyWith(clearAvailabilityMode: true);
    } else {
      state = state.copyWith(availabilityMode: mode);
    }
  }

  void clearAll() {
    state = OpportunityFilters.empty;
  }
}

final opportunityFiltersProvider =
    NotifierProvider<OpportunityFiltersNotifier, OpportunityFilters>(
      OpportunityFiltersNotifier.new,
    );

// =============================================================================
// Browse Opportunities List (with pagination)
// =============================================================================

/// State for paginated opportunity list
@immutable
class OpportunityListState {
  const OpportunityListState({
    this.opportunities = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.requiresSubscription = false,
    this.error,
  });

  final List<Opportunity> opportunities;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool requiresSubscription;
  final String? error;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => opportunities.isEmpty && !isLoading;

  OpportunityListState copyWith({
    List<Opportunity>? opportunities,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? requiresSubscription,
    String? error,
    bool clearError = false,
  }) => OpportunityListState(
    opportunities: opportunities ?? this.opportunities,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    total: total ?? this.total,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    requiresSubscription: requiresSubscription ?? this.requiresSubscription,
    error: clearError ? null : (error ?? this.error),
  );
}

class OpportunityListNotifier extends Notifier<OpportunityListState>
    with AuthScopeGuard<OpportunityListState> {
  late OpportunityService _service;
  int _activeRequestGeneration = 0;

  @override
  OpportunityListState build() {
    _service = ref.read(opportunityServiceProvider);

    // Watch filters and reload when they change
    final filters = ref.watch(opportunityFiltersProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: refresh,
        onSessionInvalidated: _invalidateActiveRequests,
      );
    });

    // Schedule initial load after build
    Future.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: () => _load(filters),
      );
    });

    return const OpportunityListState(isLoading: true);
  }

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const OpportunityListState();
  }

  Future<void> _load(OpportunityFilters filters) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }

    final requestGeneration = ++_activeRequestGeneration;
    debugPrint(
      '[OpportunityList] _load called, filters: search=${filters.searchQuery}, creator=${filters.creatorType}',
    );
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.getOpportunities(filters: filters, page: 1);
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint(
        '[OpportunityList] Loaded ${result.data.length} items, total=${result.total}',
      );
      state = OpportunityListState(
        opportunities: result.data,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
      debugPrint(
        '[OpportunityList] State updated: isEmpty=${state.isEmpty}, isLoading=${state.isLoading}, error=${state.error}',
      );
    } on AuthException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('[OpportunityList] AuthException: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
    } on ApiException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('[OpportunityList] ApiException: ${e.error.message}');
      state = state.copyWith(isLoading: false, error: e.error.message);
    } on NetworkException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('[OpportunityList] NetworkException: ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception catch (e, st) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('[OpportunityList] Error: $e');
      debugPrint('[OpportunityList] Stack: $st');
      state = state.copyWith(isLoading: false, error: 'Failed to load Kolabs');
    }
  }

  Future<void> refresh() async {
    final filters = ref.read(opportunityFiltersProvider);
    await _load(filters);
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
    final filters = ref.read(opportunityFiltersProvider);
    final requestGeneration = _activeRequestGeneration;

    try {
      final result = await _service.getOpportunities(
        filters: filters,
        page: state.currentPage + 1,
      );
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        opportunities: [...state.opportunities, ...result.data],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('Load more error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final opportunityListProvider =
    NotifierProvider<OpportunityListNotifier, OpportunityListState>(
      OpportunityListNotifier.new,
    );

// =============================================================================
// My Opportunities List (with pagination)
// =============================================================================

/// Status filter for My Opportunities
class MyOpportunitiesStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null; // null = all statuses

  String? get status => state;

  set status(String? value) {
    state = value;
  }
}

final myOpportunitiesStatusProvider =
    NotifierProvider<MyOpportunitiesStatusNotifier, String?>(
      MyOpportunitiesStatusNotifier.new,
    );

class MyOpportunitiesNotifier extends Notifier<OpportunityListState>
    with AuthScopeGuard<OpportunityListState> {
  late OpportunityService _service;
  int _activeRequestGeneration = 0;

  @override
  OpportunityListState build() {
    _service = ref.read(opportunityServiceProvider);

    final status = ref.watch(myOpportunitiesStatusProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: refresh,
        onSessionInvalidated: _invalidateActiveRequests,
      );
    });

    Future.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: () => _load(status),
      );
    });

    return const OpportunityListState(isLoading: true);
  }

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const OpportunityListState();
  }

  Future<void> _load(String? status) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }

    final requestGeneration = ++_activeRequestGeneration;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      requiresSubscription: false,
      clearError: true,
    );

    try {
      final result = await _service.getMyOpportunities(status: status, page: 1);
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = OpportunityListState(
        opportunities: result.data,
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
    } on Exception catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('Load my opportunities error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load your Kolabs',
      );
    }
  }

  Future<void> refresh() async {
    final status = ref.read(myOpportunitiesStatusProvider);
    await _load(status);
  }

  Future<void> loadMore() async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final status = ref.read(myOpportunitiesStatusProvider);
    final requestGeneration = _activeRequestGeneration;

    try {
      final result = await _service.getMyOpportunities(
        status: status,
        page: state.currentPage + 1,
      );
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        opportunities: [...state.opportunities, ...result.data],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      debugPrint('Load more my opportunities error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Publish an opportunity and update the list
  Future<bool> publish(String id) async {
    try {
      final updated = await _service.publishOpportunity(id);
      _replaceInList(id, updated);
      await refresh();
      return true;
    } on ApiException catch (e) {
      debugPrint('Publish error: ${e.error.message}');
      if (e.error.requiresSubscription || e.error.statusCode == 402) {
        state = state.copyWith(
          requiresSubscription: true,
          error: e.error.message,
        );
        return false;
      }
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Publish error: $e');
      state = state.copyWith(error: 'Failed to publish Kolab');
      return false;
    }
  }

  void clearSubscriptionRequirement() {
    state = state.copyWith(requiresSubscription: false);
  }

  /// Close an opportunity and update the list
  Future<bool> close(String id) async {
    try {
      final updated = await _service.closeOpportunity(id);
      _replaceInList(id, updated);
      await refresh();
      return true;
    } on ApiException catch (e) {
      debugPrint('Close error: ${e.error.message}');
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Close error: $e');
      state = state.copyWith(error: 'Failed to close Kolab');
      return false;
    }
  }

  /// Delete an opportunity and remove from list
  Future<bool> delete(String id) async {
    try {
      await _service.deleteOpportunity(id);
      final updated = state.opportunities.where((o) => o.id != id).toList();
      state = state.copyWith(opportunities: updated, total: state.total - 1);
      return true;
    } on ApiException catch (e) {
      debugPrint('Delete error: ${e.error.message}');
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Delete error: $e');
      state = state.copyWith(error: 'Failed to delete Kolab');
      return false;
    }
  }

  void _replaceInList(String id, Opportunity updated) {
    final list = state.opportunities.map((o) {
      if (o.id == id) return updated;
      return o;
    }).toList();
    state = state.copyWith(
      opportunities: list,
      requiresSubscription: false,
      clearError: true,
    );
  }
}

final myOpportunitiesProvider =
    NotifierProvider<MyOpportunitiesNotifier, OpportunityListState>(
      MyOpportunitiesNotifier.new,
    );

// =============================================================================
// Single Opportunity Detail
// =============================================================================

final opportunityDetailProvider = FutureProvider.family<Opportunity, String>((
  ref,
  id,
) async {
  final service = ref.watch(opportunityServiceProvider);
  return service.getOpportunity(id);
});
