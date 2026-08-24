// Layout guardrails for the Luma-style community page pieces.
//
// The community Rewards tile shipped with its title wrapping one letter per
// line: a full-width-themed button in a Row squeezed the Expanded beside it to
// 0px. These tests hold the new page's rows to a real width so the same class
// of collapse cannot come back unseen, and check the date grouping renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/community/widgets/community_page_sections.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

const _longTitle =
    '10% honest greens discount with every Sunday run, members only';

Event _event({
  required String id,
  required String name,
  required DateTime day,
  String? location,
  String? signupStatus,
  bool canAccess = true,
}) => Event(
  id: id,
  name: name,
  partner: const EventPartner(
    name: 'Real Run Club',
    type: PartnerType.community,
  ),
  date: day,
  startsAt: day,
  location: location,
  mySignupStatus: signupStatus,
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
  testWidgets('the hero and identity block lay out at phone width', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          CommunityCoverHero(name: 'Real Run Club'),
          CommunityIdentityBlock(
            name: 'Real Run Club',
            description: _longTitle,
            metaText: 'Sports · 5 members',
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sports · 5 members'), findsOneWidget);
    // The name must get the full content width, not a squeezed column.
    expect(
      tester.getSize(find.text('Real Run Club').last).width,
      greaterThan(100),
    );
  });

  testWidgets('a nav row keeps its title wide next to the chevron', (
    tester,
  ) async {
    await _pump(
      tester,
      CommunityNavRow(
        icon: Icons.star,
        title: _longTitle,
        subtitle: 'Gold tier',
        onTap: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    // A 0px-wide Text still renders — one letter per line — so assert the width
    // the title actually got, not merely that it is on screen.
    expect(tester.getSize(find.text(_longTitle)).width, greaterThan(200));
  });

  testWidgets('the timeline groups events under a day header', (tester) async {
    final events = [
      _event(
        id: 'e1',
        name: 'Sunday Reset & Move',
        day: DateTime(2026, 9, 6, 19),
        location: 'La Fabrica &Co',
        signupStatus: 'going',
      ),
      _event(id: 'e2', name: 'Sunset Beach Run', day: DateTime(2026, 9, 6, 21)),
      _event(
        id: 'e3',
        name: 'Members-only social',
        day: DateTime(2026, 9, 12, 11),
        canAccess: false,
      ),
    ];
    final opened = <String>[];
    final refused = <String>[];

    await _pump(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: CommunityEventTimeline(
          events: events,
          onOpen: (event) => opened.add(event.id),
          onLocked: (event) => refused.add(event.id),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // Two days, one header each — the two 6 September events share theirs.
    expect(find.text('6 September'), findsOneWidget);
    expect(find.text('/ Sunday'), findsOneWidget);
    expect(find.text('12 September'), findsOneWidget);
    expect(find.text('/ Saturday'), findsOneWidget);
    expect(find.text('Sunday Reset & Move'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('La Fabrica &Co'), findsOneWidget);
    expect(find.text('Going'), findsOneWidget);

    // Titles must get real width, not the one-letter-per-line collapse.
    expect(
      tester.getSize(find.text('Sunday Reset & Move')).width,
      greaterThan(150),
    );

    await tester.tap(find.text('Sunset Beach Run'));
    await tester.pump();
    expect(opened, ['e2']);

    // A gated event is visible but shut: it reports back instead of opening.
    await tester.tap(find.text('Members-only social'));
    await tester.pump();
    expect(refused, ['e3']);
    expect(opened, ['e2']);
  });
}
