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
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_detail_screen.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture script for the integrated Explore feed.
///
/// Deliberately named `..._capture.dart`, not `..._test.dart`, so `flutter
/// test` never collects it — matching
/// `test/features/multi_kolab/multi_kolab_organizer_capture.dart`. Run it
/// explicitly to refresh the PNGs under `goldens/`:
///
/// ```
/// flutter test test/features/discovery/screens/explore_mixed_feed_capture.dart \
///   --update-goldens
/// ```
///
/// These are real renders produced by the test binding — no simulator
/// automation is involved. As with the organizer captures, `google_fonts`
/// cannot resolve typefaces in the test binding, so the PNGs document
/// layout, copy, spacing, colour and state in the fallback typeface.
/// Behavioural coverage lives in `explore_mixed_feed_test.dart`.
void main() {
  ExploreFeedItem role({
    required String id,
    String eligible = 'community',
    String roleTitle = 'Run Club Partner',
    int needed = 1,
    int filled = 0,
  }) => ExploreFeedItem.fromJson(<String, dynamic>{
    'item_type': 'multi_kolab_role',
    'id': id,
    'multi_kolab_event_id': 'event-1',
    'role_title': roleTitle,
    'event_title': 'Kolabing Launch Weekend',
    'status': 'open',
    'looking_for': <String, dynamic>{
      'eligible_account_type': eligible,
      'required': true,
    },
    'positions_needed': needed,
    'positions_filled': filled,
    'positions_remaining': needed - filled,
    'city': 'Barcelona',
    'target_date': <String, dynamic>{'mode': 'exact', 'date': '2026-09-12'},
    'creator_profile': <String, dynamic>{'id': 'organizer-1'},
  });

  ExploreFeedItem offer({String id = 'kolab-1'}) => ExploreOfferItem(
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

  Future<void> captureExplore(
    WidgetTester tester,
    String name, {
    required UserType viewerType,
    required List<ExploreFeedItem> feedItems,
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
        discoveryFiltersProvider.overrideWith(
          _FakeDiscoveryFiltersNotifier.new,
        ),
        discoveryListProvider.overrideWith(
          () => _FakeDiscoveryListNotifier(feedItems),
        ),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
      ],
    );
    addTearDown(container.dispose);

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
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('community Explore feed — ordinary offer, no banner', (
    tester,
  ) async {
    await captureExplore(
      tester,
      'explore_community_offer',
      viewerType: UserType.community,
      feedItems: [offer(), role(id: 'role-1')],
    );
  });

  testWidgets('community Explore feed — Multi-Kolab role card', (tester) async {
    await captureExplore(
      tester,
      'explore_community_role_card',
      viewerType: UserType.community,
      feedItems: [role(id: 'role-1', eligible: 'community')],
    );
  });

  testWidgets('business Explore feed — Multi-Kolab role card', (tester) async {
    await captureExplore(
      tester,
      'explore_business_role_card',
      viewerType: UserType.business,
      feedItems: [
        role(id: 'role-b', eligible: 'business', roleTitle: 'Venue Partner'),
      ],
    );
  });

  testWidgets('role-focused event detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          multiKolabRepositoryProvider.overrideWithValue(
            MockMultiKolabRepository(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MultiKolabEventDetailScreen(eventId: 'mk-event-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/explore_role_detail.png'),
    );
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
