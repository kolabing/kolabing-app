import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/utils/auth_scope_guard.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

// =============================================================================
// Service Provider
// =============================================================================

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(authService: ref.watch(authServiceProvider)),
);

// =============================================================================
// Notification State
// =============================================================================

@immutable
class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.unreadCount = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int unreadCount;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get isEmpty => notifications.isEmpty && !isLoading;
  bool get hasUnread => unreadCount > 0;
  bool get hasMore => currentPage < lastPage;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? unreadCount,
    int? currentPage,
    int? lastPage,
    int? total,
  }) => NotificationState(
    notifications: notifications ?? this.notifications,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : (error ?? this.error),
    unreadCount: unreadCount ?? this.unreadCount,
    currentPage: currentPage ?? this.currentPage,
    lastPage: lastPage ?? this.lastPage,
    total: total ?? this.total,
  );
}

// =============================================================================
// Notification Notifier
// =============================================================================

class NotificationNotifier extends Notifier<NotificationState>
    with AuthScopeGuard<NotificationState> {
  late NotificationService _service;

  @override
  NotificationState build() {
    _service = ref.read(notificationServiceProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: loadUnreadCount,
      );
    });
    Future.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: loadUnreadCount,
      );
    });
    return const NotificationState();
  }

  void _clearSignedOutState() {
    state = const NotificationState();
  }

  /// Load unread notification count (for badge display)
  Future<void> loadUnreadCount() async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }

    final sessionVersion = activeAuthSessionVersion;
    try {
      final count = await _service.getUnreadCount();
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      debugPrint('Load unread count error: $e');
    }
  }

  /// Load first page of notifications
  Future<void> loadNotifications() async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }
    if (state.isLoading) return;
    final sessionVersion = activeAuthSessionVersion;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getNotifications(page: 1);
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      final unreadCount = response.data.where((n) => !n.isRead).length;
      state = NotificationState(
        notifications: response.data,
        unreadCount: unreadCount,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      debugPrint('Load notifications error: $e');
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  /// Load next page of notifications (infinite scroll)
  Future<void> loadMore() async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final sessionVersion = activeAuthSessionVersion;

    try {
      final response = await _service.getNotifications(
        page: state.currentPage + 1,
      );
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        notifications: [...state.notifications, ...response.data],
        isLoadingMore: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      debugPrint('Load more notifications error: $e');
      state = state.copyWith(isLoadingMore: false, error: _getErrorMessage(e));
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }
    try {
      await _service.markAsRead(notificationId);

      final updated = state.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      final unreadCount = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unreadCount);
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }
    try {
      await _service.markAllAsRead();

      final now = DateTime.now();
      final updated = state.notifications.map((n) {
        if (!n.isRead) {
          return n.copyWith(isRead: true, readAt: now);
        }
        return n;
      }).toList();

      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> refresh() => loadNotifications();

  String _getErrorMessage(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

// =============================================================================
// Providers
// =============================================================================

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

/// Convenience provider for just the unread count (for badge display)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
