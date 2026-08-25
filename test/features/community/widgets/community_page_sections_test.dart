// Layout guardrails for the Luma-style community page pieces.
//
// The community Rewards tile shipped with its title wrapping one letter per
// line: a full-width-themed button in a Row squeezed the Expanded beside it to
// 0px. These tests hold the new page's rows to a real width so the same class
// of collapse cannot come back unseen, and check the date grouping renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/community/widgets/community_page_sections.dart';
import 'package:kolabing_app/features/event/widgets/event_timeline.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/hero_circle_action.dart';

const _longTitle =
    '10% honest greens discount with every Sunday run, members only';

Event _event({
  required String id,
  required String name,
  required DateTime day,
  String? location,
  String? signupStatus,
  bool canAccess = true,
  int? capacity,
  int goingCount = 0,
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
  capacity: capacity,
  goingCount: goingCount,
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
        child: EventTimeline(
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

  testWidgets('the hero paints a real cover photo when there is one', (
    tester,
  ) async {
    await _pump(
      tester,
      const CommunityCoverHero(
        name: 'Real Run Club',
        avatarUrl: 'https://example.test/avatar.jpg',
        coverUrl: 'https://example.test/cover.jpg',
      ),
    );

    expect(tester.takeException(), isNull);
    // Sharp cover + logo tile, not two copies of the blurred avatar.
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('with no photo at all the hero stays on the brand band', (
    tester,
  ) async {
    await _pump(tester, const CommunityCoverHero(name: 'Real Run Club'));
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the identity block shows the handles a community has', (
    tester,
  ) async {
    await _pump(
      tester,
      const CommunityIdentityBlock(
        name: 'Real Run Club',
        metaText: 'Barcelona · Running club · 5 members',
        instagram: 'realrunclub',
        website: 'run.club',
      ),
    );

    expect(find.text('@realrunclub'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    // No tiktok handle → no dead icon.
    expect(find.text('@'), findsNothing);
  });

  testWidgets('filter chips report their counts and their selection', (
    tester,
  ) async {
    CommunityEventFilter? picked;
    await _pump(
      tester,
      CommunityFilterChips(
        counts: const {
          CommunityEventFilter.upcoming: 3,
          CommunityEventFilter.past: 7,
          CommunityEventFilter.publicOnly: 2,
          CommunityEventFilter.membersOnly: 1,
        },
        selected: CommunityEventFilter.upcoming,
        onSelect: (f) => picked = f,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tester.tap(find.text('Past'));
    await tester.pump();
    expect(picked, CommunityEventFilter.past);
  });

  testWidgets('a filter nobody can use is not offered', (tester) async {
    await _pump(
      tester,
      CommunityFilterChips(
        counts: const {
          CommunityEventFilter.upcoming: 3,
          CommunityEventFilter.past: 0,
          CommunityEventFilter.publicOnly: 0,
          CommunityEventFilter.membersOnly: 0,
        },
        selected: CommunityEventFilter.upcoming,
        onSelect: (_) {},
      ),
    );
    // One live filter is not a choice, so the row disappears entirely.
    expect(find.text('Upcoming'), findsNothing);
  });

  testWidgets(
    'an event says how full it is, and an uncapped one says nothing',
    (tester) async {
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: EventTimeline(
            events: [
              _event(
                id: 'full',
                name: 'Sold out run',
                day: DateTime(2026, 9, 6, 19),
                capacity: 10,
                goingCount: 10,
              ),
              _event(
                id: 'nearly',
                name: 'Almost full run',
                day: DateTime(2026, 9, 7, 19),
                capacity: 10,
                goingCount: 9,
              ),
              _event(
                id: 'roomy',
                name: 'Plenty of room run',
                day: DateTime(2026, 9, 8, 19),
                capacity: 20,
                goingCount: 2,
              ),
              _event(
                id: 'uncapped',
                name: 'Uncapped run',
                day: DateTime(2026, 9, 9, 19),
              ),
            ],
            onOpen: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('Near capacity'), findsOneWidget);
      expect(find.text('18 left'), findsOneWidget);
      // Four events, three badges: "unlimited" is not news.
      expect(find.text('Unlimited'), findsNothing);
    },
  );

  testWidgets(
    'the photo strip renders what it is given, and hides when empty',
    (tester) async {
      await _pump(tester, const CommunityPhotoStrip(photos: []));
      expect(find.text('PHOTOS'), findsNothing);

      await _pump(
        tester,
        const CommunityPhotoStrip(
          photos: [
            GalleryPhoto(id: '1', url: 'https://example.test/1.jpg'),
            GalleryPhoto(id: '2', url: 'https://example.test/2.jpg'),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('PHOTOS'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    },
  );

  testWidgets('the hero back button actually goes back', (tester) async {
    // It did not. `Navigator.maybePop()` on a page entered cold from a deep
    // link has nothing to pop, so the button was silently dead.
    await tester.pumpWidget(
      MaterialApp(
        theme: KolabingTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: CommunityCoverHero(name: 'Real Run Club'),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityCoverHero), findsOneWidget);

    await tester.tap(find.byType(HeroBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityCoverHero), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('with nothing behind it and no router, back is inert not fatal', (
    tester,
  ) async {
    await _pump(tester, const CommunityCoverHero(name: 'Real Run Club'));
    await tester.tap(find.byType(HeroBackButton));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('deep-linked with nothing behind it, back opens the app', (
    tester,
  ) async {
    // The reported bug, exactly: arriving cold on a community page (a shared
    // link, a notification) left the back button with an empty navigator, and
    // `maybePop()` did nothing at all. It should let the visitor in.
    final router = GoRouter(
      initialLocation: '/community/deep',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('the app')),
        ),
        GoRoute(
          path: '/community/deep',
          builder: (_, _) =>
              const Scaffold(body: CommunityCoverHero(name: 'Real Run Club')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: KolabingTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommunityCoverHero), findsOneWidget);

    await tester.tap(find.byType(HeroBackButton));
    await tester.pumpAndSettle();
    expect(find.text('the app'), findsOneWidget);
  });
}
