import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/providers/event_provider.dart';
import 'package:kolabing_app/features/event/screens/event_detail_screen.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  testWidgets(
    'loads read-only event detail when the event is not in the owner cache and hides delete controls',
    (tester) async {
      final event = _testEvent();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith(
              () => _FakeEventsNotifier(const EventsState(events: [])),
            ),
            eventServiceProvider.overrideWith(
              (ref) => _FakeEventService(event),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EventDetailScreen(eventId: 'event-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Public Event'), findsOneWidget);
      expect(find.text('DELETE EVENT'), findsNothing);
    },
  );

  testWidgets(
    'keeps delete controls hidden for read-only event detail when the owner cache is warm',
    (tester) async {
      final event = _testEvent();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith(
              () => _FakeEventsNotifier(EventsState(events: [event])),
            ),
            eventServiceProvider.overrideWith(
              (ref) => _FakeEventService(event),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EventDetailScreen(eventId: 'event-1', isReadOnly: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Public Event'), findsOneWidget);
      expect(find.text('DELETE EVENT'), findsNothing);
    },
  );
}

class _FakeEventsNotifier extends EventsNotifier {
  _FakeEventsNotifier(this._initialState);

  final EventsState _initialState;

  @override
  EventsState build() => _initialState;
}

class _FakeEventService extends EventService {
  _FakeEventService(this.event);

  final Event event;

  @override
  Future<Event> getEvent(String eventId) async => event;
}

Event _testEvent() => Event(
  id: 'event-1',
  name: 'Public Event',
  partner: const EventPartner(
    id: 'partner-1',
    name: 'Cafe Sol',
    type: PartnerType.business,
  ),
  date: DateTime(2026, 7, 1),
  attendeeCount: 160,
  photos: const [
    EventPhoto(id: 'photo-1', url: 'https://example.com/photo.jpg'),
  ],
  createdAt: DateTime(2026, 7, 1),
);
