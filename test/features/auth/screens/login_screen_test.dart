import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/screens/login_screen.dart';
import 'package:kolabing_app/widgets/brand/kolabing_k_mark.dart';
import 'package:kolabing_app/features/auth/widgets/google_logo.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> _pumpLogin(
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
  testWidgets('login screen survives a very short screen without clipping', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester, size: const Size(320, 640), textScaleFactor: 1.0);

    expect(tester.takeException(), isNull);
    // The page scrolls rather than clipping on very short screens.
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // Copy updated for the Mobile Login v2 port (#193): the hero is now two
    // Anton lines, and the social buttons say what they continue with.
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('BACK.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
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
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
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
      // Social-first puts the CTA further down than the old layout did, so on
      // a 390x844 viewport it can start below the fold.
      await tester.ensureVisible(find.text('Sign in'));
      await tester.pump();
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
      // The v2 nav uses Lucide's chevron rather than the Material arrow.
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('WELCOME ROOT'), findsOneWidget);
    },
  );
  Future<void> pumpLoginV2(WidgetTester tester) async {
    // Sibling tests in this file drive `tester.view` directly, so set both and
    // reset both — otherwise a leaked physicalSize changes the geometry these
    // assertions measure.
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
    while (tester.takeException() != null) {}
  }

  testWidgets('renders the design in order, social before email', (
    tester,
  ) async {
    await pumpLoginV2(tester);

    expect(find.byType(AnimatedKolabingKMark), findsOneWidget);
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('BACK.'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.text('or with email'), findsOneWidget);
    expect(find.text('forgot password?'), findsOneWidget);
    expect(
      find.textContaining('new to kolabing', findRichText: true),
      findsOneWidget,
    );

    // The point of variant 1a: the social buttons come before the email form.
    final apple = tester.getRect(find.text('Continue with Apple'));
    final email = tester.getRect(find.text('Email'));
    expect(apple.top, lessThan(email.top));
  });

  testWidgets('the footer sits at the bottom of the page, not after the CTA', (
    tester,
  ) async {
    await pumpLoginV2(tester);

    final footer = tester.getRect(
      find.textContaining('new to kolabing', findRichText: true),
    );
    final cta = tester.getRect(find.text('Sign in'));

    // The design pins it with `margin: auto 0 0`; a naive Column would leave it
    // hugging the button instead.
    //
    // Only the gap is asserted, not an absolute y. The test binding substitutes
    // its own faces for Anton/Inter/Caveat, and those metrics change the page's
    // height — so pinning `footer.bottom` to the viewport would be pinning the
    // fallback font, not the layout.
    expect(footer.top - cta.bottom, greaterThan(100));
  });

  testWidgets('Sign in stays disabled until both fields have something', (
    tester,
  ) async {
    await pumpLoginV2(tester);

    // AnimatedOpacity renders a RenderAnimatedOpacity, not a plain Opacity
    // widget, so read the declared value off the widget itself.
    double ctaOpacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('Sign in'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    // Nothing typed: the design greys it to 50%.
    expect(ctaOpacity(), closeTo(0.5, 0.01));

    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.pumpAndSettle();
    expect(
      ctaOpacity(),
      closeTo(0.5, 0.01),
      reason: 'an email alone is not enough',
    );

    await tester.enterText(find.byType(TextFormField).last, 'hunter2');
    await tester.pumpAndSettle();
    expect(ctaOpacity(), closeTo(1.0, 0.01));
  });

  testWidgets('the eye button toggles password obscurity', (tester) async {
    await pumpLoginV2(tester);

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byTooltip('Show or hide password'));
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
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
