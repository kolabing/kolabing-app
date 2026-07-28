import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/profile/models/public_profile.dart';
import 'package:kolabing_app/features/profile/widgets/reputation_summary_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/cards/kolabing_cards.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required Reputation? reputation,
    int? completedKolabsCount,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReputationSummaryCard(
          reputation: reputation,
          completedKolabsCount: completedKolabsCount,
        ),
      ),
    ),
  );

  const withReviews = Reputation(
    averageRating: 4.8,
    reviewCount: 5,
    uniquePartnerCount: 3,
  );

  testWidgets('renders rating, reviews, partners and completed Kolabs', (
    tester,
  ) async {
    await pumpCard(tester, reputation: withReviews, completedKolabsCount: 7);
    await tester.pumpAndSettle();

    expect(find.text('4.8'), findsOneWidget);
    expect(find.textContaining('5 reviews'), findsOneWidget);
    expect(find.textContaining('3 partners'), findsOneWidget);
    expect(find.textContaining('7 completed'), findsOneWidget);
  });

  testWidgets('hides the completed-Kolabs stat when the count is zero', (
    tester,
  ) async {
    await pumpCard(tester, reputation: withReviews, completedKolabsCount: 0);
    await tester.pumpAndSettle();

    expect(find.textContaining('completed'), findsNothing);
  });

  testWidgets('hides the partners stat when there are none', (tester) async {
    await pumpCard(
      tester,
      reputation: const Reputation(
        averageRating: 5,
        reviewCount: 2,
        uniquePartnerCount: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('partner'), findsNothing);
  });

  testWidgets('shows the empty state when there are no reviews', (
    tester,
  ) async {
    await pumpCard(
      tester,
      reputation: const Reputation(reviewCount: 0, uniquePartnerCount: 0),
      completedKolabsCount: 4,
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateCard), findsOneWidget);
  });

  testWidgets('shows the empty state when reputation is null', (tester) async {
    await pumpCard(tester, reputation: null);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateCard), findsOneWidget);
  });
}
