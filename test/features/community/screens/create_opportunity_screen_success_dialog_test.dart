import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/features/community/widgets/opportunity_publish_success_dialog.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

void main() {
  Widget buildSubject({
    required bool isDraft,
    Opportunity? opportunity,
    VoidCallback? onShare,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: OpportunityPublishSuccessDialog(
        isDraft: isDraft,
        opportunity: opportunity,
        onShare: onShare ?? () {},
        onViewOpportunities: () {},
      ),
    ),
  );

  testWidgets(
    'published opportunity with id shows share and opportunity copy',
    (WidgetTester tester) async {
      final opportunity = Opportunity.empty().copyWith(
        id: 'opp-42',
        title: 'Sunset Rooftop Collab',
      );

      await tester.pumpWidget(
        buildSubject(isDraft: false, opportunity: opportunity),
      );

      expect(find.text('SHARE'), findsOneWidget);
      expect(find.text('Opportunity Published!'), findsOneWidget);
      expect(find.text('VIEW MY OPPORTUNITIES'), findsOneWidget);
    },
  );

  testWidgets('draft dialog hides share CTA', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject(isDraft: true));

    expect(find.text('Draft Saved!'), findsOneWidget);
    expect(find.text('SHARE'), findsNothing);
    expect(find.text('VIEW MY OPPORTUNITIES'), findsOneWidget);
  });

  testWidgets('published opportunity without usable id hides share CTA', (
    WidgetTester tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(title: 'Untitled');

    await tester.pumpWidget(
      buildSubject(isDraft: false, opportunity: opportunity, onShare: null),
    );

    expect(find.text('Opportunity Published!'), findsOneWidget);
    expect(find.text('SHARE'), findsNothing);
    expect(find.text('VIEW MY OPPORTUNITIES'), findsOneWidget);
  });
}
