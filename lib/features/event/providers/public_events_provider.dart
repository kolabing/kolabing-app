import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../models/public_event.dart';
import 'event_provider.dart';

/// Immutable state for the attendee public-events (Explore) feed.
@immutable
class PublicEventsState {
  const PublicEventsState({
    this.events = const <PublicEvent>[],
    this.currentPage = 0,
    this.totalPages = 1,
    this.totalCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<PublicEvent> events;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => currentPage < totalPages;
  bool get isEmpty => events.isEmpty && !isLoading;

  PublicEventsState copyWith({
    List<PublicEvent>? events,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) => PublicEventsState(
    events: events ?? this.events,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Loads + paginates `GET /events/discovery` (Batch 3). Auth-scoped: clears on
/// sign-out and ignores stale completions across session changes (matches the
/// existing discovery/event notifiers).
class PublicEventsNotifier extends Notifier<PublicEventsState>
    with AuthScopeGuard<PublicEventsState> {
  int _activeRequestGeneration = 0;

  @override
  PublicEventsState build() {
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
        loadAuthenticatedData: _load,
      );
    });

    return const PublicEventsState(isLoading: true);
  }

  void _invalidateActiveRequests() {
    _activeRequestGeneration++;
  }

  void _clearSignedOutState() {
    state = const PublicEventsState();
  }

  Future<void> _load() async {
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
      final page = await ref.read(eventServiceProvider).getDiscovery(page: 1);
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = PublicEventsState(
        events: page.events,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
      );
    } on AuthException catch (e) {
      if (_isStale(requestGeneration)) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } on ApiException catch (e) {
      if (_isStale(requestGeneration)) return;
      state = state.copyWith(isLoading: false, error: e.error.message);
    } on NetworkException catch (e) {
      if (_isStale(requestGeneration)) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception {
      if (_isStale(requestGeneration)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load public events',
      );
    }
  }

  bool _isStale(int generation) => generation != _activeRequestGeneration;

  Future<void> refresh() => _load();

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
      final page = await ref
          .read(eventServiceProvider)
          .getDiscovery(page: state.currentPage + 1);
      if (requestGeneration != _activeRequestGeneration ||
          isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        events: <PublicEvent>[...state.events, ...page.events],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
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

  /// Optimistically bump the local going-count for [eventId] after a successful
  /// RSVP from a discovery card, so the feed reflects the change without a
  /// full reload.
  void markGoing(String eventId) {
    state = state.copyWith(
      events: <PublicEvent>[
        for (final e in state.events)
          if (e.id == eventId)
            PublicEvent(
              id: e.id,
              name: e.name,
              partnerName: e.partnerName,
              date: e.date,
              startsAt: e.startsAt,
              endsAt: e.endsAt,
              visibility: e.visibility,
              location: e.location,
              address: e.address,
              capacity: e.capacity,
              goingCount: e.goingCount + 1,
              photos: e.photos,
              community: e.community,
            )
          else
            e,
      ],
    );
  }
}

final publicEventsProvider =
    NotifierProvider<PublicEventsNotifier, PublicEventsState>(
      PublicEventsNotifier.new,
    );
