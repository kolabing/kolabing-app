import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../models/event.dart';
import '../services/event_service.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return EventService(authService: authService);
});

/// State for the events list
class EventsState {
  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Event> events;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int totalCount;

  EventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? totalCount,
  }) =>
      EventsState(
        events: events ?? this.events,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        totalCount: totalCount ?? this.totalCount,
      );
}

/// Notifier for managing events state
class EventsNotifier extends Notifier<EventsState> with AuthScopeGuard<EventsState> {
  late final EventService _service;
  int _activeRequestGeneration = 0;

  @override
  EventsState build() {
    _service = ref.read(eventServiceProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: loadEvents,
        onSessionInvalidated: _invalidateActiveRequests,
      );
    });
    Future.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: loadEvents,
      );
    });
    return const EventsState();
  }

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const EventsState();
  }

  /// Load initial events
  Future<void> loadEvents({String? profileId}) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (state.isLoading) return;
    final requestGeneration = ++_activeRequestGeneration;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.getEvents(
        page: 1,
        profileId: profileId,
      );
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        events: result.events,
        isLoading: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } on AuthException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } on ApiException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.error.message,
      );
    } on NetworkException catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more events (pagination)
  Future<void> loadMoreEvents({String? profileId}) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final requestGeneration = _activeRequestGeneration;

    try {
      final nextPage = state.currentPage + 1;
      final result = await _service.getEvents(
        page: nextPage,
        profileId: profileId,
      );
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }

      state = state.copyWith(
        events: [...state.events, ...result.events],
        isLoadingMore: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh events
  Future<void> refresh({String? profileId}) async {
    if (!ensureAuthenticatedUser(
      clearSignedOutState: _clearSignedOutState,
      onUnauthenticated: _invalidateActiveRequests,
    )) {
      return;
    }
    final requestGeneration = ++_activeRequestGeneration;
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMore: true,
    );

    try {
      final result = await _service.getEvents(
        page: 1,
        profileId: profileId,
      );
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        events: result.events,
        isLoading: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } catch (e) {
      if (requestGeneration != _activeRequestGeneration) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new event
  Future<bool> addEvent(EventCreateRequest request) async {
    try {
      final newEvent = await _service.createEvent(request);
      final updated = [newEvent, ...state.events];
      state = state.copyWith(
        events: updated,
        totalCount: updated.length,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _service.deleteEvent(eventId);
      final updated = state.events.where((e) => e.id != eventId).toList();
      state = state.copyWith(
        events: updated,
        totalCount: updated.length,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for events state (current user's events)
final eventsProvider =
    NotifierProvider<EventsNotifier, EventsState>(EventsNotifier.new);

final eventDetailProvider =
    FutureProvider.family<Event, String>((ref, eventId) async {
  final service = ref.watch(eventServiceProvider);
  return service.getEvent(eventId);
});

/// Provider for loading another user's events by profile ID (read-only)
final profileEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, profileId) async {
  final service = ref.watch(eventServiceProvider);
  final result = await service.getEvents(profileId: profileId);
  return result.events;
});
