import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/screens/welcome_screen.dart';
import 'package:kolabing_app/features/auth/widgets/auth_brand_hero.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  // Welcome is the K brand hero (yellow K + KOLABING on black, the same as the
  // splash and login) over a cream sheet: headline, MATCH · KOLAB · GROW,
  // an ink "Start kolabing" CTA and an "Already in? Log in" row.
  testWidgets('welcome shows the K brand hero, not the cloud lockup', (
    WidgetTester tester,
  ) async {
    await _pumpWelcome(tester);

    expect(find.byType(AuthBrandHero), findsOneWidget);
    final mark = tester.widget<Image>(find.byKey(const Key('auth-logo-mark')));
    expect(
      (mark.image as AssetImage).assetName,
      'assets/brand/kolabing-k-mark.png',
    );
    expect(find.text('KOLABING'), findsOneWidget);

    expect(find.text('Where businesses'), findsOneWidget);
    expect(find.text('and communities'), findsOneWidget);
    expect(find.text('together'), findsOneWidget);
    expect(find.text('KOLAB'), findsOneWidget);
  });

  testWidgets('Start kolabing opens user-type selection', (
    WidgetTester tester,
  ) async {
    await _pumpWelcome(tester);

    final start = find.text('Start kolabing');
    final login = find.text('Log in');
    expect(start, findsOneWidget);
    expect(login, findsOneWidget);
    // The CTA sits above the login row.
    expect(tester.getTopLeft(start).dy, lessThan(tester.getTopLeft(login).dy));

    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('user type selection'), findsOneWidget);
  });

  testWidgets('a tap anywhere on "Already in? Log in" opens login', (
    WidgetTester tester,
  ) async {
    await _pumpWelcome(tester);

    await tester.tap(find.text('Already in?'));
    await tester.pumpAndSettle();
    expect(find.text('login screen'), findsOneWidget);
  });

  testWidgets('welcome remains stable on compact scaled layouts', (
    WidgetTester tester,
  ) async {
    await _pumpWelcome(
      tester,
      size: const Size(320, 640),
      textScaleFactor: 1.25,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthBrandHero), findsOneWidget);
    await tester.ensureVisible(find.text('Log in'));
    expect(find.text('Start kolabing'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
