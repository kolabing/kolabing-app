// The events feed and Explore are the app's two browsing surfaces, and they now
// draw the same card. These pin the parts of that claim that are easy to break:
// the card variant is opt-in (community pages must keep their compact rows), the
// date grouping survives the switch (a swipe deck cannot group, which is why the
// feed stayed a list), and a locked event still refuses to show its picture.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/widgets/event_feed_card.dart';
import 'package:kolabing_app/features/event/widgets/event_timeline.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Event _event({
  required String id,
  required String name,
  required DateTime startsAt,
  String? location,
  String hostName = 'Real Run Club',
  bool canAccess = true,
}) => Event(
  id: id,
  name: name,
  partner: EventPartner(name: hostName, type: PartnerType.community),
  date: startsAt,
  startsAt: startsAt,
  location: location,
  canAccess: canAccess,
  attendeeCount: 12,
  photos: const [],
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1179, 2556); // iPhone @3x
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: KolabingTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the card carries host, title, time and the Explore CTA', (
    tester,
  ) async {
    await _pump(
      tester,
      EventFeedCard(
        event: _event(
          id: 'e1',
          name: 'Gamification Test Run',
          startsAt: DateTime(2026, 8, 25, 18),
          location: 'Eixample 46',
        ),
        locale: 'en',
        onTap: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Real Run Club'), findsOneWidget);
    expect(find.text('Gamification Test Run'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('Eixample 46'), findsOneWidget);
    // The same words Explore uses, because it is the same affordance.
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('a venue-less event drops the line rather than placeholding it', (
    tester,
  ) async {
    await _pump(
      tester,
      EventFeedCard(
        event: _event(
          id: 'e1',
          name: 'Somewhere unannounced',
          startsAt: DateTime(2026, 8, 25, 18),
        ),
        locale: 'en',
        onTap: () {},
      ),
    );

    expect(find.text('18:00'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('an event with no picture gets no photo area at all', (
    tester,
  ) async {
    // A full-bleed 16:10 grey rectangle with a calendar glyph in it reads as a
    // broken image and costs ~40% of the screen to say nothing. The feed's own
    // rule: where a field is absent, the line is absent.
    await _pump(
      tester,
      EventFeedCard(
        event: _event(
          id: 'e1',
          name: 'No photos yet',
          startsAt: DateTime(2026, 8, 25, 18),
        ),
        locale: 'en',
        onTap: () {},
      ),
    );

    expect(find.byType(AspectRatio), findsNothing);
    expect(find.byType(PageView), findsNothing);
    // The card itself is still there and still says the useful things.
    expect(find.text('No photos yet'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('a locked event says why instead of showing when and where', (
    tester,
  ) async {
    await _pump(
      tester,
      EventFeedCard(
        event: _event(
          id: 'e1',
          name: 'Members only',
          startsAt: DateTime(2026, 8, 25, 18),
          location: 'Eixample 46',
          canAccess: false,
        ),
        locale: 'en',
        onTap: () {},
      ),
    );

    expect(find.text('18:00'), findsNothing);
    expect(find.text('Eixample 46'), findsNothing);
  });

  group('EventTimeline variant', () {
    final events = [
      _event(id: 'a', name: 'Morning run', startsAt: DateTime(2026, 8, 25, 9)),
      _event(id: 'b', name: 'Evening run', startsAt: DateTime(2026, 8, 26, 19)),
    ];

    testWidgets('defaults to rows, so community pages are untouched', (
      tester,
    ) async {
      await _pump(tester, EventTimeline(events: events, onOpen: (_) {}));

      expect(find.byType(EventTimelineRow), findsNWidgets(2));
      expect(find.byType(EventFeedCard), findsNothing);
    });

    testWidgets('draws cards on request, keeping the date headers', (
      tester,
    ) async {
      await _pump(
        tester,
        EventTimeline(
          events: events,
          onOpen: (_) {},
          variant: EventTimelineVariant.card,
        ),
      );

      expect(find.byType(EventFeedCard), findsNWidgets(2));
      expect(find.byType(EventTimelineRow), findsNothing);
      // Two days, two headers — the thing a swipe deck would have cost us.
      expect(find.textContaining('/'), findsNWidgets(2));
    });
  });
}
