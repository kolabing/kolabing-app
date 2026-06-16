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

    // Share and Close are now icon buttons (GlassIconButton) carrying their
    // labels as tooltips rather than visible Text.
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
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

    // Only the primary action (View) carries a visible label now; it is a
    // GlassButton that uppercases the label and keeps it on a single line.
    final viewLabel = tester.widget<Text>(find.text('VIEW'));
    expect(viewLabel.maxLines, 1);
    expect(viewLabel.overflow, TextOverflow.ellipsis);

    // Edit, Share and Close are icon-only buttons (tooltips), never wrapping.
    for (final tooltip in ['Edit', 'Share', 'Close']) {
      expect(find.byTooltip(tooltip), findsOneWidget);
      expect(find.text(tooltip), findsNothing);
    }
  });
}
