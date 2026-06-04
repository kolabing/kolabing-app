import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/chat_thread.dart';
import '../services/chat_service.dart';

/// DI for [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ChatService(authService: authService);
});

/// The viewer's chat threads (role-scoped by the backend).
///
/// Notifier (not FutureProvider) so `reload()` sets state directly and the
/// list refreshes reliably — see the NF-6 refresh lesson in
/// docs/tickets/2026-06-04-tier-instant-refresh-bug.md.
class ChatThreadsNotifier extends Notifier<AsyncValue<List<ChatThread>>> {
  @override
  AsyncValue<List<ChatThread>> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(chatServiceProvider).getThreads());
  }
}

final chatThreadsProvider =
    NotifierProvider<ChatThreadsNotifier, AsyncValue<List<ChatThread>>>(
        ChatThreadsNotifier.new);

/// Total unread message count — feeds the app-bar inbox badge.
class ChatUnreadNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(refresh);
    return 0;
  }

  Future<void> refresh() async {
    try {
      state = await ref.read(chatServiceProvider).getUnreadCount();
    } catch (_) {
      // Keep the last known count on a transient failure.
    }
  }
}

final chatUnreadProvider =
    NotifierProvider<ChatUnreadNotifier, int>(ChatUnreadNotifier.new);
