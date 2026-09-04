import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/screens/forgot_password_screen.dart';
import 'package:kolabing_app/features/auth/widgets/kolabing_logo.dart';

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
  testWidgets('forgot password screen reuses the login hero shell', (
    WidgetTester tester,
  ) async {
    await _pumpForgotPassword(tester);

    expect(tester.takeException(), isNull);
    // The form scrolls rather than risking clipping on shorter screens —
    // the opposite of a stale "must never scroll" assumption.
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final logo = tester.widget<KolabingLogo>(find.byType(KolabingLogo));
    expect(logo.tone, KolabingLogoTone.dark);

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
}
