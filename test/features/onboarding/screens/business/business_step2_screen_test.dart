import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/business_type.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:kolabing_app/features/onboarding/screens/business/business_step2_screen.dart';
import 'package:kolabing_app/features/onboarding/services/onboarding_service.dart';

void main() {
  testWidgets('normalizes the business phone field to digits-only E.164 text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            () => _FakeOnboardingNotifier(_businessOnboardingData),
          ),
          onboardingServiceProvider.overrideWith(
            (ref) => _FakeOnboardingService(),
          ),
        ],
        child: const MaterialApp(home: BusinessStep2Screen()),
      ),
    );

    await tester.pumpAndSettle();

    final phoneField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '+34612345678',
    );
    expect(phoneField, findsOneWidget);

    final initialWidget = tester.widget<TextField>(phoneField);
    expect(initialWidget.controller?.text, '+34680562095');

    await tester.enterText(phoneField, '+34 611 22 33 44');
    await tester.pump();

    final updatedWidget = tester.widget<TextField>(phoneField);
    expect(updatedWidget.controller?.text, '+34611223344');
  });
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier(this._state);

  final OnboardingData _state;

  @override
  OnboardingData? build() => _state;
}

class _FakeOnboardingService extends OnboardingService {
  @override
  Future<List<BusinessType>> getBusinessTypes() async => const [
    BusinessType(id: 'cafe-1', name: 'Cafe', slug: 'cafe'),
  ];
}

const OnboardingData _businessOnboardingData = OnboardingData(
  userType: UserType.business,
  name: 'Venue Works',
  phone: '+34 680 56 20 95',
  businessTypeIds: ['cafe-1'],
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
