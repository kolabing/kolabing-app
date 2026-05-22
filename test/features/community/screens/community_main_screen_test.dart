import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/collaboration/models/collaboration.dart';
import 'package:kolabing_app/features/collaboration/providers/collaborations_list_provider.dart';
import 'package:kolabing_app/features/community/screens/my_opportunities_screen.dart';

void main() {
  // The community "My Kolabs" tab was repurposed (2026-05-22) from the
  // community's own POSTS to its COLLABORATIONS (Active / Finished). Creating a
  // post (and its dashboard refresh-on-return) moved to the Applications tab,
  // so the legacy FAB-opens-create-flow test no longer applies here. This test
  // now asserts the repurposed screen renders the collaborations buckets.
  testWidgets('My Kolabs renders the Active collaborations bucket', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collaborationsListProvider(CollaborationsFilter.active).overrideWith(
            (ref) async => [
              const CollaborationListItem(
                id: 'collab-1',
                status: CollaborationStatus.scheduled,
                partnerName: 'Brew & Co',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: MyOpportunitiesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MY KOLABS'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Brew & Co'), findsOneWidget);
  });
}
