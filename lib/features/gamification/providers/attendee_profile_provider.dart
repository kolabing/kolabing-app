import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/attendee_profile_detail.dart';
import '../services/attendee_profile_service.dart';

/// Provider for [AttendeeProfileService].
final attendeeProfileServiceProvider = Provider<AttendeeProfileService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AttendeeProfileService(authService: authService);
});

/// Rich attendee profile aggregate for a given profile id.
///
/// Used for both the self view (pass the current user's id) and the public
/// view (pass someone else's id). The screen decides which by comparing the id
/// to the authenticated user's id.
final attendeeProfileDetailProvider = FutureProvider.autoDispose
    .family<AttendeeProfileDetail, String>((ref, profileId) async {
      final service = ref.watch(attendeeProfileServiceProvider);
      return service.getAttendeeProfile(profileId);
    });

/// State for the paginated events-attended history (`/me/events-attended`).
class EventsAttendedState {
  const EventsAttendedState({
    this.events = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<AttendedEvent> events;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => currentPage > 0 && currentPage < lastPage;
  bool get isEmpty => events.isEmpty && !isLoading && error == null;

  EventsAttendedState copyWith({
    List<AttendedEvent>? events,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _sentinel,
  }) {
    return EventsAttendedState(
      events: events ?? this.events,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const Object _sentinel = Object();
}

/// Notifier driving the paginated events-attended history.
class EventsAttendedNotifier extends Notifier<EventsAttendedState> {
  static const int _perPage = 20;

  AttendeeProfileService get _service =>
      ref.read(attendeeProfileServiceProvider);

  @override
  EventsAttendedState build() => const EventsAttendedState();

  /// Load (or reload) the first page.
  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _service.getMyEventsAttended(
        page: 1,
        perPage: _perPage,
      );
      state = state.copyWith(
        events: page.events,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Append the next page, if any.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final next = state.currentPage + 1;
      final page = await _service.getMyEventsAttended(
        page: next,
        perPage: _perPage,
      );
      state = state.copyWith(
        events: [...state.events, ...page.events],
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

/// Provider for the paginated events-attended history.
final eventsAttendedProvider =
    NotifierProvider.autoDispose<EventsAttendedNotifier, EventsAttendedState>(
      EventsAttendedNotifier.new,
    );
