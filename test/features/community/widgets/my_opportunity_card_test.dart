import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/features/community/widgets/my_opportunity_card.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

void main() {
  testWidgets('published opportunities show the Share action', (tester) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MyOpportunityCard(
            opportunity: opportunity,
            onEdit: () {},
            onShare: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('action labels stay on a single line on compact widths', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-43',
      title: 'Sunday Run',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 800)),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MyOpportunityCard(
                opportunity: opportunity,
                onView: () {},
                onEdit: () {},
                onShare: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );

    for (final label in ['View', 'Edit', 'Share', 'Close']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.fade);
    }
  });
}
