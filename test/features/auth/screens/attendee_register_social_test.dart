import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/screens/attendee_register_screen.dart';
import 'package:kolabing_app/features/auth/widgets/apple_sign_in_button.dart';
import 'package:kolabing_app/features/auth/widgets/google_sign_in_button.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AttendeeRegisterScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows Google button; Apple hidden while flag off', (
    tester,
  ) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    // attendeeAppleSignupEnabled is false by default → no Apple button.
    expect(find.byType(AppleSignInButton), findsNothing);
  });
}
