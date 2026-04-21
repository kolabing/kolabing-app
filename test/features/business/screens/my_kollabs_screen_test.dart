import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/screens/my_kollabs_screen.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';

void main() {
  testWidgets(
    'tapping Edit opens the business edit route with the existing opportunity',
    (tester) async {
      final opportunity = Opportunity(
        id: '42',
        title: 'Spring Launch',
        description: 'Need a community partner for our launch event.',
        businessOffer: const BusinessOffer(venue: true),
        communityDeliverables: const CommunityDeliverables(
          socialMediaContent: true,
        ),
        categories: const ['Food'],
        availabilityMode: AvailabilityMode.oneTime,
        availabilityStart: DateTime(2026, 5, 1),
        availabilityEnd: DateTime(2026, 5, 2),
        selectedTime: const TimeOfDay(hour: 10, minute: 0),
        venueMode: VenueMode.businessVenue,
        address: 'Madrid',
        preferredCity: 'Madrid',
        status: OpportunityStatus.draft,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MyKollabsScreen(),
          ),
          GoRoute(
            path: KolabingRoutes.kolabNew,
            builder: (context, state) => const Scaffold(
              body: Text('new-collab-screen'),
            ),
          ),
          GoRoute(
            path: '/business/offers/:id/edit',
            builder: (context, state) {
              final extra = state.extra as Opportunity?;
              return Scaffold(
                body: Text(
                  'edit-collab-screen:${state.pathParameters['id']}:${extra?.id}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myOpportunitiesProvider.overrideWith(
              () => _FakeMyOpportunitiesNotifier(
                OpportunityListState(
                  opportunities: [opportunity],
                  currentPage: 1,
                  lastPage: 1,
                  total: 1,
                ),
              ),
            ),
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(
                const ProfileState(
                  isLoading: false,
                  isInitialized: true,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EDIT'), findsOneWidget);

      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      expect(find.text('edit-collab-screen:42:42'), findsOneWidget);
      expect(find.text('new-collab-screen'), findsNothing);
    },
  );
}

class _FakeMyOpportunitiesNotifier extends MyOpportunitiesNotifier {
  _FakeMyOpportunitiesNotifier(this._initialState);

  final OpportunityListState _initialState;

  @override
  OpportunityListState build() => _initialState;

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
