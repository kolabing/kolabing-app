import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/screens/business/ideal_community_screen.dart';
import 'package:kolabing_app/features/onboarding/models/community_type.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';

void main() {
  testWidgets('shows community-type chips fetched from communityTypesProvider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityTypesProvider.overrideWith(
            (ref) async => const [
              CommunityType(id: '1', name: 'Business / Coworking', slug: 'business_coworking'),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: IdealCommunityScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Business / Coworking'), findsOneWidget);
  });
}
