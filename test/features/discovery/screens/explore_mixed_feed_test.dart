import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/application/widgets/quick_chat_sheet.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/screens/explore_screen.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/explore_detail_sheet.dart';
import 'package:kolabing_app/widgets/explore_swipe_card.dart';
import 'package:kolabing_app/widgets/kolabing_button.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

ExploreFeedItem _role({
  required String id,
  String eligible = 'community',
  String status = 'open',
  int needed = 1,
  int filled = 0,
  String organizerProfileId = 'organizer-1',
  String roleTitle = 'Run Club Partner',
  String eventId = 'event-1',
}) => ExploreFeedItem.fromJson(<String, dynamic>{
  'item_type': 'multi_kolab_role',
  'id': id,
  'multi_kolab_event_id': eventId,
  'role_title': roleTitle,
  'event_title': 'Kolabing Launch Weekend',
  'status': status,
  'looking_for': <String, dynamic>{
    'eligible_account_type': eligible,
    'required': true,
  },
  'positions_needed': needed,
  'positions_filled': filled,
  'positions_remaining': needed - filled,
  'city': 'Barcelona',
  'target_date': <String, dynamic>{'mode': 'exact', 'date': '2026-09-12'},
  'creator_profile': <String, dynamic>{'id': organizerProfileId},
});

ExploreFeedItem _offer({String id = 'kolab-1'}) => ExploreOfferItem(
  DiscoveryItem(
    id: id,
    creatorType: 'business',
    intentType: 'venue_promotion',
    title: 'Sunset rooftop collab',
    description: 'Host your creator event on our rooftop',
    preferredCity: 'Barcelona',
    availability: DiscoveryAvailability(
      mode: 'one_time',
      start: DateTime(2030, 5, 20),
      end: DateTime(2030, 5, 20),
    ),
    creatorProfile: const DiscoveryCreatorProfile(
      id: 'creator-1',
      displayName: 'Casa Sol',
    ),
    businessOffer: const BusinessOfferSummary(
      offerTypes: <String>['venue'],
      venueType: 'rooftop',
    ),
  ),
);

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _CapturedRoutes {
  final List<String> locations = <String>[];
}

