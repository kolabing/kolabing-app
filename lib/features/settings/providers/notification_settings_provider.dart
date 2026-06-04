import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/models/notification_preferences.dart';
import '../../business/providers/profile_provider.dart';

/// Notification preferences for the current account (NF-16 B3).
///
/// Bound to `GET`/`PUT /me/notification-preferences` (shared across roles).
/// Notifier (not FutureProvider) so a toggle writes through and re-emits state
/// directly — the NF-6 refresh pattern
/// (docs/tickets/2026-06-04-tier-instant-refresh-bug.md).
class NotificationSettingsNotifier
    extends Notifier<AsyncValue<NotificationPreferences>> {
  @override
  AsyncValue<NotificationPreferences> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(profileServiceProvider).getNotificationPreferences());
  }

  /// Persist one toggle. Optimistically reflects the new value, then writes the
  /// full prefs map and re-emits the backend's canonical result. On failure,
  /// reverts to the previous value and rethrows so the UI can surface it.
  Future<void> setPreference(NotificationPreferences updated) async {
    final previous = state;
    state = AsyncData(updated);
    try {
      final saved = await ref
          .read(profileServiceProvider)
          .updateNotificationPreferences(_payload(updated));
      state = AsyncData(saved);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Map<String, bool> _payload(NotificationPreferences p) => {
        'message_notifications': p.messagesEnabled,
        'messages_enabled': p.messagesEnabled,
        'new_application_alerts': p.applicationsEnabled,
        'applications_enabled': p.applicationsEnabled,
        'collaboration_updates': p.collaborationsEnabled,
        'collaborations_enabled': p.collaborationsEnabled,
        'marketing_tips': p.marketingEnabled,
        'marketing_enabled': p.marketingEnabled,
      };
}

final notificationSettingsProvider = NotifierProvider<
    NotificationSettingsNotifier,
    AsyncValue<NotificationPreferences>>(NotificationSettingsNotifier.new);
