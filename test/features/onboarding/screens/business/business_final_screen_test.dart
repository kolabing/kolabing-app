import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:kolabing_app/features/onboarding/screens/business/business_final_screen.dart';

void main() {
  testWidgets('business final screen shows referral code field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            () => _FakeOnboardingNotifier(_businessOnboardingData),
          ),
        ],
        child: const MaterialApp(home: BusinessFinalScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Referral Code (optional)'), findsOneWidget);
    expect(find.text('Paste referral code'), findsOneWidget);
  });
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier(this._state);

  final OnboardingData _state;

  @override
  OnboardingData? build() => _state;
}

const OnboardingData _businessOnboardingData = OnboardingData(
  userType: UserType.business,
  name: 'Venue Works',
  businessTypeIds: ['1'],
  businessTypeSlugs: ['cafe'],
  businessTypeNames: ['Cafe'],
  location: PlaceSuggestion(
    placeId: 'place-1',
    title: 'Venue Works',
    formattedAddress: 'Carrer 1',
    city: 'Barcelona',
    cityId: 'city-1',
  ),
  venueName: 'Venue Works',
  venueType: 'cafe',
  venueCapacity: 80,
  venuePhotos: [],
);
