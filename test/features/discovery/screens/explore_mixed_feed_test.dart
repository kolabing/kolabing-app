import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
import 'package:kolabing_app/widgets/explore_swipe_card.dart';

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
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final isCommunity = viewerType == UserType.community;
  final user = UserModel(
    id: 'user-1',
    email: 'user@example.com',
    userType: viewerType,
    hasActiveSubscription: true,
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

/// Walks the vertical Explore deck, collecting the feed key of every card it
/// builds. The deck is a lazy [PageView], so items are only constructed as
/// they scroll into view — this is the only honest way to assert on the
/// deck's full contents.
Future<List<String>> _deckFeedKeys(
  WidgetTester tester, {
  int maxPages = 8,
}) async {
  final keys = <String>[];

  String? currentKey() {
    for (final element in tester.allWidgets) {
      final key = element.key;
      if (key is ValueKey<String> &&
          key.value.startsWith('explore-feed-item-')) {
        return key.value.substring('explore-feed-item-'.length);
      }
    }
    return null;
  }

  for (var page = 0; page < maxPages; page++) {
    final key = currentKey();
    if (key != null && !keys.contains(key)) {
      keys.add(key);
    }
    final deck = find.byKey(const Key('explore-deck'));
    if (deck.evaluate().isEmpty) break;
    await tester.drag(deck, const Offset(0, -600));
    await tester.pumpAndSettle();
    final next = currentKey();
    if (next == null || keys.contains(next)) break;
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

    testWidgets('a business role is absent from the community feed', (
      tester,
    ) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-b', eligible: 'business'),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>['offer:kolab-1']);
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

    testWidgets('a filled role never appears', (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-f', status: 'filled', needed: 1, filled: 1),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>['offer:kolab-1']);
    });

    testWidgets("the organizer's own role never appears", (tester) async {
      await _pumpExplore(
        tester,
        viewerType: UserType.community,
        feedItems: [
          _offer(),
          _role(id: 'role-own', organizerProfileId: 'viewer-profile-1'),
        ],
      );

      expect(await _deckFeedKeys(tester), <String>['offer:kolab-1']);
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
