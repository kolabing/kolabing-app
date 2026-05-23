import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
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
  // The welcome screen was redesigned (commit c1e1c1a) into a dark landing-page
  // hero: pure-black background, yellow wordmark, a "REAL PEOPLE / REAL
  // EXPERIENCES / REAL GROWTH." headline, a GET STARTED primary CTA and a LOGIN
  // text link. These tests assert that current intended design.
  testWidgets(
    'welcome screen renders the dark landing hero and routes correctly',
    (WidgetTester tester) async {
      await _pumpWelcome(tester);

      // Dark hero background (not the old cream editorial layout).
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF000000));

      // Old editorial copy is gone.
      const removedCopy = [
        'BRANDS X',
        'COMMUNITIES',
        'Match fast. Launch louder.',
        'OFFERS',
        'EVENTS',
        'PARTNERSHIPS',
        'CREATE ACCOUNT',
        'Free to join as a brand or community.',
      ];
      for (final label in removedCopy) {
        expect(find.text(label), findsNothing);
      }

      // New stacked headline.
      for (final line in ['REAL PEOPLE', 'REAL EXPERIENCES', 'REAL GROWTH.']) {
        expect(find.text(line), findsOneWidget);
      }

      // Yellow wordmark logo.
      final logoFinder = find.byType(KolabingLogo);
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<KolabingLogo>(logoFinder);
      expect(logo.variant, KolabingLogoVariant.yellowTransparent);

      // Primary CTA + login link.
      final getStartedFinder = find.text('GET STARTED');
      final loginFinder = find.text('LOGIN');
      expect(getStartedFinder, findsOneWidget);
      expect(loginFinder, findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      // CTA sits above the login link.
      expect(
        tester.getTopLeft(getStartedFinder).dy,
        lessThan(tester.getTopLeft(loginFinder).dy),
      );

      // GET STARTED routes to user-type selection.
      await tester.tap(getStartedFinder);
      await tester.pumpAndSettle();
      expect(find.text('user type selection'), findsOneWidget);

      // LOGIN routes to the login screen.
      await _pumpWelcome(tester);
      await tester.tap(find.text('LOGIN'));
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

    // No RenderFlex overflow (previously the CTA row overflowed by 27px).
    expect(tester.takeException(), isNull);
    expect(find.byType(KolabingLogo), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
