import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/multi_kolab/models/child_kolab_result.dart';
import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_creator_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_dashboard.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role_application.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_applicant_review_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_editor_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_management_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_organizer_dashboard_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_publish_review_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_role_editor_screen.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_entitlement_gate.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_organizer_event_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Task 10 — organizer experience.
///
/// Everything here is driven with `find.byKey` / `find.text` /
/// `tester.tap` / `tester.enterText` / `pumpAndSettle` over the
/// deterministic mock repository. No simulator-tap automation is used
/// anywhere (that was proven systemically unreliable in this environment).

/// The organizer routes, in registration order. A minimal set: the app
/// router additionally applies auth redirects, which would make these tests
/// depend on session state they are not exercising.
List<RouteBase> get organizerRoutes => [
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerEvents,
    builder: (_, _) => const MultiKolabOrganizerDashboardScreen(),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerEventNew,
    builder: (_, _) => const MultiKolabEventEditorScreen(),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerEventEdit,
    builder: (_, state) =>
        MultiKolabEventEditorScreen(eventId: state.pathParameters['id']),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerEventReview,
    builder: (_, state) => MultiKolabPublishReviewScreen(
      eventId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerRoleNew,
    builder: (_, state) =>
        MultiKolabRoleEditorScreen(eventId: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerRoleEdit,
    builder: (_, state) => MultiKolabRoleEditorScreen(
      eventId: state.pathParameters['id'] ?? '',
      roleId: state.pathParameters['roleId'],
    ),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerRoleApplications,
    builder: (_, state) => MultiKolabApplicantReviewScreen(
      roleId: state.pathParameters['roleId'] ?? '',
      eventId: state.uri.queryParameters['event'] ?? '',
    ),
  ),
  GoRoute(
    path: KolabingRoutes.multiKolabOrganizerEvent,
    builder: (_, state) => MultiKolabEventManagementScreen(
      eventId: state.pathParameters['id'] ?? '',
      initialTab: state.uri.queryParameters['tab'],
    ),
  ),
];

void main() {
  /// Wraps [child] with the app's localizations and a Riverpod scope backed
  /// by [repository]. `size` lets the same test render at a small and a
  /// large phone width.
  Widget host(
    Widget child, {
    required MultiKolabRepository repository,
    Locale locale = const Locale('en'),
    EventCreatorEntitlement? entitlement,
    Size size = const Size(390, 844),
  }) {
    // Router-backed even for single-screen tests: the organizer screens
    // navigate on success (an editor pushes the management screen), so a
    // bare `home:` would blow up with "No GoRouter found in context" for
    // reasons that have nothing to do with what is being asserted.
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => child),
        ...organizerRoutes,
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        multiKolabRepositoryProvider.overrideWithValue(repository),
        if (entitlement != null)
          multiKolabEntitlementProvider.overrideWith(
            (ref) async => entitlement,
          ),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp.router(
          locale: locale,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

  /// Renders on a tall surface so a `ListView`'s off-screen children are
  /// actually built. Widget tests default to 800x600, which virtualises away
  /// most of these screens and would make an assertion "fail" for a purely
  /// synthetic reason. The responsive group overrides this deliberately.
  void tallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  const entitled = EventCreatorEntitlement(hasEventCreatorEntitlement: true);
  const notEntitled = EventCreatorEntitlement(
    hasEventCreatorEntitlement: false,
  );

  group('organizer dashboard', () {
    testWidgets('shows a loading skeleton before the events arrive', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(
            simulatedDelay: const Duration(milliseconds: 50),
          ),
          entitlement: entitled,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('multiKolabOrganizerLoading')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('lists the organizer-owned events with a manage action', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabOrganizerEventCard_event-2')),
        findsOneWidget,
      );
      expect(find.text('My Own Rooftop Session'), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabManageCta_event-2')),
        findsOneWidget,
      );
      // Another organizer's event must never appear here.
      expect(find.text('Kolabing Launch Weekend'), findsNothing);
    });

    testWidgets('an entitled organizer is offered the create CTA', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabOrganizerCreateFab')),
        findsOneWidget,
      );
    });

    testWidgets('a non-entitled organizer is not offered the create CTA', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: notEntitled,
        ),
      );
      await tester.pumpAndSettle();

      // The existing events stay readable — the entitlement gates creation
      // only, so an organizer whose access lapsed can still wind things down.
      expect(
        find.byKey(const Key('multiKolabOrganizerEventCard_event-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiKolabOrganizerCreateFab')),
        findsNothing,
      );
    });

    testWidgets('a non-entitled organizer with no events sees the gate', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: _EmptyRepository(),
          entitlement: notEntitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MultiKolabEntitlementGate), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabOrganizerEmptyCreateCta')),
        findsNothing,
      );
      // The gate must never route at the Business subscription paywall.
      expect(
        find.byKey(const Key('multiKolabEntitlementGateCta')),
        findsNothing,
      );
    });

    testWidgets('an entitled organizer with no events sees the create CTA', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: _EmptyRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multiKolabOrganizerEmpty')), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabOrganizerEmptyCreateCta')),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            multiKolabRepositoryProvider.overrideWithValue(
              MockMultiKolabRepository(),
            ),
            multiKolabEntitlementProvider.overrideWith(
              (ref) async => entitled,
            ),
            multiKolabMyEventsProvider.overrideWith(
              (ref) => Future<List<MultiKolabEventSummary>>.error(
                Exception('simulated dashboard failure'),
                StackTrace.empty,
              ),
            ),
          ],
          // Riverpod 3 retries a failed provider automatically, which would
          // bounce the UI straight back to loading; a test asserting the
          // error state must opt out.
          retry: (_, _) => null,
          child: MaterialApp(
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

      expect(find.byKey(const Key('multiKolabOrganizerError')), findsOneWidget);
      expect(find.byKey(const Key('multiKolabOrganizerRetry')), findsOneWidget);
    });

    testWidgets('the status filter narrows and can be cleared', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      // event-2 is recruiting, so the Drafts group is empty.
      await tester.tap(find.text('DRAFTS'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('multiKolabOrganizerFilterEmpty')),
        findsOneWidget,
      );

      await tester.tap(find.text('Show all events'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('multiKolabOrganizerEventCard_event-2')),
        findsOneWidget,
      );
    });
  });

  group('organizer event card', () {
    testWidgets('a draft is flagged as needing attention', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: _SingleDraftRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabNeedsAttention_draft-1')),
        findsOneWidget,
      );
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('a recruiting event uses product language, not the enum', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recruiting partners'), findsOneWidget);
      expect(find.text('recruiting'), findsNothing);
    });

    testWidgets('the role progress carries a screen-reader label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabOrganizerDashboardScreen(),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MultiKolabOrganizerEventCard), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('roles open')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('event editor', () {
    testWidgets('an empty title is rejected before any request is sent', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabEventSaveDraftCta')));
      await tester.pumpAndSettle();

      expect(find.text('Give your event a name'), findsOneWidget);
      expect(repository.createdInputs, isEmpty);
    });

    testWidgets('a non-HTTPS RSVP link is rejected', (tester) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('multiKolabEventTitleField')),
        'Rooftop Session',
      );
      await tester.enterText(
        find.byKey(const Key('multiKolabEventRsvpField')),
        'http://lu.ma/rooftop',
      );
      await tester.tap(find.byKey(const Key('multiKolabEventSaveDraftCta')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid https:// link'), findsOneWidget);
      expect(repository.createdInputs, isEmpty);
    });

    testWidgets('venue-needed and eligibility reach the request payload', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('multiKolabEventTitleField')),
        'Rooftop Session',
      );
      await tester.tap(
        find.byKey(const Key('multiKolabEventVenueNeededSwitch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('COMMUNITIES'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabEventSaveDraftCta')));
      await tester.pumpAndSettle();

      final payload = repository.createdInputs.single.toJson();
      expect(payload['title'], 'Rooftop Session');
      expect(payload['venue_needed'], isTrue);
      expect(payload['eligible_account_type'], 'community');
    });

    testWidgets('switching to a date range hides the single-date field', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(),
          repository: _RecordingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabEventDateField')),
        findsOneWidget,
      );

      await tester.tap(find.text('A RANGE OF DATES'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multiKolabEventDateField')), findsNothing);
      expect(
        find.byKey(const Key('multiKolabEventRangeStartField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiKolabEventRangeEndField')),
        findsOneWidget,
      );
    });

    testWidgets('editing a saved draft restores every stored value', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(eventId: 'draft-existing'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stored Draft'), findsOneWidget);
      expect(find.text('Stored description'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('https://lu.ma/stored'), findsOneWidget);
    });

    testWidgets('leaving with unsaved changes asks before discarding', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventEditorScreen(),
          repository: _RecordingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('multiKolabEventTitleField')),
        'Half-typed',
      );
      await tester.pumpAndSettle();

      final popScopes = tester
          .widgetList(find.byWidgetPredicate((w) => w is PopScope))
          .cast<PopScope<Object?>>();
      expect(
        popScopes.any((p) => !p.canPop),
        isTrue,
        reason: 'a dirty form must intercept the back gesture',
      );
    });
  });

  group('role editor', () {
    testWidgets('the eligibility choice explains where the role appears', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Businesses and communities will both see this role in their '
          'Explore feed.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('COMMUNITIES'));
      await tester.pumpAndSettle();
      expect(
        find.text('Communities will see this role in their Explore feed.'),
        findsOneWidget,
      );

      await tester.tap(find.text('BUSINESSES'));
      await tester.pumpAndSettle();
      expect(
        find.text('Businesses will see this role in their Explore feed.'),
        findsOneWidget,
      );
    });

    testWidgets('positions_needed can never go below one', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
      final decrease = tester.widget<IconButton>(
        find.byKey(const Key('multiKolabPositionsDecrease')),
      );
      expect(decrease.onPressed, isNull);

      await tester.tap(find.byKey(const Key('multiKolabPositionsIncrease')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('multiKolabPositionsDecrease')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('an open-ended role saves with no compensation type', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('multiKolabRoleTitleField')),
        'Open to any brand',
      );
      await tester.tap(find.byKey(const Key('multiKolabRoleSaveCta')));
      await tester.pumpAndSettle();

      final payload = repository.addedRoles.single.toJson();
      expect(payload['title'], 'Open to any brand');
      expect(payload['eligible_account_type'], 'either');
      expect(payload.containsKey('compensation_type'), isFalse);
    });

    testWidgets('an empty role title is rejected', (tester) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabRoleSaveCta')));
      await tester.pumpAndSettle();

      expect(find.text('Give the role a name'), findsOneWidget);
      expect(repository.addedRoles, isEmpty);
    });

    testWidgets('a value-exchange role carries need and receive', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('multiKolabRoleTitleField')),
        'Coffee sponsor',
      );
      await tester.enterText(
        find.byKey(const Key('multiKolabRoleNeedField')),
        'Coffee for 60 runners',
      );
      await tester.enterText(
        find.byKey(const Key('multiKolabRoleReceiveField')),
        'Logo on the banner',
      );
      await tester.tap(
        find.byKey(const Key('multiKolabCompensation_value_exchange')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('multiKolabRoleSaveCta')));
      await tester.pumpAndSettle();

      final payload = repository.addedRoles.single.toJson();
      expect(payload['need'], 'Coffee for 60 runners');
      expect(payload['receive'], 'Logo on the banner');
      expect(payload['compensation_type'], 'value_exchange');
    });
  });

  group('pre-publish review', () {
    testWidgets('lists what is still missing and blocks a role-less publish', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabPublishReviewScreen(eventId: 'draft-empty'),
          repository: _RecordingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabReviewMissingBlock')),
        findsOneWidget,
      );
      expect(find.text('• Add at least one partner role'), findsOneWidget);

      final publish = tester.widget<Widget>(
        find.byKey(const Key('multiKolabPublishCta')),
      );
      expect(publish, isNotNull);
      await tester.tap(find.byKey(const Key('multiKolabPublishCta')));
      await tester.pumpAndSettle();
      // Nothing was published: the draft is still on screen.
      expect(find.byKey(const Key('multiKolabReviewMissingBlock')), findsOneWidget);
    });

    testWidgets('shows every role with its eligibility and capacity', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabPublishReviewScreen(eventId: 'event-2'),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabReviewRole_role-5')),
        findsOneWidget,
      );
      expect(find.textContaining('0 of 1 partners confirmed'), findsWidgets);
    });

    testWidgets('a successful publish confirms what publishing did', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabPublishReviewScreen(eventId: 'event-2'),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabPublishCta')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabPublishSuccessDialog')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Each open role is now an offer in the Explore feed of the '
          'profiles that can apply to it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an entitlement refusal shows the gate and keeps the draft', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabPublishReviewScreen(eventId: 'event-2'),
          repository: _EntitlementRefusingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabPublishCta')));
      await tester.pumpAndSettle();

      expect(find.byType(MultiKolabEntitlementGate), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabPublishSuccessDialog')),
        findsNothing,
      );
      // The publish CTA is still there — nothing was lost.
      expect(find.byKey(const Key('multiKolabPublishCta')), findsOneWidget);
    });
  });

  group('event management', () {
    testWidgets('a recruiting event offers confirm and cancel, not complete', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(eventId: 'event-2'),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabConfirmEventCta')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('multiKolabCancelEventCta')), findsOneWidget);
      expect(find.byKey(const Key('multiKolabCompleteEventCta')), findsNothing);
      expect(find.byKey(const Key('multiKolabManageReviewCta')), findsNothing);
    });

    testWidgets('a draft offers review-and-publish, not confirm', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(eventId: 'draft-empty'),
          repository: _RecordingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multiKolabManageReviewCta')), findsOneWidget);
      expect(find.byKey(const Key('multiKolabConfirmEventCta')), findsNothing);
    });

    testWidgets('a cancelled event offers no lifecycle action at all', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(eventId: 'cancelled-1'),
          repository: _RecordingRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multiKolabCancelEventCta')), findsNothing);
      expect(find.byKey(const Key('multiKolabConfirmEventCta')), findsNothing);
      expect(find.byKey(const Key('multiKolabManageEditCta')), findsNothing);
    });

    testWidgets('confirming an event asks first', (tester) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(eventId: 'recruiting-1'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabConfirmEventCta')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabConfirmEventDialog')),
        findsOneWidget,
      );
      expect(repository.confirmed, isEmpty);

      await tester.tap(find.byKey(const Key('multiKolabDialogConfirmCta')));
      await tester.pumpAndSettle();
      expect(repository.confirmed, ['recruiting-1']);
    });

    testWidgets('cancelling requires a reason', (tester) async {
      final repository = _RecordingRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(eventId: 'recruiting-1'),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabCancelEventCta')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('multiKolabCancelEventConfirmCta')));
      await tester.pumpAndSettle();

      expect(find.text('Please give a reason'), findsOneWidget);
      expect(repository.cancelled, isEmpty);

      await tester.enterText(
        find.byKey(const Key('multiKolabCancelReasonField')),
        'Venue fell through',
      );
      await tester.tap(find.byKey(const Key('multiKolabCancelEventConfirmCta')));
      await tester.pumpAndSettle();

      expect(repository.cancelled, [('recruiting-1', 'Venue fell through')]);
    });

    testWidgets('the roles tab shows fill progress and a close action', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(
            eventId: 'event-2',
            initialTab: 'roles',
          ),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabRoleCard_role-5')),
        findsOneWidget,
      );
      expect(find.text('0 of 1 partners confirmed'), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabRoleToggle_role-5')),
        findsOneWidget,
      );
      expect(find.text('Stop recruiting'), findsOneWidget);
    });

    testWidgets('closing a role confirms, then closes it server-side', (
      tester,
    ) async {
      final repository = MockMultiKolabRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabEventManagementScreen(
            eventId: 'event-2',
            initialTab: 'roles',
          ),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('multiKolabRoleToggle_role-5')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('multiKolabCloseRoleDialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('multiKolabDialogConfirmCta')));
      await tester.pumpAndSettle();

      final event = await repository.getEvent('event-2');
      expect(
        event.roles.single.status,
        MultiKolabRoleStatus.closed,
        reason: 'the role must be closed, never deleted',
      );
      expect(find.text('Reopen role'), findsOneWidget);
    });
  });

  group('applicant review', () {
    testWidgets('groups applications by status and keeps declined visible', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabApplicantsSection_pending')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiKolabApplicantsSection_shortlisted')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiKolabApplicantsSection_declined')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('multiKolabApplication_seed-application-3')),
        findsOneWidget,
      );
    });

    testWidgets('only state-valid actions are offered', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      // Pending: shortlist + decline + accept.
      expect(
        find.byKey(const Key('multiKolabShortlist_seed-application-1')),
        findsOneWidget,
      );
      // Shortlisted: no shortlist action any more.
      expect(
        find.byKey(const Key('multiKolabShortlist_seed-application-2')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiKolabAccept_seed-application-2')),
        findsOneWidget,
      );
      // Declined: nothing actionable.
      expect(
        find.byKey(const Key('multiKolabAccept_seed-application-3')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('multiKolabDecline_seed-application-3')),
        findsNothing,
      );
    });

    testWidgets('shortlisting moves the row into the shortlisted section', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('multiKolabShortlist_seed-application-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabShortlist_seed-application-1')),
        findsNothing,
      );
      expect(find.text('Shortlisted (2)'), findsOneWidget);
    });

    testWidgets('declining asks for confirmation first', (tester) async {
      final repository = MockMultiKolabRepository();
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
          repository: repository,
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('multiKolabDecline_seed-application-1')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('multiKolabDeclineDialog')), findsOneWidget);
      expect(find.textContaining('DJ Partner'), findsOneWidget);

      await tester.tap(find.byKey(const Key('multiKolabDeclineConfirmCta')));
      await tester.pumpAndSettle();

      expect(find.text('Declined (2)'), findsOneWidget);
    });

    testWidgets(
      'accepting shows capacity + the child-Kolab consequence, then the '
      'created Kolab',
      (tester) async {
        final repository = MockMultiKolabRepository();
        tallSurface(tester);
      await tester.pumpWidget(
          host(
            const MultiKolabApplicantReviewScreen(
              eventId: 'event-2',
              roleId: 'role-5',
            ),
            repository: repository,
            entitlement: entitled,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('multiKolabAccept_seed-application-1')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('multiKolabAcceptConfirmSheet')),
          findsOneWidget,
        );
        expect(find.text('Role: DJ Partner'), findsOneWidget);
        expect(find.text('0 of 1 places left after this'), findsOneWidget);
        expect(
          find.text(
            'A Kolab and a collaboration will be created between you and '
            'this partner.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('multiKolabAcceptConfirmCta')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('multiKolabAcceptSuccessDialog')),
          findsOneWidget,
        );
        expect(find.text('Open collaboration'), findsOneWidget);

        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        // Server-side capacity is what changed — the role is now filled.
        final event = await repository.getEvent('event-2');
        expect(event.roles.single.positionsFilled, 1);
        expect(event.roles.single.status, MultiKolabRoleStatus.filled);

        // The accepted row now links at the created child Kolab.
        expect(
          find.byKey(const Key('multiKolabChildKolab_seed-application-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets('a capacity conflict is reported without losing the list', (
      tester,
    ) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
          repository: _CapacityConflictRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('multiKolabAccept_seed-application-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('multiKolabAcceptConfirmCta')));
      await tester.pumpAndSettle();

      expect(find.text('This role is already full.'), findsOneWidget);
      expect(
        find.byKey(const Key('multiKolabApplication_seed-application-1')),
        findsOneWidget,
      );
    });

    testWidgets('an empty role shows the empty state', (tester) async {
      tallSurface(tester);
      await tester.pumpWidget(
        host(
          const MultiKolabApplicantReviewScreen(
            eventId: 'event-1',
            roleId: 'role-1',
          ),
          repository: MockMultiKolabRepository(),
          entitlement: entitled,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiKolabApplicantsEmpty')),
        findsOneWidget,
      );
    });
  });

  group('localization', () {
    for (final (locale, expected) in <(String, String)>[
      ('es', 'Buscando partners'),
      ('ca', 'Buscant partners'),
    ]) {
      testWidgets('the dashboard renders in $locale', (tester) async {
        tallSurface(tester);
      await tester.pumpWidget(
          host(
            const MultiKolabOrganizerDashboardScreen(),
            repository: MockMultiKolabRepository(),
            entitlement: entitled,
            locale: Locale(locale),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expected), findsOneWidget);
        expect(find.text('Recruiting partners'), findsNothing);
      });
    }
  });

  group('responsive rendering', () {
    for (final size in const [Size(320, 640), Size(430, 932)]) {
      testWidgets('the dashboard lays out at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(
            const MultiKolabOrganizerDashboardScreen(),
            repository: MockMultiKolabRepository(),
            entitlement: entitled,
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('multiKolabOrganizerEventCard_event-2')),
          findsOneWidget,
        );
      });
    }

    testWidgets('the role editor survives a large text scale', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            multiKolabRepositoryProvider.overrideWithValue(
              MockMultiKolabRepository(),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MultiKolabRoleEditorScreen(eventId: 'event-2'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('routing', () {
    test('organizer routes never collide with the applicant detail route', () {
      // `/organizer/...` cannot be matched by `/multi-kolab-events/:id`.
      expect(
        KolabingRoutes.multiKolabOrganizerEventNew.startsWith('/organizer/'),
        isTrue,
      );
      expect(
        KolabingRoutes.multiKolabEventDetail.startsWith('/organizer/'),
        isFalse,
      );
    });

    test('the location helpers build the expected paths', () {
      expect(
        multiKolabOrganizerEventLocation('abc'),
        '/organizer/multi-kolab-events/abc',
      );
      expect(
        multiKolabOrganizerEventLocation('abc', tab: 'roles'),
        '/organizer/multi-kolab-events/abc?tab=roles',
      );
      expect(
        multiKolabOrganizerEventEditLocation('abc'),
        '/organizer/multi-kolab-events/abc/edit',
      );
      expect(
        multiKolabOrganizerRoleLocation('abc'),
        '/organizer/multi-kolab-events/abc/roles/new',
      );
      expect(
        multiKolabOrganizerRoleLocation('abc', roleId: 'r1'),
        '/organizer/multi-kolab-events/abc/roles/r1',
      );
      expect(
        multiKolabOrganizerRoleApplicationsLocation(
          eventId: 'abc',
          roleId: 'r1',
        ),
        '/organizer/multi-kolab-roles/r1/applications?event=abc',
      );
    });
  });

  group('full organizer flow', () {
    testWidgets(
      'create a draft, add community/business/open-ended roles, review, '
      'publish, then shortlist, decline and accept',
      (tester) async {
        tallSurface(tester);
        final repository = MockMultiKolabRepository();
        final router = GoRouter(
          initialLocation: KolabingRoutes.multiKolabOrganizerEventNew,
          routes: organizerRoutes,
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              multiKolabRepositoryProvider.overrideWithValue(repository),
              multiKolabEntitlementProvider.overrideWith(
                (ref) async => entitled,
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Create the draft.
        await tester.enterText(
          find.byKey(const Key('multiKolabEventTitleField')),
          'Launch Weekend',
        );
        await tester.tap(find.byKey(const Key('multiKolabEventSaveDraftCta')));
        await tester.pumpAndSettle();

        // Landed on the management screen's Roles tab.
        expect(find.byKey(const Key('multiKolabAddRoleCta')), findsOneWidget);

        final draft = (await repository.myEvents())
            .firstWhere((e) => e.title == 'Launch Weekend');

        // 2. Add three roles: community, business and open-ended.
        for (final (title, segment) in const [
          ('Run club partner', 'COMMUNITIES'),
          ('Venue partner', 'BUSINESSES'),
          ('Open to any partner', 'BUSINESSES AND COMMUNITIES'),
        ]) {
          await tester.tap(find.byKey(const Key('multiKolabAddRoleCta')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('multiKolabRoleTitleField')),
            title,
          );
          await tester.tap(find.text(segment));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('multiKolabRoleSaveCta')));
          await tester.pumpAndSettle();
        }

        final withRoles = await repository.getEvent(draft.id);
        expect(withRoles.roles, hasLength(3));
        expect(
          withRoles.roles.map((r) => r.eligibleAccountType.toApiValue()),
          containsAll(<String>['community', 'business', 'either']),
        );

        // 3. Review and publish.
        await tester.tap(find.text('OVERVIEW'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('multiKolabManageReviewCta')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('multiKolabPublishCta')), findsOneWidget);

        await tester.tap(find.byKey(const Key('multiKolabPublishCta')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('multiKolabPublishSuccessDialog')),
          findsOneWidget,
        );
        await tester.tap(find.text('Back to event'));
        await tester.pumpAndSettle();

        expect(
          (await repository.getEvent(draft.id)).status,
          MultiKolabEventStatus.recruiting,
        );

        // 4. Review the applicants on the seeded role and act on each.
        router.push(
          multiKolabOrganizerRoleApplicationsLocation(
            eventId: 'event-2',
            roleId: 'role-5',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('multiKolabShortlist_seed-application-1')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Shortlisted (2)'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('multiKolabDecline_seed-application-2')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('multiKolabDeclineConfirmCta')));
        await tester.pumpAndSettle();
        expect(find.text('Declined (2)'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('multiKolabAccept_seed-application-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('multiKolabAcceptConfirmCta')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();

        // 5. Role capacity came back from the server, and the child Kolab
        //    is reachable.
        final ownEvent = await repository.getEvent('event-2');
        expect(ownEvent.roles.single.positionsFilled, 1);
        expect(ownEvent.roles.single.status, MultiKolabRoleStatus.filled);
        expect(
          find.byKey(const Key('multiKolabChildKolab_seed-application-1')),
          findsOneWidget,
        );

        // 6. Confirm the event through a valid lifecycle action.
        router.push(multiKolabOrganizerEventLocation('event-2'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('multiKolabConfirmEventCta')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('multiKolabDialogConfirmCta')));
        await tester.pumpAndSettle();

        expect(
          (await repository.getEvent('event-2')).status,
          MultiKolabEventStatus.confirmed,
        );
      },
    );
  });
}

// --- test doubles ------------------------------------------------------------

/// Records every write so a test can assert on the exact payload that would
/// have gone over the wire, and serves a small deterministic fixture set
/// covering a draft, a recruiting event and a cancelled event.
class _RecordingRepository extends MockMultiKolabRepository {
  final List<CreateMultiKolabEventInput> createdInputs = [];
  final List<CreateMultiKolabRoleInput> addedRoles = [];
  final List<String> confirmed = [];
  final List<(String, String)> cancelled = [];

  static final _fixtures = <String, MultiKolabEvent>{
    'draft-existing': MultiKolabEvent(
      id: 'draft-existing',
      status: MultiKolabEventStatus.draft,
      creatorProfileId: MockMultiKolabRepository.mockViewerProfileId,
      title: 'Stored Draft',
      description: 'Stored description',
      city: 'Barcelona',
      rsvpUrl: 'https://lu.ma/stored',
      dateMode: MultiKolabDateMode.exact,
      eventDate: DateTime(2026, 9, 12),
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: const [],
      roleCounts: (total: 0, open: 0, filled: 0),
    ),
    'draft-empty': MultiKolabEvent(
      id: 'draft-empty',
      status: MultiKolabEventStatus.draft,
      creatorProfileId: MockMultiKolabRepository.mockViewerProfileId,
      title: 'Bare Draft',
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: const [],
      roleCounts: (total: 0, open: 0, filled: 0),
    ),
    'recruiting-1': MultiKolabEvent(
      id: 'recruiting-1',
      status: MultiKolabEventStatus.recruiting,
      creatorProfileId: MockMultiKolabRepository.mockViewerProfileId,
      title: 'Recruiting Event',
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: const [],
      roleCounts: (total: 0, open: 0, filled: 0),
    ),
    'cancelled-1': MultiKolabEvent(
      id: 'cancelled-1',
      status: MultiKolabEventStatus.cancelled,
      creatorProfileId: MockMultiKolabRepository.mockViewerProfileId,
      title: 'Cancelled Event',
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: const [],
      roleCounts: (total: 0, open: 0, filled: 0),
    ),
  };

  @override
  Future<MultiKolabEvent> getEvent(String eventId) async =>
      _fixtures[eventId] ?? super.getEvent(eventId);

  @override
  Future<MultiKolabDashboard> getDashboard(String eventId) async {
    final fixture = _fixtures[eventId];
    if (fixture == null) return super.getDashboard(eventId);
    return MultiKolabDashboard(
      eventId: fixture.id,
      status: fixture.status,
      roleCounts: const MultiKolabRoleCounts(total: 0, open: 0, filled: 0),
      roles: const [],
    );
  }

  @override
  Future<MultiKolabEvent> createDraft(CreateMultiKolabEventInput input) {
    createdInputs.add(input);
    return super.createDraft(input);
  }

  @override
  Future<MultiKolabRole> addRole(
    String eventId,
    CreateMultiKolabRoleInput input,
  ) async {
    addedRoles.add(input);
    if (_fixtures.containsKey(eventId)) {
      return MultiKolabRole(
        id: 'role-${addedRoles.length}',
        multiKolabEventId: eventId,
        status: MultiKolabRoleStatus.open,
        title: input.title,
        eligibleAccountType: input.eligibleAccountType,
        positionsNeeded: input.positionsNeeded,
        positionsFilled: 0,
        required_: input.required_,
      );
    }
    return super.addRole(eventId, input);
  }

  @override
  Future<MultiKolabEvent> confirmEvent(String eventId) async {
    confirmed.add(eventId);
    final fixture = _fixtures[eventId];
    if (fixture == null) return super.confirmEvent(eventId);
    return fixture.copyWith(status: MultiKolabEventStatus.confirmed);
  }

  @override
  Future<void> cancelEvent(String eventId, String reason) async {
    cancelled.add((eventId, reason));
  }

  @override
  Future<List<MultiKolabRoleApplication>> roleApplications(String roleId) async =>
      const [];
}

class _SingleDraftRepository extends MockMultiKolabRepository {
  @override
  Future<List<MultiKolabEventSummary>> myEvents() async => [
    const MultiKolabEventSummary(
      id: 'draft-1',
      status: MultiKolabEventStatus.draft,
      title: 'Unfinished Draft',
      roleCounts: MultiKolabRoleCounts(total: 0, open: 0, filled: 0),
      eligibleAccountType: MultiKolabEligibleAccountType.either,
    ),
  ];
}

class _EmptyRepository extends MockMultiKolabRepository {
  @override
  Future<List<MultiKolabEventSummary>> myEvents() async => const [];
}

class _EntitlementRefusingRepository extends MockMultiKolabRepository {
  @override
  Future<MultiKolabEvent> publish(String eventId) async {
    throw ApiException(
      error: const ApiError(
        message: 'Event Creator access is required to publish.',
        statusCode: 403,
        errors: {
          'entitlement': ['event_creator_required'],
        },
      ),
    );
  }
}

class _CapacityConflictRepository extends MockMultiKolabRepository {
  @override
  Future<ChildKolabResult> accept(String applicationId) async {
    throw ApiException(
      error: const ApiError(
        message: 'This role has no remaining positions.',
        statusCode: 409,
        errors: {
          'role': ['role_capacity_exceeded'],
        },
      ),
    );
  }
}
