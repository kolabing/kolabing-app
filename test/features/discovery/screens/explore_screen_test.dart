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
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';

void main() {
  testWidgets('explore screen renders segmented feed and updates feed filter', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          () => _FakeAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              user: _user(UserType.community),
            ),
          ),
        ),
        profileProvider.overrideWith(
          () => _FakeProfileNotifier(
            const ProfileState(
              profile: UserModel(
                id: 'community-1',
                email: 'community@example.com',
                userType: UserType.community,
                communityProfile: CommunityProfile(
                  id: 'community-profile-1',
                  name: 'Barcelona Creators',
                ),
              ),
              isLoading: false,
              isInitialized: true,
            ),
          ),
        ),
        discoveryFiltersProvider.overrideWith(
          _FakeDiscoveryFiltersNotifier.new,
        ),
        discoveryListProvider.overrideWith(_FakeDiscoveryListNotifier.new),
        unreadNotificationCountProvider.overrideWith((ref) => 0),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const ExploreScreen(
                detailRoutePrefix: '/community/explore/offer',
                lockedCreatorType: 'business',
              ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(container.read(discoveryFiltersProvider).feed, DiscoveryFeed.all);
  });

  testWidgets(
    'business explore keeps the kolab visible while hiding the community and locking apply without a subscription',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: _user(UserType.business),
              ),
            ),
          ),
          profileProvider.overrideWith(
            () => _FakeProfileNotifier(
              const ProfileState(
                profile: UserModel(
                  id: 'business-1',
                  email: 'business@example.com',
                  userType: UserType.business,
                  hasActiveSubscription: false,
                  businessProfile: BusinessProfile(
                    id: 'business-profile-1',
                    name: 'Casa Sol',
                  ),
                ),
                isLoading: false,
                isInitialized: true,
              ),
            ),
          ),
          discoveryFiltersProvider.overrideWith(
            _FakeDiscoveryFiltersNotifier.new,
          ),
          discoveryListProvider.overrideWith(
            () => _FakeDiscoveryListNotifier(
              items: <DiscoveryItem>[
                DiscoveryItem(
                  id: 'community-1',
                  creatorType: 'community',
                  intentType: 'community_seeking',
                  title: 'Training & Brunch',
                  description: 'We need a venue partner for our next meetup.',
                  preferredCity: 'Barcelona',
                  availability: DiscoveryAvailability(
                    mode: 'one_time',
                    start: DateTime(2030, 6, 12),
                    end: DateTime(2030, 6, 14),
                  ),
                  creatorProfile: const DiscoveryCreatorProfile(
                    id: 'creator-1',
                    displayName: 'Move Club',
                  ),
                  communityRequest: const CommunityRequestSummary(
                    needTypes: <String>['venue', 'food_drink'],
                    communityTypes: <DiscoveryLabelValue>[
                      DiscoveryLabelValue(key: 'wellness', label: 'Wellness'),
                    ],
                    communitySize: 1200,
                    typicalAttendance: 75,
                    offersInReturn: <String>[
                      'social_media',
                      'event_activation',
                    ],
                    venuePreference: 'business_provides',
                  ),
                  match: const DiscoveryMatch(
                    feed: 'recommended',
                    score: 94,
                    breakdown: <DiscoveryMatchSignal>[
                      DiscoveryMatchSignal(
                        key: 'city_match',
                        label: 'City match',
                        weight: 0.5,
                        score: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            builder: (BuildContext context, GoRouterState state) =>
                const ExploreScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Training & Brunch'), findsOneWidget);
      expect(find.text('Community hidden'), findsOneWidget);
      expect(find.text('Move Club'), findsNothing);

      await tester.tap(find.text('Training & Brunch'));
      await tester.pumpAndSettle();

      expect(find.text('Community hidden'), findsWidgets);
      expect(find.text('UNLOCK TO APPLY'), findsOneWidget);
      expect(find.text('Jun 12 - Jun 14'), findsOneWidget);
      expect(find.text('Move Club'), findsNothing);
    },
  );

  testWidgets(
    'business explore still hides the community identity after subscribing',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: _user(UserType.business),
              ),
            ),
          ),
          profileProvider.overrideWith(
            () => _FakeProfileNotifier(
              const ProfileState(
                profile: UserModel(
                  id: 'business-1',
                  email: 'business@example.com',
                  userType: UserType.business,
                  hasActiveSubscription: true,
                  businessProfile: BusinessProfile(
                    id: 'business-profile-1',
                    name: 'Casa Sol',
                  ),
                ),
                isLoading: false,
                isInitialized: true,
              ),
            ),
          ),
          discoveryFiltersProvider.overrideWith(
            _FakeDiscoveryFiltersNotifier.new,
          ),
          discoveryListProvider.overrideWith(
            () => _FakeDiscoveryListNotifier(
              items: <DiscoveryItem>[
                DiscoveryItem(
                  id: 'community-1',
                  creatorType: 'community',
                  intentType: 'community_seeking',
                  title: 'Training & Brunch',
                  description: 'We need a venue partner for our next meetup.',
                  preferredCity: 'Barcelona',
                  availability: DiscoveryAvailability(
                    mode: 'one_time',
                    start: DateTime(2030, 6, 12),
                    end: DateTime(2030, 6, 14),
                  ),
                  creatorProfile: const DiscoveryCreatorProfile(
                    id: 'creator-1',
                    displayName: 'Move Club',
                  ),
                  communityRequest: const CommunityRequestSummary(
                    needTypes: <String>['venue', 'food_drink'],
                    communityTypes: <DiscoveryLabelValue>[
                      DiscoveryLabelValue(key: 'wellness', label: 'Wellness'),
                    ],
                    communitySize: 1200,
                    typicalAttendance: 75,
                    offersInReturn: <String>[
                      'social_media',
                      'event_activation',
                    ],
                    venuePreference: 'business_provides',
                  ),
                ),
              ],
            ),
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
            builder: (BuildContext context, GoRouterState state) =>
                const ExploreScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Training & Brunch'), findsOneWidget);
      expect(find.text('Community hidden'), findsOneWidget);
      expect(find.text('Move Club'), findsNothing);

      await tester.tap(find.text('Training & Brunch'));
      await tester.pumpAndSettle();

      expect(find.text('Community hidden'), findsWidgets);
      expect(find.text('Move Club'), findsNothing);
      expect(find.text('View creator profile'), findsNothing);
    },
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeDiscoveryFiltersNotifier extends DiscoveryFiltersNotifier {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();
}

class _FakeDiscoveryListNotifier extends DiscoveryListNotifier {
  _FakeDiscoveryListNotifier({this.items});

  final List<DiscoveryItem>? items;

  @override
  DiscoveryListState build() => DiscoveryListState(
    items:
        items ??
        <DiscoveryItem>[
          DiscoveryItem(
            id: 'business-1',
            creatorType: 'business',
            intentType: 'venue_promotion',
            title: 'Sunset rooftop collab',
            description: 'Host your creator event on our rooftop',
            preferredCity: 'Barcelona',
            availability: DiscoveryAvailability(
              mode: 'one_time',
              start: DateTime(2026, 5, 20),
              end: DateTime(2026, 5, 20),
            ),
            creatorProfile: const DiscoveryCreatorProfile(
              id: 'creator-1',
              displayName: 'Casa Sol',
            ),
            businessOffer: const BusinessOfferSummary(
              offerTypes: <String>['venue', 'food_drink'],
              venueType: 'rooftop',
              expectedDeliverables: <String>['social_media'],
            ),
            match: const DiscoveryMatch(
              feed: 'recommended',
              score: 92,
              reasons: <String>['city_match'],
            ),
          ),
        ],
    currentPage: 1,
    lastPage: 1,
    total: items?.length ?? 1,
  );

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

UserModel _user(UserType type) =>
    UserModel(id: 'user-1', email: 'user@example.com', userType: type);
