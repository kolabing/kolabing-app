import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/active_event_session.dart';
import '../models/event_checkin.dart';

/// The store, injectable so widget tests can supply a fake.
final activeEventSessionStoreProvider = Provider<ActiveEventSessionStore>(
  (ref) => const ActiveEventSessionStore(),
);

/// The event this device is currently checked in to, or `null`.
///
/// Seeded by a check-in scan and read by the peer-pairing flow to decide whose
/// challenges to list. Persisted, so backgrounding the app mid-event does not
/// lose the context.
class ActiveEventSessionNotifier extends Notifier<ActiveEventSession?> {
  @override
  ActiveEventSession? build() {
    // Restoring from disk is async while build() is not, so start with no
    // session and fill it in when the read lands. Every consumer already
    // handles the null ("check in first") case, so there is no wrong state to
    // show in between.
    Future.microtask(restore);
    return null;
  }

  ActiveEventSessionStore get _store =>
      ref.read(activeEventSessionStoreProvider);

  /// Loads the persisted session, if any is still live.
  Future<void> restore() async {
    try {
      final session = await _store.read();
      if (session != null) state = session;
    } on Object catch (e) {
      debugPrint('active_event_session: restore failed: $e');
    }
  }

  /// Opens a session from a successful check-in.
  Future<void> start(EventCheckin checkin) async {
    final session = ActiveEventSession.fromCheckin(checkin);
    state = session;
    try {
      await _store.save(session);
    } on Object catch (e) {
      // A failed write only costs persistence across restarts; the in-memory
      // session still drives this sitting.
      debugPrint('active_event_session: save failed: $e');
    }
  }

  /// Opens a session for an event we already know, with no check-in payload.
  /// See [ActiveEventSession.forEvent].
  Future<void> startForEvent({
    required String eventId,
    String? eventName,
  }) async {
    final session = ActiveEventSession.forEvent(
      eventId: eventId,
      eventName: eventName,
    );
    state = session;
    try {
      await _store.save(session);
    } on Object catch (e) {
      debugPrint('active_event_session: save failed: $e');
    }
  }

  /// Ends the session (left the event, logged out, or it expired).
  Future<void> clear() async {
    state = null;
    try {
      await _store.clear();
    } on Object catch (e) {
      debugPrint('active_event_session: clear failed: $e');
    }
  }
}

final activeEventSessionProvider =
    NotifierProvider<ActiveEventSessionNotifier, ActiveEventSession?>(
      ActiveEventSessionNotifier.new,
    );
