import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/screens/login_screen.dart';
import 'package:kolabing_app/features/auth/widgets/kolabing_logo.dart';

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
  testWidgets('login screen uses the splash-style hero layout without scroll', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester, size: const Size(320, 640), textScaleFactor: 1.0);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    final logo = tester.widget<KolabingLogo>(find.byType(KolabingLogo));
    final logoRenderSize = tester.getSize(
      find.bySemanticsLabel('Kolabing logo'),
    );
    expect(logo.variant, KolabingLogoVariant.yellowTransparent);
    expect(logoRenderSize.width, greaterThanOrEqualTo(80));
    expect(find.text('REAL MATCHES.'), findsOneWidget);
    expect(find.text('REAL PARTNERSHIPS.'), findsOneWidget);
    expect(find.text('WELCOME BACK.'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('GOOGLE'), findsOneWidget);
    expect(find.text('APPLE'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('APPLE')).dy, lessThanOrEqualTo(640));
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
    expect(find.text('REAL MATCHES.'), findsOneWidget);
    expect(find.text('APPLE'), findsOneWidget);
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
      await tester.tap(find.text('SIGN IN'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
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
