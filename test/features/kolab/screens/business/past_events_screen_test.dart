import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/providers/event_provider.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/business/past_events_screen.dart';

void main() {
  testWidgets('imports a profile event into kolab past collaborations', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        eventsProvider.overrideWith(
          () => _FakeEventsNotifier(
            EventsState(events: [_testEvent()]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PastEventsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Select from profile'), findsOneWidget);

    await tester.tap(find.text('Select from profile'));
    await tester.pumpAndSettle();

    expect(find.text('Wellness Rooftop'), findsOneWidget);

    await tester.tap(find.text('Wellness Rooftop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import events'));
    await tester.pumpAndSettle();

    final imported = container.read(kolabFormProvider).kolab.pastEvents;
    expect(imported, hasLength(1));
    expect(imported.first.name, 'Wellness Rooftop');
    expect(imported.first.partnerName, 'Run Club');
  });
}

class _FakeEventsNotifier extends EventsNotifier {
  _FakeEventsNotifier(this._initialState);

  final EventsState _initialState;

  @override
  EventsState build() => _initialState;
}

Event _testEvent() => Event(
  id: 'event-1',
  name: 'Wellness Rooftop',
  partner: const EventPartner(
    name: 'Run Club',
    type: PartnerType.community,
  ),
  date: DateTime(2026, 5, 1),
  attendeeCount: 120,
  photos: const [],
  createdAt: DateTime(2026, 5, 1),
);
