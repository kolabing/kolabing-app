import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/services/auth_service.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../../opportunity/models/opportunity.dart';

// =============================================================================
// Service Provider
// =============================================================================

final applicationServiceProvider = Provider<ApplicationService>(
  (ref) => ApplicationService(),
);

// =============================================================================
// Applications List State
// =============================================================================

@immutable
class ApplicationsState {
  const ApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<Application> applications;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get isEmpty => applications.isEmpty && !isLoading;
  bool get hasData => applications.isNotEmpty;
  bool get hasMore => currentPage < lastPage;

  int get pendingCount =>
      applications.where((a) => a.status.isPending).length;

  int get totalUnreadCount =>
      applications.fold(0, (sum, a) => sum + a.unreadCount);

  ApplicationsState copyWith({
    List<Application>? applications,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    bool clearError = false,
  }) =>
      ApplicationsState(
        applications: applications ?? this.applications,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        total: total ?? this.total,
      );
}

// =============================================================================
// My Applications Provider (Sent applications)
// =============================================================================

class MyApplicationsNotifier extends Notifier<ApplicationsState> {
  late ApplicationService _service;

  @override
  ApplicationsState build() {
    _service = ref.read(applicationServiceProvider);
    Future.microtask(() => load());
    return const ApplicationsState(isLoading: true);
  }

