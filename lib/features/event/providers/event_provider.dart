import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../services/event_service.dart';

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
class EventsNotifier extends Notifier<EventsState> {
  late final EventService _service;

  @override
  EventsState build() {
    _service = EventService();
    // Auto-load events on initialization
    Future.microtask(() => loadEvents());
    return const EventsState();
  }

  /// Load initial events
  Future<void> loadEvents({String? profileId}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.getEvents(
        page: 1,
        profileId: profileId,
      );
      state = state.copyWith(
        events: result.events,
        isLoading: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more events (pagination)
  Future<void> loadMoreEvents({String? profileId}) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _service.getEvents(
        page: nextPage,
        profileId: profileId,
      );

      state = state.copyWith(
        events: [...state.events, ...result.events],
        isLoadingMore: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh events
  Future<void> refresh({String? profileId}) async {
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
      state = state.copyWith(
        events: result.events,
        isLoading: false,
        currentPage: result.pagination.currentPage,
        hasMore: result.pagination.hasMore,
        totalCount: result.pagination.totalCount,
      );
    } catch (e) {
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

/// Provider for loading another user's events by profile ID (read-only)
final profileEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, profileId) async {
  final service = EventService();
  final result = await service.getEvents(profileId: profileId);
  return result.events;
});