Future<_CapturedRoutes> _pumpExplore(
  WidgetTester tester, {
  required List<ExploreFeedItem> feedItems,
  required UserType viewerType,
  bool subscribed = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final isCommunity = viewerType == UserType.community;
  final user = UserModel(
    id: 'user-1',
    email: 'user@example.com',
    userType: viewerType,
    hasActiveSubscription: subscribed,
    communityProfile: isCommunity
        ? const CommunityProfile(id: 'viewer-profile-1', name: 'BCN Creators')
        : null,
    businessProfile: isCommunity
        ? null
        : const BusinessProfile(id: 'viewer-profile-1', name: 'Casa Sol'),
  );

  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(
        () => _FakeAuthNotifier(
          AuthState(status: AuthStatus.authenticated, user: user),
        ),
      ),
      profileProvider.overrideWith(
        () => _FakeProfileNotifier(
          ProfileState(profile: user, isLoading: false, isInitialized: true),
        ),
      ),
      discoveryFiltersProvider.overrideWith(_FakeDiscoveryFiltersNotifier.new),
      discoveryListProvider.overrideWith(
        () => _FakeDiscoveryListNotifier(feedItems),
      ),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
    ],
  );
  addTearDown(container.dispose);

  final captured = _CapturedRoutes();
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => ExploreScreen(
          detailRoutePrefix: isCommunity
              ? '/community/explore/offer'
              : '/business/explore/offer',
          lockedCreatorType: isCommunity ? 'business' : 'community',
        ),
      ),
      GoRoute(
        path: '/multi-kolab-events/:id',
        builder: (context, state) {
          captured.locations.add(state.uri.toString());
          return const Scaffold(body: Text('multi-kolab detail'));
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  return captured;
}

/// Walks the vertical Explore list, collecting the feed key of every card it
/// builds. The list is lazy, so items are only constructed as they scroll into
/// view, and several cards can be on screen at once (the next one peeks) —
/// this is the only honest way to assert on the feed's full contents.
Future<List<String>> _deckFeedKeys(
  WidgetTester tester, {
  int maxPages = 8,
}) async {
  final keys = <String>[];

  int collectVisible() {
    var added = 0;
    for (final element in tester.allWidgets) {
      final key = element.key;
      if (key is ValueKey<String> &&
          key.value.startsWith('explore-feed-item-')) {
        final feedKey = key.value.substring('explore-feed-item-'.length);
        if (!keys.contains(feedKey)) {
          keys.add(feedKey);
          added++;
        }
      }
    }
    return added;
  }

  collectVisible();
  for (var page = 0; page < maxPages; page++) {
    final deck = find.byKey(const Key('explore-deck'));
    if (deck.evaluate().isEmpty) break;
    await tester.drag(deck, const Offset(0, -600));
    await tester.pumpAndSettle();
    if (collectVisible() == 0) break;
  }

  return keys;
}

void main() {
  group('mixed Explore feed', () {
    testWidgets('a community role sits beside ordinary offers in the '
        'community feed', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-1', eligible: 'community'),
        ],
      );

      // Both items are present in one feed, in backend order...
      expect(await _deckFeedKeys(tester), <String>[
        'offer:kolab-1',
        'multi-kolab-role:role-1',
      ]);
      // ...and each is rendered by the ordinary offer-card widget.
      expect(find.byType(ExploreSwipeCard), findsWidgets);
    });

    testWidgets('a business role sits beside ordinary offers in the '
        'business feed', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.business,
        feedItems: [
          _offer(),
          _role(id: 'role-b', eligible: 'business'),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>[
        'offer:kolab-1',
        'multi-kolab-role:role-b',
      ]);
    });

    testWidgets('an either role appears in both feeds', (tester) async {
      for (final type in [UserType.community, UserType.business]) {
        await _pumpExplore(
          tester,
          viewerType: type,
          feedItems: [_role(id: 'role-e', eligible: 'either')],
        );

        expect(
          await _deckFeedKeys(tester),
          <String>['multi-kolab-role:role-e'],
          reason: 'either role should be visible to $type',
        );
      }
    });

    // Three tests used to live here: a business role absent from the community
    // feed, a filled role never appearing, and the organiser's own role never
    // appearing. All three asserted that the DECK dropped items the API had
    // sent it. It no longer does — `GET /discovery/opportunities` is the only
    // filter (`makeMultiKolabRoleBaseQuery()`: open, positions remaining,
    // eligible account type, not the viewer's own event), and the client
    // printed that endpoint's `meta.total` as its result count while filtering
    // the list itself, so the two could disagree. Those exclusions are now
    // asserted in kolabing-v2's `DiscoveryServerSideDeckFilterTest`; what is
    // asserted HERE is the new contract:
    testWidgets('the deck draws every item the API returns', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          // A role the old client filter would have dropped three times over:
          // business-only, filled, and organised by the viewer. If the endpoint
          // sent it, the deck shows it — and the count above the deck stays true.
          _role(
            id: 'role-whatever',
            eligible: 'business',
            status: 'filled',
            needed: 1,
            filled: 1,
            organizerProfileId: 'viewer-profile-1',
          ),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>[
        'offer:kolab-1',
        'multi-kolab-role:role-whatever',
      ]);
    });

    testWidgets('each open role of one event gets its OWN card', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _role(id: 'role-1', roleTitle: 'Run Club Partner'),
          _role(id: 'role-2', roleTitle: 'Yoga Partner'),
          _role(id: 'role-3', roleTitle: 'Content Creator'),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>[
        'multi-kolab-role:role-1',
        'multi-kolab-role:role-2',
        'multi-kolab-role:role-3',
      ]);
    });

    testWidgets('a multi-position role still produces exactly one card', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_role(id: 'role-multi', needed: 4, filled: 1)],
      );

      // One role, one card — never one card per position.
      expect(await _deckFeedKeys(tester), <String>[
        'multi-kolab-role:role-multi',
      ]);
      expect(find.text('3 spots open'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping a role opens the event detail focused on that role', (
      tester,
    ) async {
      final captured = await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_role(id: 'role-1', eventId: 'event-1')],
      );

      await tester.tap(find.text('Run Club Partner'));
      await tester.pumpAndSettle();

      expect(captured.locations, ['/multi-kolab-events/event-1?role=role-1']);
    });
  });

  group('bookmarking', () {
    testWidgets('an ordinary offer keeps its bookmark control', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_offer()],
      );

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('a role card offers no bookmark, since saving is keyed by a '
        'concrete Kolab id', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_role(id: 'role-1')],
      );

      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });
  });

  group('quick chat', () {
    const quickChat = Key('explore-card-quick-chat');

    testWidgets('a community viewer gets the Quick chat button on an '
        'ordinary offer', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_offer()],
      );

      expect(find.byKey(quickChat), findsOneWidget);
      expect(find.bySemanticsLabel('Quick chat'), findsOneWidget);
    });

    testWidgets('a subscribed business gets the Quick chat button', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.business,
        feedItems: [_offer()],
      );

      expect(find.byKey(quickChat), findsOneWidget);
    });

    testWidgets('a free business gets no Quick chat button', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.business,
        subscribed: false,
        feedItems: [_offer()],
      );

      expect(find.byType(ExploreSwipeCard), findsOneWidget);
      expect(find.byKey(quickChat), findsNothing);
    });

    testWidgets('a Multi-Kolab role card gets no Quick chat button', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_role(id: 'role-1')],
      );

      expect(find.byKey(quickChat), findsNothing);
    });

    testWidgets('tapping Quick chat opens the sheet, not the detail', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_offer()],
      );

      await tester.tap(find.byKey(quickChat));
      await tester.pumpAndSettle();

      expect(find.byType(QuickChatSheet), findsOneWidget);
      expect(find.text('with Casa Sol'), findsOneWidget);
      expect(find.byType(ExploreDetailSheet), findsNothing);
    });

    testWidgets('tapping the card itself still opens the detail', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_offer()],
      );

      await tester.tap(find.byType(ExploreSwipeCard));
      await tester.pumpAndSettle();

      expect(find.byType(ExploreDetailSheet), findsOneWidget);
      expect(find.byType(QuickChatSheet), findsNothing);
      expect(find.text('Send full kolab request'), findsOneWidget);
    });
  });

  group('quick chat sheet', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final offer = (_offer() as ExploreOfferItem).offer;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: QuickChatSheet(
                opportunity: offer.toOpportunity(),
                partnerName: 'Casa Sol',
                today: DateTime(2030, 5, 1),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    VoidCallback? startAction(WidgetTester tester) => tester
        .widget<KolabingButton>(find.byKey(const Key('quick-chat-start')))
        .onPressed;

    testWidgets('Start chat stays disabled until When is picked', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Quick chat'), findsOneWidget);
      expect(find.text('with Casa Sol'), findsOneWidget);
      expect(startAction(tester), isNull);

      // The offer's only date is Monday 20 May 2030.
      await tester.tap(find.byKey(const Key('quick-chat-day-2030-5-20')));
      await tester.pump();
      expect(startAction(tester), isNotNull);
    });

    testWidgets('days outside the kolab window cannot be picked', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.tap(find.byKey(const Key('quick-chat-day-2030-5-21')));
      await tester.pump();
      expect(startAction(tester), isNull);
    });

    testWidgets('switching to Day of the week clears the pick and offers '
        'only the weekdays the kolab runs on', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byKey(const Key('quick-chat-day-2030-5-20')));
      await tester.pump();
      expect(startAction(tester), isNotNull);

      await tester.tap(find.byKey(const Key('quick-chat-mode-weekday')));
      await tester.pump();
      expect(startAction(tester), isNull);

      // Tuesday is not a day this one-date kolab runs on.
      await tester.tap(find.byKey(const Key('quick-chat-weekday-2')));
      await tester.pump();
      expect(startAction(tester), isNull);

      await tester.tap(find.byKey(const Key('quick-chat-weekday-1')));
      await tester.pump();
      expect(startAction(tester), isNotNull);
    });

    testWidgets('group size defaults to 20 and steps by one', (tester) async {
      await pumpSheet(tester);

      expect(find.text('20'), findsWidgets);
      await tester.tap(find.byKey(const Key('quick-chat-people-plus')));
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('quick-chat-people-count')))
            .data,
        '21',
      );
    });
  });

  group('feed chrome is unchanged by mixed content', () {
    testWidgets('the search bar, tabs and quick filters still render', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-1'),
        ],
      );

      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('switching to Saved hides the discovery deck entirely', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-1'),
        ],
      );

      await tester.tap(find.text('Saved'));
      await tester.pump();

      expect(find.byKey(const Key('explore-deck')), findsNothing);
    });
  });

  group('the obsolete standalone Multi-Kolab entry point is gone', () {
    testWidgets('Explore shows no Multi-Kolab banner or separate entry point', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-1'),
        ],
      );

      // The withdrawn Task 9 UX: a yellow promo banner above the feed that
      // pushed users into a separate Multi-Kolab Explore screen.
      expect(find.text('Multi-Kolab Events'), findsNothing);
      expect(find.text('Recruit or join multi-partner events'), findsNothing);
      expect(find.byKey(const Key('multi-kolab-explore-banner')), findsNothing);
    });

    testWidgets('a role card carries the small Multi-Kolab indicator that '
        'replaced the banner', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_role(id: 'role-1')],
      );

      expect(
        find.byKey(const Key('explore-card-multi-kolab-badge')),
        findsOneWidget,
      );
    });

    testWidgets('an ordinary offer card carries no Multi-Kolab indicator', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [_offer()],
      );

      expect(
        find.byKey(const Key('explore-card-multi-kolab-badge')),
        findsNothing,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;
}

class _FakeDiscoveryFiltersNotifier extends DiscoveryFiltersNotifier {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();
}

class _FakeDiscoveryListNotifier extends DiscoveryListNotifier {
  _FakeDiscoveryListNotifier(this._items);

  final List<ExploreFeedItem> _items;

  @override
  DiscoveryListState build() =>
      DiscoveryListState(items: _items, currentPage: 1, lastPage: 1, total: 1);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}
