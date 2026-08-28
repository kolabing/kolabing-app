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
      () => ref.read(profileServiceProvider).getNotificationPreferences(),
    );
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
      // `events_enabled` is kept from what we just sent rather than from the
      // response. `notification_preferences` has no such column yet
      // (kolabing-v2#252), so the 200 body omits the key, `fromJson` defaults it
      // back to true, and the switch would visibly snap back on a moment after
      // the tap. Once the column ships the server echoes the same value, so
      // this stays harmless — it is a floor, not an override.
      state = AsyncData(saved.copyWith(eventsEnabled: updated.eventsEnabled));
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  /// NOTE: a hand-written whitelist, deliberately not `p.toJson()` (which also
  /// carries nullable quiet-hours/timezone strings this `Map<String, bool>`
  /// cannot hold). Adding a preference to the model is therefore NOT enough —
  /// add its wire key here too, or the toggle is a dead switch.
  Map<String, bool> _payload(NotificationPreferences p) => {
    'message_notifications': p.messagesEnabled,
    'messages_enabled': p.messagesEnabled,
    'new_application_alerts': p.applicationsEnabled,
    'applications_enabled': p.applicationsEnabled,
    'collaboration_updates': p.collaborationsEnabled,
    'collaborations_enabled': p.collaborationsEnabled,
    'marketing_tips': p.marketingEnabled,
    'marketing_enabled': p.marketingEnabled,
    'events_enabled': p.eventsEnabled,
  };
}

final notificationSettingsProvider =
    NotifierProvider<
      NotificationSettingsNotifier,
      AsyncValue<NotificationPreferences>
    >(NotificationSettingsNotifier.new);
