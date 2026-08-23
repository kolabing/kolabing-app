import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../models/discovered_event.dart';
import '../services/discovery_service.dart';

/// Provider for DiscoveryService
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return DiscoveryService(authService: authService);
});

// =============================================================================
// Discovery Parameters
// =============================================================================

// =============================================================================
// Discovery State Provider (city-based + optional geo)
// =============================================================================

/// Allowed values for the discover `date` range filter (#5). `upcoming` (the
/// default) maps to no `date` param — all future events.
class DiscoveryDateRange {
  DiscoveryDateRange._();
  static const String upcoming = 'upcoming';
  static const String today = 'today';
  static const String week = 'week';
  static const String weekend = 'weekend';
  static const String month = 'month';
}

/// State for event discovery. Discovery is **city-based** (NF-19): a city is
/// selected (defaulting to the attendee's own) and the list re-queries on city,
/// the `date` range, and `community_type` filter changes. Geo (lat/lng) is kept
/// as an optional alternative the home screen can supply.
class DiscoveryState {
  const DiscoveryState({
    this.latitude,
    this.longitude,
    this.radiusKm = 10.0,
    this.cityId,
    this.cityName,
    this.dateRange = DiscoveryDateRange.upcoming,
    this.typeSlug,
    this.typeName,
    this.following = false,
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final String? cityId;
  final String? cityName;

  /// One of [DiscoveryDateRange]. `upcoming` = no `date` param (all future).
  final String dateRange;
  final String? typeSlug;
  final String? typeName;

  /// The feed's scope (#142): false = the city feed, true = only the
  /// communities the viewer follows.
  final bool following;

  final List<DiscoveredEvent> events;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasCity => cityId != null && cityId!.isNotEmpty;

  /// Whether the notifier has enough context to query (a city, a geo fix, or
  /// the Following scope — which needs neither).
  bool get canQuery => hasCity || hasLocation || following;

  DiscoveryState copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? cityId,
    String? cityName,
    String? dateRange,
    String? typeSlug,
    String? typeName,
    bool clearType = false,
    bool? following,
    List<DiscoveredEvent>? events,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) => DiscoveryState(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusKm: radiusKm ?? this.radiusKm,
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    dateRange: dateRange ?? this.dateRange,
    typeSlug: clearType ? null : (typeSlug ?? this.typeSlug),
    typeName: clearType ? null : (typeName ?? this.typeName),
    following: following ?? this.following,
    events: events ?? this.events,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

/// Notifier for discovery with location and pagination
class DiscoveryNotifier extends Notifier<DiscoveryState>
    with AuthScopeGuard<DiscoveryState> {
  int _activeRequestGeneration = 0;

  @override
  DiscoveryState build() {
    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: _reloadWithCurrentLocation,
        onSessionInvalidated: _invalidateActiveRequests,
      );
    });
    return const DiscoveryState();
  }

  DiscoveryService get _service => ref.read(discoveryServiceProvider);

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const DiscoveryState();
  }

  Future<void> _reloadWithCurrentLocation() async {
    if (!state.canQuery) {
      return;
    }

    await _fetchEvents();
  }

  // ---------------------------------------------------------------------------
  // City-based discovery (NF-19)
  // ---------------------------------------------------------------------------

  /// Select the city to discover events in (defaults to the attendee's own at
  /// home init) and (re)fetch the first page.
  Future<void> setCityAndDiscover(String cityId, String cityName) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }

    state = state.copyWith(
      cityId: cityId,
      cityName: cityName,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Switch the feed between the city scope and Following (#142).
  ///
  /// The city selection is deliberately KEPT while Following is on, so turning
  /// it off puts the attendee back on the city they were browsing instead of
  /// making them pick again. The city is simply not SENT while following: a
  /// community you follow is worth knowing about wherever it is, and a feed
  /// labelled Barcelona showing events in three cities would be a lie.
  Future<void> setFollowing(bool following) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (state.following == following) return;

    state = state.copyWith(
      following: following,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Set the `date` range filter (#5). One of [DiscoveryDateRange].
  Future<void> setDateRange(String dateRange) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (!state.canQuery) return;
    if (state.dateRange == dateRange) return;

    state = state.copyWith(
      dateRange: dateRange,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Set (or clear, when [typeSlug] is null) the community-type filter.
  Future<void> setTypeFilter({String? typeSlug, String? typeName}) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (!state.canQuery) return;

    state = state.copyWith(
      typeSlug: typeSlug,
      typeName: typeName,
      clearType: typeSlug == null,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Set location and fetch events
  Future<void> setLocationAndDiscover(
    double lat,
    double lng, {
    double? radiusKm,
  }) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }

    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      radiusKm: radiusKm,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Update search radius
  Future<void> updateRadius(double radiusKm) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (!state.hasLocation) return;

    state = state.copyWith(
      radiusKm: radiusKm,
      isLoading: true,
      error: null,
      events: [],
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  /// Load more events (pagination)
  Future<void> loadMore() async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (!state.canQuery || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, currentPage: state.currentPage + 1);

    await _fetchEvents(append: true);
  }

  /// Refresh events
  Future<void> refresh() async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (!state.canQuery) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  Future<void> _fetchEvents({bool append = false}) async {
    final requestGeneration = ++_activeRequestGeneration;
    final sessionVersion = activeAuthSessionVersion;

    try {
      // Following wins outright (#142): it asks about a relationship, so no
      // place filter applies and the type filter is meaningless — you already
      // know who you follow. Otherwise city mode takes precedence (NF-19) and
      // geo is used only when no city is selected. `date` composes with all
      // three.
      final useFollowing = state.following;
      final useCity = !useFollowing && state.hasCity;
      final useGeo = !useFollowing && !useCity;
      final response = await _service.discoverEvents(
        latitude: useGeo ? state.latitude : null,
        longitude: useGeo ? state.longitude : null,
        radiusKm: state.radiusKm,
        cityId: useCity ? state.cityId : null,
        following: useFollowing,
        // `upcoming` is the default (no `date` param → all future events).
        date: state.dateRange == DiscoveryDateRange.upcoming
            ? null
            : state.dateRange,
        typeSlug: useFollowing ? null : state.typeSlug,
        page: state.currentPage,
      );

      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }

      final events = append
          ? [...state.events, ...response.events]
          : response.events;

      state = state.copyWith(
        events: events,
        isLoading: false,
        hasMore: response.hasMore,
      );
    } on DiscoveryException catch (e) {
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to discover events',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for discovery with location management
final discoveryProvider = NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);
