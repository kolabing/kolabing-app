// Guardrails for the rebuilt attendee feed (#161).
//
// The old feed's failure was not a crash: it rendered fields that carried no
// information ("0 m" on every card because city discovery sends no
// coordinates, "Community" on every card, a showcase headcount on a future
// event) and omitted the ones that did. These tests hold the new sections to
// the promises the redesign makes — a section with nothing to say renders
// nothing, "Your events" caps its preview and offers the rest, and a row says
// when and where.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/widgets/event_timeline.dart';
import 'package:kolabing_app/features/gamification/providers/my_events_provider.dart';
import 'package:kolabing_app/features/gamification/widgets/attendee_feed_sections.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Event _event({
  required String id,
  required String name,
  required DateTime startsAt,
  String? location,
  String? signupStatus,
  String hostName = 'Real Run Club',
}) => Event(
  id: id,
  name: name,
  partner: EventPartner(name: hostName, type: PartnerType.community),
  date: startsAt,
  startsAt: startsAt,
  location: location,
  mySignupStatus: signupStatus,
  attendeeCount: 12,
  photos: const [],
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Event>? myEvents,
}) async {
  tester.view.physicalSize = const Size(1179, 2556); // iPhone @3x
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (myEvents != null)
          myUpcomingEventsProvider.overrideWith((ref) async => myEvents),
      ],
      child: MaterialApp(
        theme: KolabingTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the points strip states points and events on one line', (
    tester,
  ) async {
    await _pump(
      tester,
      const AttendeePointsStrip(points: 1240, eventsAttended: 8),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1,240 points · 8 events'), findsOneWidget);
  });

  testWidgets('the points strip counts one event in the singular', (
    tester,
  ) async {
    await _pump(
      tester,
      const AttendeePointsStrip(points: 40, eventsAttended: 1),
    );

    expect(find.text('40 points · 1 event'), findsOneWidget);
  });

  testWidgets('Your events shows the next three and offers the rest', (
    tester,
  ) async {
    final today = DateTime.now();
    await _pump(
      tester,
      const YourEventsSection(),
      myEvents: [
        for (var i = 0; i < 5; i++)
          _event(
            id: 'e$i',
            name: 'Event number $i',
            startsAt: DateTime(
              today.year,
              today.month,
              today.day,
              19,
              30,
            ).add(Duration(days: i)),
          ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('YOUR EVENTS'), findsOneWidget);
    // Capped at the preview count, with the rest behind View all.
    expect(find.byType(EventTimelineRow), findsNWidgets(3));
    expect(find.text('Event number 0'), findsOneWidget);
    expect(find.text('Event number 3'), findsNothing);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('Your events drops View all when it is showing everything', (
    tester,
  ) async {
    await _pump(
      tester,
      const YourEventsSection(),
      myEvents: [
        _event(
          id: 'only',
          name: 'The only event',
          startsAt: DateTime.now().add(const Duration(days: 2)),
        ),
      ],
    );

    expect(find.byType(EventTimelineRow), findsOneWidget);
    expect(find.text('View all'), findsNothing);
  });

  testWidgets('a section with nothing to say renders nothing at all', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(children: [YourEventsSection()]),
      myEvents: const [],
    );

    expect(find.text('YOUR EVENTS'), findsNothing);
    expect(find.byType(EventTimelineRow), findsNothing);
  });

  testWidgets('a standalone row carries its own day, and names the host', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      EventTimelineRow(
        event: _event(
          id: 'e1',
          name: 'Beach 5K',
          startsAt: DateTime(now.year, now.month, now.day, 19, 30),
          location: 'Pça. de Pau Vila, 3',
          signupStatus: 'going',
        ),
        locale: 'en',
        showDay: true,
        showHost: true,
        showVisibility: false,
        onTap: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Today, 19:30'), findsOneWidget);
    expect(find.text('Pça. de Pau Vila, 3'), findsOneWidget);
    expect(find.text('Real Run Club'), findsOneWidget);
    expect(find.text('Going'), findsOneWidget);
    // Nothing on a feed row may claim a distance or a partner type again.
    expect(find.textContaining('0 m'), findsNothing);
    expect(find.text('Community'), findsNothing);
  });

  testWidgets('a grouped row leaves the day to the header', (tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await _pump(
      tester,
      EventTimeline(
        events: [
          _event(
            id: 'e1',
            name: 'Nomad Run',
            startsAt: DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day,
              19,
              30,
            ),
          ),
        ],
        showHost: true,
        showVisibility: false,
        onOpen: (_) {},
      ),
    );

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('19:30'), findsOneWidget);
    expect(find.text('Tomorrow, 19:30'), findsNothing);
  });
}
