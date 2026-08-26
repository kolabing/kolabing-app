import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/screens/my_kollabs_screen.dart';
import 'package:kolabing_app/features/collaboration/models/collaboration.dart';
import 'package:kolabing_app/features/collaboration/providers/collaborations_list_provider.dart';
import 'package:kolabing_app/features/collaboration/widgets/collaborations_list_tab.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/my_kolabs_multi_kolab_provider.dart';
import 'package:kolabing_app/features/kolab/providers/my_kolabs_provider.dart';
import 'package:kolabing_app/features/kolab/screens/my_kolabs_hub_screen.dart';
import 'package:kolabing_app/features/kolab/widgets/my_kolab_card.dart';
import 'package:kolabing_app/features/kolab/widgets/my_multi_kolab_card.dart';
import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_creator_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event_summary.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/kolab_card_shell.dart';

/// A Multi-Kolab Event is still a Kolab: these tests pin the integration
/// INTO My Kolabs — no standalone promo entry point, ordinary card shell,
/// and lifecycle mapped onto the sections that already exist.
void main() {
  MultiKolabEventSummary event(
    String id, {
    MultiKolabEventStatus status = MultiKolabEventStatus.recruiting,
    String title = 'Kolabing Launch Weekend',
    int open = 3,
  }) => MultiKolabEventSummary(
    id: id,
    status: status,
    title: title,
    city: 'Barcelona',
    eventDate: DateTime(2026, 9, 12),
    dateMode: MultiKolabDateMode.exact,
    roleCounts: MultiKolabRoleCounts(total: 4, open: open, filled: 4 - open),
    eligibleAccountType: MultiKolabEligibleAccountType.either,
  );

  const ordinaryKolab = Kolab(
    id: '42',
    intentType: IntentType.venuePromotion,
    status: 'published',
    title: 'Spring Launch',
    description: 'Need a community partner for our launch event.',
    preferredCity: 'Madrid',
    venueName: 'Launch Hub',
    venueAddress: 'Madrid',
  );

  Widget host({
    required Widget home,
    List<Kolab> kolabs = const [],
    List<MultiKolabEventSummary> events = const [],
    bool entitled = true,
    bool stubCollaborations = false,
    List<GoRoute> extraRoutes = const [],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: KolabingRoutes.kolabNew,
          builder: (_, _) => const Scaffold(body: Text('create-kolab-screen')),
        ),
        GoRoute(
          path: KolabingRoutes.multiKolabOrganizerEventNew,
          builder: (_, _) =>
              const Scaffold(body: Text('create-multi-kolab-screen')),
        ),
        GoRoute(
          path: KolabingRoutes.multiKolabOrganizerEvents,
          builder: (_, _) =>
              const Scaffold(body: Text('multi-kolab-organizer-area')),
        ),
        GoRoute(
          path: KolabingRoutes.multiKolabOrganizerEvent,
          builder: (_, state) => Scaffold(
            body: Text('manage-event:${state.pathParameters['id']}'),
          ),
        ),
        ...extraRoutes,
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        myKolabsProvider.overrideWith(
          () => _FakeMyKolabsNotifier(
            MyKolabsState(kolabs: kolabs, total: kolabs.length),
          ),
        ),
        profileProvider.overrideWith(
          () => _FakeProfileNotifier(
            const ProfileState(isLoading: false, isInitialized: true),
          ),
        ),
        multiKolabMyEventsProvider.overrideWith((ref) async => events),
        multiKolabEntitlementProvider.overrideWith(
          (ref) async =>
              EventCreatorEntitlement(hasEventCreatorEntitlement: entitled),
        ),
        if (stubCollaborations)
          collaborationsListProvider.overrideWith(
            (ref) async => const <Collaboration>[],
          ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('My Kolabs Offers list', () {
    testWidgets('no longer renders the standalone Multi-Kolab promo banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKolabsHubScreen(
            offersTab: MyKollabsScreen(embedded: true),
          ),
          kolabs: const [ordinaryKolab],
          events: [event('event-1')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multiKolabOrganizerEntryRow')), findsNothing);
      expect(find.text('Multi-Kolab events'), findsNothing);
      expect(find.text('One event, several partners'), findsNothing);
    });

    testWidgets('renders an organizer-owned event in the normal kolab list', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          kolabs: const [ordinaryKolab],
          events: [event('event-1')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kolabing Launch Weekend'), findsOneWidget);
      expect(find.text('Spring Launch'), findsOneWidget);
      // Both live inside the SAME ListView, not in separate sections.
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ordinary and Multi-Kolab cards share one card shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          kolabs: const [ordinaryKolab],
          events: [event('event-1')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KolabCardShell), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(MyMultiKolabCard),
          matching: find.byType(KolabCardShell),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MyKolabCard),
          matching: find.byType(KolabCardShell),
        ),
        findsOneWidget,
      );
    });

    testWidgets('marks the event with only a small badge and open-role copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          events: [event('event-1')],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('myKolabsMultiKolabBadge_event-1')),
        findsOneWidget,
      );
      expect(find.text('3 open roles'), findsOneWidget);
      // Role counts only — the summary payload carries no partner-spot total.
      expect(find.textContaining('partner'), findsNothing);
    });

    testWidgets('tapping the card opens Multi-Kolab management', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          events: [event('event-7')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MyMultiKolabCard));
      await tester.pumpAndSettle();

      expect(find.text('manage-event:event-7'), findsOneWidget);
    });

    testWidgets('recruiting shows under Published, draft under Draft', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          events: [
              event('event-1'),
              event(
                'event-2',
                status: MultiKolabEventStatus.draft,
                title: 'Winter Market',
              ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kolabing Launch Weekend'), findsOneWidget);
      expect(find.text('Winter Market'), findsNothing);

      await tester.tap(find.text('DRAFT').first);
      await tester.pumpAndSettle();

      expect(find.text('Winter Market'), findsOneWidget);
      expect(find.text('Kolabing Launch Weekend'), findsNothing);
    });

    testWidgets('confirmed and completed events stay out of the Offers list', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          events: [
            event(
              'event-3',
              status: MultiKolabEventStatus.confirmed,
              title: 'Confirmed Event',
            ),
            event(
              'event-4',
              status: MultiKolabEventStatus.completed,
              title: 'Completed Event',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed Event'), findsNothing);
      expect(find.text('Completed Event'), findsNothing);
      expect(find.text('No kolabs yet'), findsOneWidget);
    });

    testWidgets('ordinary kolab actions still work', (tester) async {
      await tester.pumpWidget(
        host(
          home: const MyKollabsScreen(embedded: true),
          kolabs: const [
            Kolab(
              id: '42',
              intentType: IntentType.venuePromotion,
              status: 'draft',
              title: 'Spring Launch',
              description: 'A draft.',
              preferredCity: 'Madrid',
            ),
          ],
          events: [event('event-1')],
          extraRoutes: [
            GoRoute(
              path: KolabingRoutes.kolabFlow,
              builder: (_, state) =>
                  Scaffold(body: Text('edit:${(state.extra as Kolab?)?.id}')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      expect(find.text('edit:42'), findsOneWidget);
    });
  });

  group('Active / Finished tabs', () {
    Widget bucketHost(
      CollaborationBucket bucket,
      List<MultiKolabEventSummary> events,
    ) => host(
      home: Scaffold(
        body: CollaborationsListTab(
          bucket: bucket,
          emptyTitle: 'Nothing here',
          emptyMessage: 'Nothing here yet',
        ),
      ),
      events: events,
      stubCollaborations: true,
    );

    testWidgets('a confirmed event appears in Active', (tester) async {
      await tester.pumpWidget(
        bucketHost(CollaborationBucket.active, [
          event(
            'event-3',
            status: MultiKolabEventStatus.confirmed,
            title: 'Confirmed Event',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed Event'), findsOneWidget);
      expect(find.byType(KolabCardShell), findsOneWidget);
    });

    testWidgets('completed and cancelled events appear in Finished', (
      tester,
    ) async {
      await tester.pumpWidget(
        bucketHost(CollaborationBucket.finished, [
          event(
            'event-4',
            status: MultiKolabEventStatus.completed,
            title: 'Completed Event',
          ),
          event(
            'event-5',
            status: MultiKolabEventStatus.cancelled,
            title: 'Cancelled Event',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed Event'), findsOneWidget);
      expect(find.text('Cancelled Event'), findsOneWidget);
    });

    testWidgets('empty state survives when there is nothing at all', (
      tester,
    ) async {
      await tester.pumpWidget(
        bucketHost(CollaborationBucket.active, const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
    });
  });

  group('creation entry point', () {
    Future<void> openSheet(WidgetTester tester, {bool entitled = true}) async {
      await tester.pumpWidget(
        host(
          home: const MyKolabsHubScreen(
            offersTab: MyKollabsScreen(embedded: true),
          ),
          entitled: entitled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    testWidgets('the "+" action offers both kinds of Kolab', (tester) async {
      await openSheet(tester);

      expect(find.byKey(const Key('createKolabChoiceSheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('createKolabChoiceOrdinary')));
      await tester.pumpAndSettle();

      expect(find.text('create-kolab-screen'), findsOneWidget);
    });

    testWidgets('an entitled organizer reaches the event creator', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('createKolabChoiceMultiKolab')));
      await tester.pumpAndSettle();

      expect(find.text('create-multi-kolab-screen'), findsOneWidget);
    });

    testWidgets('a non-entitled profile still sees the option and is gated', (
      tester,
    ) async {
      await openSheet(tester, entitled: false);

      expect(
        find.byKey(const Key('createKolabChoiceMultiKolab')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('createKolabChoiceMultiKolab')));
      await tester.pumpAndSettle();

      expect(find.text('multi-kolab-organizer-area'), findsOneWidget);
    });
  });

  group('status mapping', () {
    test('maps every Multi-Kolab status onto an existing section', () {
      expect(
        multiKolabSectionFor(MultiKolabEventStatus.draft),
        MyKolabsSection.drafts,
      );
      expect(
        multiKolabSectionFor(MultiKolabEventStatus.recruiting),
        MyKolabsSection.offers,
      );
      expect(
        multiKolabSectionFor(MultiKolabEventStatus.confirmed),
        MyKolabsSection.active,
      );
      for (final status in [
        MultiKolabEventStatus.completed,
        MultiKolabEventStatus.cancelled,
        MultiKolabEventStatus.expired,
      ]) {
        expect(multiKolabSectionFor(status), MyKolabsSection.finished);
      }
    });

    test('reuses the ordinary status vocabulary for the badge', () {
      expect(
        MyMultiKolabCard.badgeStatusFor(MultiKolabEventStatus.recruiting),
        'published',
      );
      expect(
        MyMultiKolabCard.badgeStatusFor(MultiKolabEventStatus.draft),
        'draft',
      );
      expect(
        MyMultiKolabCard.badgeStatusFor(MultiKolabEventStatus.confirmed),
        'active',
      );
    });
  });
}

class _FakeMyKolabsNotifier extends MyKolabsNotifier {
  _FakeMyKolabsNotifier(this._initialState);

  final MyKolabsState _initialState;

  @override
  MyKolabsState build() {
    // Honour the status filter the screen drives, so Draft/Published
    // filtering still exercises the real provider wiring.
    ref.watch(myKolabsStatusProvider);
    return _initialState;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;
}
