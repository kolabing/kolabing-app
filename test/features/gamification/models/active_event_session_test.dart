import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/active_event_session.dart';
import 'package:kolabing_app/features/gamification/models/event_checkin.dart';
import 'package:shared_preferences/shared_preferences.dart';

EventCheckin _checkin({
  String eventId = 'evt-1',
  String? eventName = 'Sunset Run',
}) => EventCheckin(
  id: 'chk-1',
  eventId: eventId,
  profileId: 'me',
  checkedInAt: DateTime.utc(2026, 8, 22, 18),
  createdAt: DateTime.utc(2026, 8, 22, 18),
  eventName: eventName,
  pointsEarned: 5,
);

void main() {
  group('ActiveEventSession', () {
    test('is live right after check-in and expired after the TTL', () {
      final now = DateTime.utc(2026, 8, 22, 18);
      final session = ActiveEventSession.fromCheckin(_checkin(), now: now);

      expect(session.isExpiredAt(now), isFalse);
      expect(session.isExpiredAt(now.add(const Duration(hours: 11))), isFalse);
      expect(session.isExpiredAt(now.add(const Duration(hours: 13))), isTrue);
    });

    test('carries the event id and name from the check-in', () {
      final session = ActiveEventSession.fromCheckin(_checkin());

      expect(session.eventId, 'evt-1');
      expect(session.eventName, 'Sunset Run');
    });

    test('survives a JSON round-trip', () {
      final session = ActiveEventSession.fromCheckin(_checkin());

      final restored = ActiveEventSession.fromJson(session.toJson());

      expect(restored, isNotNull);
      expect(restored!.eventId, session.eventId);
      expect(restored.eventName, session.eventName);
      expect(restored.expiresAt, session.expiresAt);
    });

    test('returns null for malformed JSON instead of throwing', () {
      expect(ActiveEventSession.fromJson(const {}), isNull);
      expect(ActiveEventSession.fromJson(const {'event_id': 'x'}), isNull);
      expect(
        ActiveEventSession.fromJson(const {
          'event_id': 'x',
          'checked_in_at': 'not-a-date',
          'expires_at': 'nope',
        }),
        isNull,
      );
    });

    test('tolerates a check-in with no event name', () {
      final session = ActiveEventSession.fromCheckin(_checkin(eventName: null));

      expect(session.eventName, isNull);
      expect(ActiveEventSession.fromJson(session.toJson()), isNotNull);
    });
  });

  group('ActiveEventSessionStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves and reads back a session', () async {
      final store = ActiveEventSessionStore();
      final session = ActiveEventSession.fromCheckin(_checkin());

      await store.save(session);

      final loaded = await store.read();
      expect(loaded?.eventId, 'evt-1');
    });

    test('drops an expired session on read', () async {
      final store = ActiveEventSessionStore();
      final stale = ActiveEventSession.fromCheckin(
        _checkin(),
        now: DateTime.now().subtract(const Duration(hours: 20)),
      );

      await store.save(stale);

      expect(await store.read(), isNull);
    });

    test('read returns null when nothing was ever saved', () async {
      expect(await ActiveEventSessionStore().read(), isNull);
    });

    test('read returns null when the stored value is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        ActiveEventSessionStore.storageKey: 'not json',
      });

      expect(await ActiveEventSessionStore().read(), isNull);
    });

    test('clear removes the session', () async {
      final store = ActiveEventSessionStore();
      await store.save(ActiveEventSession.fromCheckin(_checkin()));

      await store.clear();

      expect(await store.read(), isNull);
    });
  });
}
