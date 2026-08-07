import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/subscription/widgets/subscription_legal_footer.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

void main() {
  // App Store Guideline 3.1.2: the purchase surface must disclose auto-renewal
  // and expose functional Terms of Use (EULA) + Privacy Policy links.
  testWidgets('renders the auto-renew notice and both legal links', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SubscriptionLegalFooter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(
      find.textContaining('renew automatically'),
      findsOneWidget,
      reason: 'auto-renewal terms must be disclosed at the point of purchase',
    );
  });

  testWidgets('legal links are tappable (wrapped in a gesture detector)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SubscriptionLegalFooter()),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in const ['Terms of Use (EULA)', 'Privacy Policy']) {
      final gesture = find.ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      );
      expect(gesture, findsOneWidget, reason: '"$label" must be tappable');
    }
  });
}
