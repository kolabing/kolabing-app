import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_creator_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event_summary.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_applicant_review_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_detail_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_editor_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_management_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_organizer_dashboard_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_publish_review_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_role_editor_screen.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_entitlement_gate.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture script for the Task 10 organizer screens.
///
/// Deliberately named `..._capture.dart`, not `..._test.dart`: `flutter
/// test` only collects `*_test.dart`, so this never runs as part of the
/// suite. Run it explicitly to refresh the PNGs under
/// `test/features/multi_kolab/goldens/`:
///
/// ```
/// flutter test test/features/multi_kolab/multi_kolab_organizer_capture.dart \
///   --update-goldens
/// ```
///
/// These are real renders produced by the test binding — no simulator
/// automation is involved anywhere.
///
/// It is a capture script rather than a golden *assertion* suite because
/// `google_fonts` resolves its typefaces over the network at runtime, and
/// the test binding has none: every screen raises an asynchronous
/// "Failed to load font" that the framework attributes to the running test,
/// so the captures always write successfully but the assertions can never
/// pass in this environment. The PNGs therefore document layout, copy,
/// spacing, colour and state — in the fallback typeface, not the shipped
/// one. Behavioural coverage lives in
/// `multi_kolab_organizer_flow_test.dart`, which is what actually gates
/// the build.
void main() {
  // Renders the captures in a REAL typeface instead of the test binding's
  // block-glyph fallback. `google_fonts` fetches Inter/Anton over the
  // network, which the test binding has none of, so the PNGs used to be
  // unreadable rectangles. Registering a local TrueType file under the same
  // family names makes the copy legible; the shapes are Arial's, not
  // Inter's, so treat the captures as proof of LAYOUT and COPY, not of
  // typeface.
  setUpAll(() async {
    const candidates = [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/Library/Fonts/Arial.ttf',
    ];
    final path = candidates.firstWhere(
      (p) => File(p).existsSync(),
      orElse: () => '',
    );
    if (path.isEmpty) return;

    final bytes = await File(path).readAsBytes();
    final data = ByteData.view(Uint8List.fromList(bytes).buffer);

    // `google_fonts` keys its loaded fonts by "Family_variant"
    // (`Inter_regular`, `Inter_700`, `Anton_regular`, ...), so registering
    // the bare family name is not enough — every variant the theme asks for
    // has to resolve, or that run of text falls back to block glyphs.
    final families = <String>[];
    for (final family in const ['Inter', 'Anton', 'Roboto']) {
      families
        ..add(family)
        ..add('${family}_regular')
        ..add('${family}_italic');
      for (final weight in const [100, 200, 300, 500, 600, 700, 800, 900]) {
        families..add('${family}_$weight')..add('${family}_${weight}italic');
      }
    }

    for (final family in families) {
      final loader = FontLoader(family)..addFont(Future.value(data));
      await loader.load();
    }
  });

  Widget host(
    Widget child, {
    Locale locale = const Locale('en'),
    bool entitled = true,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => child),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        multiKolabRepositoryProvider.overrideWithValue(
          MockMultiKolabRepository(),
        ),
        multiKolabEntitlementProvider.overrideWith(
          (ref) async => EventCreatorEntitlement(
            hasEventCreatorEntitlement: entitled,
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    Widget child,
    String name, {
    Locale locale = const Locale('en'),
    bool entitled = true,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(child, locale: locale, entitled: entitled));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('organizer dashboard — populated', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_populated',
    );
  });

  testWidgets('organizer dashboard — small phone', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_small_phone',
      size: const Size(320, 640),
    );
  });

  testWidgets('organizer dashboard — es', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_es',
      locale: const Locale('es'),
    );
  });

  testWidgets('organizer dashboard — ca', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_ca',
      locale: const Locale('ca'),
    );
  });

  testWidgets('entitlement gate', (tester) async {
    await capture(
      tester,
      const Scaffold(body: MultiKolabEntitlementGate()),
      'entitlement_gate',
      entitled: false,
    );
  });

  testWidgets('create event form', (tester) async {
    await capture(
      tester,
      const MultiKolabEventEditorScreen(),
      'event_editor_create',
      // Tall enough to show the WHOLE form, so the capture is proof that no
      // event-level "Who can apply?" control survives below the fold.
      size: const Size(390, 1200),
    );
  });

  testWidgets('role editor', (tester) async {
    await capture(
      tester,
      const MultiKolabRoleEditorScreen(eventId: 'event-2'),
      'role_editor',
    );
  });

  // Applicant-facing, not organizer-facing, but it belongs to the same
  // capture harness: mock `event-1` carries exactly the three role states the
  // detail screen has to distinguish — a one-spot open role, a FILLED role,
  // and a multi-capacity role with one of three partners confirmed.
  testWidgets('event detail — open, filled and multi-capacity roles', (
    tester,
  ) async {
    await capture(
      tester,
      const MultiKolabEventDetailScreen(eventId: 'event-1'),
      'event_detail_role_states',
      size: const Size(390, 1500),
    );
  });

  testWidgets('event detail — small phone', (tester) async {
    await capture(
      tester,
      const MultiKolabEventDetailScreen(eventId: 'event-1'),
      'event_detail_role_states_small_phone',
      size: const Size(320, 1500),
    );
  });

  testWidgets('role editor — small phone, "Businesses and communities"', (
    tester,
  ) async {
    await capture(
      tester,
      const MultiKolabRoleEditorScreen(eventId: 'event-2'),
      'role_editor_small_phone',
      size: const Size(320, 1600),
    );
  });

  testWidgets('role editor — Catalan, small phone', (tester) async {
    await capture(
      tester,
      const MultiKolabRoleEditorScreen(eventId: 'event-2'),
      'role_editor_ca_small_phone',
      locale: const Locale('ca'),
      size: const Size(320, 1600),
    );
  });

  testWidgets('organizer dashboard — small phone, es', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_es_small_phone',
      locale: const Locale('es'),
      size: const Size(320, 640),
    );
  });

  testWidgets('organizer dashboard — small phone, ca', (tester) async {
    await capture(
      tester,
      const MultiKolabOrganizerDashboardScreen(),
      'organizer_dashboard_ca_small_phone',
      locale: const Locale('ca'),
      size: const Size(320, 640),
    );
  });

  testWidgets('pre-publish review', (tester) async {
    await capture(
      tester,
      const MultiKolabPublishReviewScreen(eventId: 'event-2'),
      'publish_review',
    );
  });

  testWidgets('event management — recruiting overview', (tester) async {
    await capture(
      tester,
      const MultiKolabEventManagementScreen(eventId: 'event-2'),
      'event_management_overview',
    );
  });

  testWidgets('event management — roles', (tester) async {
    await capture(
      tester,
      const MultiKolabEventManagementScreen(
        eventId: 'event-2',
        initialTab: 'roles',
      ),
      'event_management_roles',
    );
  });

  testWidgets('applicants grouped by status', (tester) async {
    await capture(
      tester,
      const MultiKolabApplicantReviewScreen(
        eventId: 'event-2',
        roleId: 'role-5',
      ),
      'applicant_review',
      size: const Size(390, 1100),
    );
  });

  testWidgets('accept confirmation sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const MultiKolabApplicantReviewScreen(
          eventId: 'event-2',
          roleId: 'role-5',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('multiKolabAccept_seed-application-1')),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/accept_confirmation.png'),
    );
  });

  testWidgets('empty organizer dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          multiKolabRepositoryProvider.overrideWithValue(
            MockMultiKolabRepository(),
          ),
          multiKolabEntitlementProvider.overrideWith(
            (ref) async =>
                const EventCreatorEntitlement(hasEventCreatorEntitlement: true),
          ),
          multiKolabMyEventsProvider.overrideWith(
            (ref) async => const <MultiKolabEventSummary>[],
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MultiKolabOrganizerDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/organizer_dashboard_empty.png'),
    );
  });

  testWidgets('create event form — venue needed selected', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const MultiKolabEventEditorScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('multiKolabEventTitleField')),
      'Kolabing Launch Weekend',
    );
    await tester.tap(find.byKey(const Key('multiKolabEventVenueNeededSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A RANGE OF DATES'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/event_editor_venue_needed_range.png'),
    );
  });

  testWidgets('role editor — open-ended, either eligibility', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const MultiKolabRoleEditorScreen(eventId: 'event-2')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('multiKolabRoleTitleField')),
      'Open to any brand',
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/role_editor_open_ended.png'),
    );
  });
}
