import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/screens/community/logistics_screen.dart';
import 'package:kolabing_app/features/onboarding/models/city.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';

void main() {
  testWidgets('logistics screen hides venue preference input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          citiesProvider.overrideWith(
            (ref) async => const [
              OnboardingCity(id: '1', name: 'Barcelona', country: 'Spain'),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LogisticsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Venue Preference'), findsNothing);
    expect(find.text('Business Provides'), findsNothing);
    expect(find.text('Community Provides'), findsNothing);
    expect(find.text('No Venue Needed'), findsNothing);
    expect(find.text('Preferred City'), findsOneWidget);
    expect(find.text('Preferred Area (optional)'), findsOneWidget);
  });
}
