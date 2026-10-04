import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/screens/forgot_password_screen.dart';
import 'package:kolabing_app/features/auth/widgets/auth_brand_hero.dart';

Future<void> _pumpForgotPassword(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScaleFactor = 1.0,
  FakeViewPadding viewPadding = FakeViewPadding.zero,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewPadding();
  });

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewPadding = viewPadding;

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: const ForgotPasswordScreen(),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('forgot password screen uses the K brand hero, like login', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPassword(tester);

    expect(tester.takeException(), isNull);
    // The form scrolls rather than risking clipping on shorter screens —
    // the opposite of a stale "must never scroll" assumption.
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // The K brand hero, as on login — not the old cloud lockup.
    expect(find.byType(AuthBrandHero), findsOneWidget);
    expect(find.byKey(const Key('auth-logo-mark')), findsOneWidget);

    expect(find.text('Reset access.'), findsOneWidget);
    expect(
      find.text("Enter your account email and we'll send a secure reset link."),
      findsOneWidget,
    );
    expect(find.text('Send reset link'), findsOneWidget);
  });

  testWidgets('forgot password screen stays stable on compact safe areas', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPassword(
      tester,
      size: const Size(320, 640),
      textScaleFactor: 1.0,
      viewPadding: const FakeViewPadding(top: 47, bottom: 20),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Reset access.'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Send reset link')).dy,
      lessThanOrEqualTo(640),
    );
  });

  testWidgets('the form matches login: labeled email field, ink CTA', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPassword(tester);

    expect(find.text('Email'), findsOneWidget); // label above the field
    expect(find.text('your@email.com'), findsOneWidget); // hint
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Remembered it?'), findsOneWidget);
    // The old literal success CTA is gone from the idle form.
    expect(find.text('BACK TO SIGN IN'), findsNothing);
  });

  testWidgets('a tap anywhere on "Remembered it? Log in" opens login', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    final router = GoRouter(
      initialLocation: '/auth/forgot-password',
      routes: [
        GoRoute(
          path: '/auth/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    final prompt = find.text('Remembered it?');
    await tester.ensureVisible(prompt);
    await tester.tap(prompt);
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
