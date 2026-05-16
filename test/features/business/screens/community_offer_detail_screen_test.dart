import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/business/screens/community_offer_detail_screen.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/providers/event_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';
import 'package:kolabing_app/features/opportunity/services/opportunity_service.dart';

void main() {
  testWidgets(
    'shows a preview banner and disabled preview CTA for an owned published community offer',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final opportunity = Opportunity(
        id: 'opp-1',
        title: 'Barcelona brunch collab',
        description: 'Host our community for a brunch meetup.',
        businessOffer: const BusinessOffer(venue: true, foodDrink: true),
        communityDeliverables: const CommunityDeliverables(
          socialMediaContent: true,
        ),
        categories: const ['Food'],
        availabilityMode: AvailabilityMode.oneTime,
        availabilityStart: DateTime(2026, 6, 12),
        availabilityEnd: DateTime(2026, 6, 12),
        venueMode: VenueMode.businessVenue,
        preferredCity: 'Barcelona',
        status: OpportunityStatus.published,
        creatorProfile: const CreatorProfile(
          id: 'community-profile-1',
          userType: 'community',
          displayNameValue: 'Barcelona Creators',
        ),
        isOwn: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: _communityUser(),
                ),
              ),
            ),
            opportunityServiceProvider.overrideWith(
              (ref) => _FakeOpportunityService(opportunity),
            ),
            profileEventsProvider.overrideWith((ref, profileId) => const []),
          ],
          child: const MaterialApp(
            home: CommunityOfferDetailScreen(offerId: 'opp-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You are previewing this collaboration as businesses see it'),
        findsOneWidget,
      );
      expect(find.text('PREVIEW MODE'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'PREVIEW MODE'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'shows the five most recent past events from this community and hides older ones',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final events = <Event>[
        _testEvent(
          id: 'event-1',
          name: '2019 Meetup',
          date: DateTime(2019, 1, 1),
        ),
        _testEvent(
          id: 'event-2',
          name: '2026 Meetup',
          date: DateTime(2026, 1, 1),
        ),
        _testEvent(
          id: 'event-3',
          name: '2023 Meetup',
          date: DateTime(2023, 1, 1),
        ),
        _testEvent(
          id: 'event-4',
          name: '2025 Meetup',
          date: DateTime(2025, 1, 1),
        ),
        _testEvent(
          id: 'event-5',
          name: '2024 Meetup',
          date: DateTime(2024, 1, 1),
        ),
        _testEvent(
          id: 'event-6',
          name: '2022 Meetup',
          date: DateTime(2022, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: _businessUser(),
                ),
              ),
            ),
            opportunityServiceProvider.overrideWith(
              (ref) => _FakeOpportunityService(_testOpportunity()),
            ),
            profileEventsProvider.overrideWith((ref, profileId) => events),
          ],
          child: const MaterialApp(
            home: CommunityOfferDetailScreen(offerId: 'opp-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Past events from this community'), findsOneWidget);
      expect(find.text('2026 Meetup'), findsOneWidget);
      expect(find.text('2025 Meetup'), findsOneWidget);
      expect(find.text('2024 Meetup'), findsOneWidget);
      expect(find.text('2023 Meetup'), findsOneWidget);
      expect(find.text('2022 Meetup'), findsOneWidget);
      expect(find.text('2019 Meetup'), findsNothing);
    },
  );

  testWidgets(
    'hides the past events section when the community has no events',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: _businessUser(),
                ),
              ),
            ),
            opportunityServiceProvider.overrideWith(
              (ref) => _FakeOpportunityService(_testOpportunity()),
            ),
            profileEventsProvider.overrideWith((ref, profileId) => const []),
          ],
          child: const MaterialApp(
            home: CommunityOfferDetailScreen(offerId: 'opp-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Past events from this community'), findsNothing);
    },
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeOpportunityService extends OpportunityService {
  _FakeOpportunityService(this.opportunity);

  final Opportunity opportunity;

  @override
  Future<Opportunity> getOpportunity(String id) async => opportunity;
}

UserModel _communityUser() => const UserModel(
  id: 'user-1',
  email: 'community@example.com',
  userType: UserType.community,
  communityProfile: CommunityProfile(
    id: 'community-profile-1',
    name: 'Barcelona Creators',
  ),
);

UserModel _businessUser() => const UserModel(
  id: 'business-1',
  email: 'business@example.com',
  userType: UserType.business,
);

Opportunity _testOpportunity() => Opportunity(
  id: 'opp-1',
  title: 'Barcelona brunch collab',
  description: 'Host our community for a brunch meetup.',
  businessOffer: const BusinessOffer(venue: true, foodDrink: true),
  communityDeliverables: const CommunityDeliverables(
    socialMediaContent: true,
  ),
  categories: const ['Food'],
  availabilityMode: AvailabilityMode.oneTime,
  availabilityStart: DateTime(2026, 6, 12),
  availabilityEnd: DateTime(2026, 6, 12),
  venueMode: VenueMode.businessVenue,
  preferredCity: 'Barcelona',
  status: OpportunityStatus.published,
  creatorProfile: const CreatorProfile(
    id: 'community-profile-1',
    userType: 'community',
    displayNameValue: 'Barcelona Creators',
  ),
);

Event _testEvent({
  required String id,
  required String name,
  required DateTime date,
}) => Event(
  id: id,
  name: name,
  partner: const EventPartner(
    id: 'partner-1',
    name: 'Cafe Sol',
    type: PartnerType.business,
  ),
  date: date,
  attendeeCount: 120,
  photos: [
    const EventPhoto(
      id: 'photo-1',
      url: 'https://example.com/photo.jpg',
    ),
  ],
  createdAt: date,
);
