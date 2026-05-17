import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/config/theme/colors.dart';
import 'package:kolabing_app/features/auth/screens/welcome_screen.dart';
import 'package:kolabing_app/features/auth/widgets/kolabing_logo.dart';

GoRouter _buildRouter() => GoRouter(
  initialLocation: KolabingRoutes.welcome,
  routes: [
    GoRoute(
      path: KolabingRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.userTypeSelection,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('user type selection'))),
    ),
    GoRoute(
      path: KolabingRoutes.login,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('login screen'))),
    ),
  ],
);

Future<void> _pumpWelcome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScaleFactor = 1.0,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: _buildRouter(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'welcome screen keeps the cream editorial layout and routes correctly',
    (WidgetTester tester) async {
      await _pumpWelcome(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, KolabingColors.background);

      const removedHeadlines = [
        'BRANDS X',
        'COMMUNITIES',
        'Match fast. Launch louder.',
      ];
      for (final label in removedHeadlines) {
        expect(find.text(label), findsNothing);
      }

      for (final label in ['OFFERS', 'EVENTS', 'PARTNERSHIPS', 'GROWTH']) {
        expect(find.text(label), findsOneWidget);
      }

      final logoFinder = find.byType(KolabingLogo);
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<KolabingLogo>(logoFinder);
      expect(logo.variant, KolabingLogoVariant.lightTransparent);

      expect(
        find.text('Free to join as a brand or community.'),
        findsOneWidget,
      );

      final createAccountFinder = find.text('CREATE ACCOUNT');
      final loginFinder = find.text('LOGIN');
      expect(createAccountFinder, findsOneWidget);
      expect(loginFinder, findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(
        tester.getTopLeft(createAccountFinder).dy,
        lessThan(tester.getTopLeft(loginFinder).dy),
      );

      await tester.tap(createAccountFinder);
      await tester.pumpAndSettle();
      expect(find.text('user type selection'), findsOneWidget);

      await _pumpWelcome(tester);
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();
      expect(find.text('login screen'), findsOneWidget);
    },
  );

  testWidgets('welcome screen remains stable on compact scaled layouts', (
    WidgetTester tester,
  ) async {
    await _pumpWelcome(
      tester,
      size: const Size(320, 640),
      textScaleFactor: 1.25,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(KolabingLogo), findsOneWidget);
    expect(find.text('Free to join as a brand or community.'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