  Future<void> load({String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getMyApplications(
        status: status,
        page: 1,
      );
      state = ApplicationsState(
        applications: response.data,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      debugPrint('Load applications error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _service.getMyApplications(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        applications: [...state.applications, ...response.data],
        isLoading: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      debugPrint('Load more applications error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> refresh() => load();

  Future<Application?> submitApplication({
    required Opportunity opportunity,
    required String message,
    required String availability,
  }) async {
    try {
      final application = await _service.submitApplication(
        opportunityId: opportunity.id ?? '',
        message: message,
        availability: availability,
      );

      // Add to local list
      state = state.copyWith(
        applications: [application, ...state.applications],
        total: state.total + 1,
      );

      return application;
    } catch (e) {
      debugPrint('Submit application error: $e');
      rethrow; // Rethrow to let UI handle it
    }
  }

  Future<bool> withdrawApplication(String id) async {
    try {
      await _service.withdrawApplication(id);
      // Update local list
      final applications = state.applications.map((a) {
        if (a.id == id) {
          return a.copyWith(status: ApplicationStatus.withdrawn);
        }
        return a;
      }).toList();
      state = state.copyWith(applications: applications);
      return true;
    } catch (e) {
      debugPrint('Withdraw application error: $e');
      return false;
    }
  }

  void updateApplication(Application updated) {
    final applications = state.applications.map((a) {
      if (a.id == updated.id) return updated;
      return a;
    }).toList();
    state = state.copyWith(applications: applications);
  }

  String _getErrorMessage(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

final myApplicationsProvider =
    NotifierProvider<MyApplicationsNotifier, ApplicationsState>(
        MyApplicationsNotifier.new);

// =============================================================================
// Received Applications Provider (For opportunity owners)
// =============================================================================

class ReceivedApplicationsNotifier extends Notifier<ApplicationsState> {
  late ApplicationService _service;

  @override
  ApplicationsState build() {
    _service = ref.read(applicationServiceProvider);
    Future.microtask(() => load());
    return const ApplicationsState(isLoading: true);
  }

  Future<void> load({String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getReceivedApplications(
        status: status,
        page: 1,
      );
      state = ApplicationsState(
        applications: response.data,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      debugPrint('Load received applications error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _service.getReceivedApplications(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        applications: [...state.applications, ...response.data],
        isLoading: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (e) {
      debugPrint('Load more received applications error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> refresh() => load();

  Future<bool> acceptApplication(String id) async {
    try {
      final updated = await _service.acceptApplication(id);
      // Update local list
      final applications = state.applications.map((a) {
        if (a.id == id) return updated;
        return a;
      }).toList();
      state = state.copyWith(applications: applications);
      return true;
    } catch (e) {
      debugPrint('Accept application error: $e');
      return false;
    }
  }

  Future<bool> declineApplication(String id, {String? reason}) async {
    try {
      final updated = await _service.declineApplication(id, reason: reason);
      // Update local list
      final applications = state.applications.map((a) {
        if (a.id == id) return updated;
        return a;
      }).toList();
      state = state.copyWith(applications: applications);
      return true;
    } catch (e) {
      debugPrint('Decline application error: $e');
      return false;
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

final receivedApplicationsProvider =
    NotifierProvider<ReceivedApplicationsNotifier, ApplicationsState>(
        ReceivedApplicationsNotifier.new);

// =============================================================================
// Single Application Detail Provider
// =============================================================================

final applicationDetailProvider =
    FutureProvider.family<Application?, String>((ref, id) async {
  final service = ref.watch(applicationServiceProvider);
  try {
    return await service.getApplication(id);
  } on AuthException {
    rethrow;
  } catch (e) {
    debugPrint('Get application detail error: $e');
    return null;
  }
});

// =============================================================================
// Chat State
// =============================================================================

@immutable
class ChatState {
  const ChatState({
    this.application,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final Application? application;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => messages.isEmpty && !isLoading;

  ChatState copyWith({
    Application? application,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? lastPage,
    int? total,
  }) =>
      ChatState(
        application: application ?? this.application,
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : (error ?? this.error),
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        total: total ?? this.total,
      );
}

/// Chat data provider - loads application details for chat
final chatDataProvider =
    FutureProvider.autoDispose.family<Application?, String>((ref, applicationId) async {
  final service = ref.read(applicationServiceProvider);
  try {
    final application = await service.getApplication(applicationId);
    // Mark messages as read when opening chat
    await service.markAsRead(applicationId);
    // Invalidate unread count to refresh badge
    ref.invalidate(unreadMessagesCountProvider);
    return application;
  } on AuthException {
    rethrow;
  } catch (e) {
    debugPrint('Load chat error: $e');
    return null;
  }
});

// =============================================================================
// Chat Messages Provider (Paginated)
// =============================================================================

/// Chat messages notifier for managing chat state with pagination
class ChatMessagesNotifier extends Notifier<ChatState> {
  String? _applicationId;

  @override
  ChatState build() {
    return const ChatState(isLoading: true);
  }

  ApplicationService get _service => ref.read(applicationServiceProvider);

  /// Load initial messages
  Future<void> load(String applicationId) async {
    _applicationId = applicationId;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getMessages(
        applicationId: applicationId,
        page: 1,
      );

      // Mark messages as read
      await _service.markAsRead(applicationId);
      ref.invalidate(unreadMessagesCountProvider);

      state = ChatState(
        messages: response.data.reversed.toList(), // Reverse for chronological order
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on Exception catch (e) {
      debugPrint('Load messages error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Load older messages (pagination)
  Future<void> loadMore() async {
    final applicationId = _applicationId;
    if (applicationId == null) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _service.getMessages(
        applicationId: applicationId,
        page: state.currentPage + 1,
      );

      // Prepend older messages (reversed for chronological order)
      state = state.copyWith(
        messages: [...response.data.reversed, ...state.messages],
        isLoadingMore: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on Exception catch (e) {
      debugPrint('Load more messages error: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Send a new message
  Future<ChatMessage?> sendMessage(String content) async {
    final applicationId = _applicationId;
    if (applicationId == null) return null;
    if (state.isSending) return null;

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final message = await _service.sendMessage(
        applicationId: applicationId,
        content: content,
      );

      // Add message to the end of the list
      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
        total: state.total + 1,
      );

      return message;
    } on Exception catch (e) {
      debugPrint('Send message error: $e');
      state = state.copyWith(
        isSending: false,
        error: _getErrorMessage(e),
      );
      return null;
    }
  }

  /// Mark all messages as read
  Future<void> markAsRead() async {
    final applicationId = _applicationId;
    if (applicationId == null) return;

    try {
      await _service.markAsRead(applicationId);
      ref.invalidate(unreadMessagesCountProvider);

      // Update local message states
      final updatedMessages = state.messages.map((ChatMessage m) {
        if (!m.isOwn && !m.isRead) {
          return m.copyWith(isRead: true, readAt: DateTime.now());
        }
        return m;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } on Exception catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Add a message received from external source (e.g., push notification)
  void addMessage(ChatMessage message) {
    if (!state.messages.any((m) => m.id == message.id)) {
      state = state.copyWith(
        messages: [...state.messages, message],
        total: state.total + 1,
      );
    }
  }

  /// Refresh messages
  Future<void> refresh() {
    final applicationId = _applicationId;
    if (applicationId == null) return Future.value();
    return load(applicationId);
  }

  String _getErrorMessage(Exception e) =>
      e.toString().replaceAll('Exception: ', '');
}

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, ChatState>(ChatMessagesNotifier.new);

// =============================================================================
// Unread Messages Count Provider
// =============================================================================

final unreadMessagesCountProvider =
    FutureProvider.autoDispose<UnreadMessagesCount>((ref) async {
  final service = ref.read(applicationServiceProvider);
  try {
    return await service.getUnreadMessagesCount();
  } catch (e) {
    debugPrint('Get unread count error: $e');
    return const UnreadMessagesCount(total: 0, byApplication: {});
  }
});

/// Provider to get unread count for a specific application
final applicationUnreadCountProvider =
    Provider.family<int, String>((ref, applicationId) {
  final asyncCount = ref.watch(unreadMessagesCountProvider);
  return asyncCount.maybeWhen(
    data: (count) => count.getCountForApplication(applicationId),
    orElse: () => 0,
  );
});

/// Provider to get total unread count
final totalUnreadCountProvider = Provider<int>((ref) {
  final asyncCount = ref.watch(unreadMessagesCountProvider);
  return asyncCount.maybeWhen(
    data: (count) => count.total,
    orElse: () => 0,
  );
});
