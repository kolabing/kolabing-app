import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/screens/business/goal_screen.dart';

void main() {
  testWidgets('shows the More Visits fallback goal option', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: GoalScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('More Visits'), findsOneWidget);
    expect(find.text('Bring a community to your space.'), findsOneWidget);
  });
}
