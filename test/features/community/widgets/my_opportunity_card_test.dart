import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
