import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
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
    expect(find.text('City match'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(container.read(discoveryFiltersProvider).feed, DiscoveryFeed.all);
  });
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
  @override
  DiscoveryListState build() => DiscoveryListState(
    items: <DiscoveryItem>[
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
    total: 1,
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

UserModel _user(UserType type) =>
    UserModel(id: 'user-1', email: 'user@example.com', userType: type);
