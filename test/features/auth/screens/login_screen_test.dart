import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/screens/login_screen.dart';

Future<void> _pumpLogin(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScaleFactor = 1.0,
  FakeViewPadding viewPadding = FakeViewPadding.zero,
  double keyboardHeight = 0,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewPadding();
    tester.view.resetViewInsets();
  });

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewPadding = viewPadding;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: const LoginScreen(),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('login screen uses the splash-style hero layout without scroll', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester, size: const Size(320, 640), textScaleFactor: 1.0);

    expect(tester.takeException(), isNull);
    // The form scrolls rather than risking clipping on very short screens —
    // no longer the strict "must never scroll" layout this test originally
    // asserted.
    expect(find.byType(CustomScrollView), findsOneWidget);
    // Current minimal hero copy (localized) + social buttons.
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Pick up where you left off.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    // The form scrolls on this compact height, so the social buttons are
    // reachable rather than required to fit above the fold unscrolled.
  });

  testWidgets('login screen stays stable on iPhone safe-area constraints', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(
      tester,
      size: const Size(393, 852),
      textScaleFactor: 1.0,
      viewPadding: const FakeViewPadding(top: 59, bottom: 34),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets(
    'login screen exits loading state when auth throws unexpectedly',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
      });

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(_ThrowingAuthNotifier.new)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'community@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.text('Sign in'));
      await tester.pump(); // exit loading state
      await tester.pump(const Duration(milliseconds: 400)); // error snackbar in

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
      // Unexpected failures surface commonErrorGeneric in a SnackBar.
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // Regression for Sentry FLUTTER-4 (GoError: There is nothing to pop): the
  // login back button must not crash when login is the navigation root; it
  // should route to the welcome screen instead.
  testWidgets(
    'back button on root login routes to welcome instead of throwing',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      final router = GoRouter(
        initialLocation: '/auth/login',
        routes: [
          GoRoute(
            path: '/auth/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/auth/welcome',
            builder: (context, state) =>
                const Scaffold(body: Text('WELCOME ROOT')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Login is the root route, so there is nothing to pop.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('WELCOME ROOT'), findsOneWidget);
    },
  );

  testWidgets('login shows the K logomark, not the old cloud lockup', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester);

    final mark = tester.widget<Image>(find.byKey(const Key('login-logo-mark')));
    expect(
      (mark.image as AssetImage).assetName,
      'assets/brand/kolabing-k-mark.png',
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('logo_cloud'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'the K sits in its own yellow on the black hero, like the splash',
    (WidgetTester tester) async {
      await _pumpLogin(tester);

      final mark = tester.widget<Image>(
        find.byKey(const Key('login-logo-mark')),
      );
      // Untinted: the asset's own yellow, not recoloured to ink.
      expect(mark.color, isNull);
      expect(find.text('KOLABING'), findsOneWidget);
    },
  );

  testWidgets('the footer Sign Up link opens user-type selection', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    final router = GoRouter(
      initialLocation: '/auth/login',
      routes: [
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/user-type',
          builder: (context, state) => const Scaffold(body: Text('USER TYPE')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text("Don't have an account?"), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('USER TYPE'), findsOneWidget);
  });

  testWidgets(
    'with the keyboard up, the focused password field scrolls into view (FX-60)',
    (WidgetTester tester) async {
      // iPhone SE height with a 260pt keyboard: only ~400pt of page is left.
      await _pumpLogin(
        tester,
        size: const Size(375, 667),
        viewPadding: const FakeViewPadding(top: 20),
        keyboardHeight: 260,
      );
      expect(tester.takeException(), isNull);

      final password = find.byType(TextFormField).at(1);
      await tester.showKeyboard(password);
      await tester.pumpAndSettle();

      final visibleBottom = 667.0 - 260.0;
      final rect = tester.getRect(password);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(visibleBottom));
    },
  );

  testWidgets('scrolling the form moves the hero with it — nothing is clipped '
      'at a fixed edge mid-sheet (FX-60)', (WidgetTester tester) async {
    await _pumpLogin(tester, size: const Size(375, 667));

    final mark = find.byKey(const Key('login-logo-mark'));
    final emailTopBefore = tester
        .getTopLeft(find.byType(TextFormField).first)
        .dy;
    final markTopBefore = tester.getTopLeft(mark).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();

    final emailTopAfter = tester
        .getTopLeft(find.byType(TextFormField).first)
        .dy;
    final markTopAfter = tester.getTopLeft(mark).dy;
    // Hero and form travel by the same amount: one scroll surface.
    expect(markTopBefore - markTopAfter, greaterThan(0));
    expect(
      emailTopBefore - emailTopAfter,
      moreOrLessEquals(markTopBefore - markTopAfter, epsilon: 0.5),
    );
  });
}

class _ThrowingAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw AssertionError('unexpected auth failure');
  }
}
