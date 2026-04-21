import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/routes/routes.dart';

void main() {
  testWidgets(
    'navigating to onboarding shows the user type selection flow',
    (tester) async {
      kolabingRouter.go(KolabingRoutes.onboarding);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: kolabingRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Page Not Found'), findsNothing);
      expect(find.text('CHOOSE YOUR PATH'), findsOneWidget);
    },
  );
}
