import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/screens/business/ideal_community_screen.dart';

void main() {
  testWidgets('shows the Business / Coworking ideal-community option', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: IdealCommunityScreen())),
      ),
    );

    expect(find.text('Business / Coworking'), findsOneWidget);
  });
}
