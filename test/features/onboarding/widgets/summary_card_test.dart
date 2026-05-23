import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';
import 'package:kolabing_app/features/onboarding/widgets/summary_card.dart';

void main() {
  testWidgets('summary card wraps long venue details on narrow screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SummaryCard(data: _summaryData),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Passatge dels Miners'), findsAtLeastNWidgets(1));
    expect(find.textContaining('08380 Malgrat de Mar'), findsOneWidget);
  });
}

const OnboardingData _summaryData = OnboardingData(
  userType: UserType.business,
  name: 'Passatge dels Miners',
  about: 'testsdfsdfsdwfwdfsfsdfsfsdfsdfsd',
  phone: '+3488888888',
  instagram: 'test',
  website: 'https://test.com',
  businessTypeIds: ['other-1'],
  businessTypeSlugs: ['other'],
  businessTypeNames: ['Other'],
  location: PlaceSuggestion(
    placeId: 'place-1',
    title: 'Passatge dels Miners',
    formattedAddress: 'Passatge dels Miners, 08380 Malgrat de Mar, Barcelona',
    city: 'Malgrat de Mar',
    cityId: 'city-1',
  ),
  venueName: 'Passatge dels Miners',
  venueType: 'other',
  venueCapacity: 50,
);
