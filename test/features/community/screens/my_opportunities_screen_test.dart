import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kolabing_app/features/community/screens/my_opportunities_screen.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share_launcher.dart';

void main() {
  testWidgets('share fallback shows snackbar when sharing is unavailable', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    var copiedText = '';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(
              OpportunityListState(opportunities: [opportunity], total: 1),
            ),
          ),
        ],
        child: MaterialApp(
          home: MyOpportunitiesScreen(
            opportunityShareLauncher: OpportunityShareLauncher(
              share: (_, {sharePositionOrigin}) async =>
                  ShareResult.unavailable,
              copyText: (text) async {
                copiedText = text;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(copiedText, contains('/c/opp-42'));
    expect(
      find.text('Sharing is unavailable. Link copied instead.'),
      findsOneWidget,
    );
  });

  testWidgets('share fallback shows snackbar when share sheet cannot open', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(
              OpportunityListState(opportunities: [opportunity], total: 1),
            ),
          ),
        ],
        child: MaterialApp(
          home: MyOpportunitiesScreen(
            opportunityShareLauncher: OpportunityShareLauncher(
              share: (_, {sharePositionOrigin}) async {
                throw Exception('share failed');
              },
              copyText: (text) async {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the share sheet.'), findsOneWidget);
  });
}

class _FakeMyOpportunitiesNotifier extends MyOpportunitiesNotifier {
  _FakeMyOpportunitiesNotifier(this._initialState);

  final OpportunityListState _initialState;

  @override
  OpportunityListState build() => _initialState;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}
