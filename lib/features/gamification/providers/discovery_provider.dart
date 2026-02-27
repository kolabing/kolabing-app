import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
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

/// Parameters for event discovery
class DiscoveryParams {
  const DiscoveryParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.page = 1,
    this.limit = 10,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
  final int page;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusKm == other.radiusKm &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radiusKm.hashCode ^
      page.hashCode ^
      limit.hashCode;
}

// =============================================================================
// Discover Events Provider
// =============================================================================

/// Provider for discovering nearby events
final discoverEventsProvider =
    FutureProvider.family<DiscoveredEventsResponse, DiscoveryParams>(
        (ref, params) async {
  final service = ref.watch(discoveryServiceProvider);
  return service.discoverEvents(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
    page: params.page,
    limit: params.limit,
  );
});

// =============================================================================
// Discovery State Provider (with location management)
// =============================================================================

/// State for discovery with cached location
class DiscoveryState {
  const DiscoveryState({
    this.latitude,
    this.longitude,
    this.radiusKm = 10.0,
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final List<DiscoveredEvent> events;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  bool get hasLocation => latitude != null && longitude != null;

  DiscoveryState copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<DiscoveredEvent>? events,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) =>
      DiscoveryState(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusKm: radiusKm ?? this.radiusKm,
        events: events ?? this.events,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
      );
}

/// Notifier for discovery with location and pagination
class DiscoveryNotifier extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() => const DiscoveryState();

  DiscoveryService get _service => ref.read(discoveryServiceProvider);

  /// Set location and fetch events
  Future<void> setLocationAndDiscover(double lat, double lng,
      {double? radiusKm}) async {
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
    if (!state.hasLocation || state.isLoading || !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      currentPage: state.currentPage + 1,
    );

    await _fetchEvents(append: true);
  }

  /// Refresh events
  Future<void> refresh() async {
    if (!state.hasLocation) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
    );

    await _fetchEvents();
  }

  Future<void> _fetchEvents({bool append = false}) async {
    try {
      final response = await _service.discoverEvents(
        latitude: state.latitude!,
        longitude: state.longitude!,
        radiusKm: state.radiusKm,
        page: state.currentPage,
      );

      final events =
          append ? [...state.events, ...response.events] : response.events;

      state = state.copyWith(
        events: events,
        isLoading: false,
        hasMore: response.hasMore,
      );
    } on DiscoveryException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
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
