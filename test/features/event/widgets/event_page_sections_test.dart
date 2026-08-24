// Guardrails for the one event page's building blocks.
//
// Two classes of bug these hold shut:
//  1. the FX-48 collapse — a theme-sized button in a Row starving its sibling
//     to 0px, which the sticky action bar is now full of;
//  2. silently dropping a field the API does send, which is how this page came
//     to show three facts out of a dozen.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/models/event_ticket.dart';
import 'package:kolabing_app/features/event/widgets/event_page_sections.dart';
import 'package:kolabing_app/features/event/widgets/my_ticket_sheet.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

const _qrSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
    '<rect width="10" height="10" fill="#000"/></svg>';

Event _event({
  String name = 'Sunday Reset & Move',
  DateTime? startsAt,
  DateTime? endsAt,
  String? location = 'La Fabrica &Co',
  String? address = 'Carrer de Pujades 191',
  String? cityName = 'Barcelona',
  int? capacity = 20,
  int goingCount = 12,
  int waitlistCount = 0,
  String? mySignupStatus,
  int? waitlistPosition,
  String? visibility = 'public',
  String? seriesId,
  int? occurrenceIndex,
  List<dynamic>? tierGate,
}) => Event(
  id: 'e1',
  name: name,
  partner: const EventPartner(
    name: 'Real Run Club',
    type: PartnerType.community,
  ),
  date: DateTime(2026, 8, 24),
  startsAt: startsAt ?? DateTime(2026, 8, 24, 18),
  endsAt: endsAt,
  location: location,
  address: address,
  cityName: cityName,
  capacity: capacity,
  goingCount: goingCount,
  waitlistCount: waitlistCount,
  mySignupStatus: mySignupStatus,
  waitlistPosition: waitlistPosition,
  visibility: visibility,
  seriesId: seriesId,
  occurrenceIndex: occurrenceIndex,
  tierGate: tierGate,
  isUpcoming: true,
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
  group('title block', () {
    testWidgets('says when it starts AND ends, where, and who can see it', (
      tester,
    ) async {
      await _pump(
        tester,
        EventTitleBlock(
          event: _event(endsAt: DateTime(2026, 8, 24, 20)),
          onDirections: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      // `ends_at` has always been sent and was never shown.
      expect(find.text('Mon 24 Aug · 18:00–20:00'), findsOneWidget);
      // Venue name, street and city are three different fields.
      expect(
        find.text('La Fabrica &Co · Carrer de Pujades 191 · Barcelona'),
        findsOneWidget,
      );
      expect(find.text('Public'), findsOneWidget);
      // The name must get real width, not the one-letter-per-line collapse.
      expect(
        tester.getSize(find.text('Sunday Reset & Move')).width,
        greaterThan(150),
      );
    });

    testWidgets('drops the time span when the event has no end', (
      tester,
    ) async {
      await _pump(tester, EventTitleBlock(event: _event()));
      expect(find.text('Mon 24 Aug · 18:00'), findsOneWidget);
    });

    testWidgets('marks an occurrence of a recurring series', (tester) async {
      await _pump(
        tester,
        EventTitleBlock(event: _event(seriesId: 's1', occurrenceIndex: 3)),
      );
      expect(find.text('#3 in the series'), findsOneWidget);
    });
  });

  group('details', () {
    testWidgets('words a capped event, and who is allowed in', (tester) async {
      await _pump(tester, EventDetailsSection(event: _event()));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('12 going'), findsOneWidget);
      expect(find.textContaining('8 spot'), findsOneWidget);
      expect(find.text('Anyone can see and join this event'), findsOneWidget);
    });

    testWidgets('says unlimited rather than inventing a capacity', (
      tester,
    ) async {
      await _pump(tester, EventDetailsSection(event: _event(capacity: null)));
      expect(find.textContaining('Unlimited'), findsOneWidget);
    });

    testWidgets('a waitlisted viewer is told their position', (tester) async {
      await _pump(
        tester,
        EventDetailsSection(
          event: _event(mySignupStatus: 'waitlisted', waitlistPosition: 2),
        ),
      );
      expect(find.textContaining('#2'), findsOneWidget);
    });

    testWidgets('tier-gating outranks the visibility flag', (tester) async {
      // A "members" event with a tier gate is NOT open to every member.
      await _pump(
        tester,
        EventDetailsSection(
          event: _event(visibility: 'members', tierGate: const ['gold']),
        ),
      );
      expect(find.text('Limited to certain membership tiers'), findsOneWidget);
    });
  });

  group('action bar', () {
    testWidgets('two actions each keep a real width', (tester) async {
      await _pump(
        tester,
        const EventActionBar(
          children: [
            EventActionButton(
              label: 'My ticket',
              icon: Icons.confirmation_num,
              filled: true,
            ),
            EventActionButton(
              label: 'Check in',
              icon: Icons.place,
              filled: false,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      // `FilledButton.icon` builds a private subclass, so byType misses it.
      final filled = find.byWidgetPredicate((w) => w is FilledButton);
      final outlined = find.byWidgetPredicate((w) => w is OutlinedButton);
      // The theme gives buttons an infinite minimum width; unbounded in a Row
      // that starves the sibling to nothing (FX-48).
      expect(tester.getSize(filled).width, greaterThan(120));
      expect(tester.getSize(outlined).width, greaterThan(120));
    });

    testWidgets('collapses to nothing when there is no action', (tester) async {
      await _pump(tester, const EventActionBar(children: []));
      expect(find.byWidgetPredicate((w) => w is FilledButton), findsNothing);
      expect(tester.getSize(find.byType(EventActionBar)).height, 0);
    });
  });

  group('social links', () {
    testWidgets('render only the handles the host actually has', (
      tester,
    ) async {
      await _pump(
        tester,
        const EventSocialLinks(instagram: 'realrunclub', website: 'run.club'),
      );
      expect(find.text('@realrunclub'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      // No tiktok handle → no dead chip.
      expect(find.byIcon(Icons.music_note), findsNothing);
    });

    testWidgets('render nothing at all when the host has none', (tester) async {
      await _pump(tester, const EventSocialLinks());
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('ticket sheet', () {
    testWidgets('shows the server QR, the code and what to do with it', (
      tester,
    ) async {
      await _pump(
        tester,
        MyTicketSheet(
          ticket: const EventTicket(
            id: 't1',
            code: 'ABCD1234',
            status: 'going',
            qrSvg: _qrSvg,
            holderName: 'QA Attendee B',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(find.text('QA Attendee B'), findsOneWidget);
      expect(find.text('Show this at the door'), findsOneWidget);
    });

    testWidgets('an admitted ticket says so instead', (tester) async {
      await _pump(
        tester,
        MyTicketSheet(
          ticket: EventTicket(
            id: 't1',
            code: 'ABCD1234',
            status: 'going',
            qrSvg: _qrSvg,
            usedAt: DateTime(2026, 8, 24, 18, 4),
          ),
        ),
      );
      expect(find.text('Admitted at 18:04'), findsOneWidget);
      expect(find.text('Show this at the door'), findsNothing);
    });

    testWidgets('no QR from the server → the code alone, never a fake QR', (
      tester,
    ) async {
      await _pump(
        tester,
        MyTicketSheet(
          ticket: const EventTicket(
            id: 't1',
            code: 'ABCD1234',
            status: 'going',
            qrSvg: null,
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.text('Show this code at the door.'), findsOneWidget);
      expect(find.text('ABCD1234'), findsOneWidget);
    });
  });
}
