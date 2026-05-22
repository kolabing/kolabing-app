import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/collaboration/models/collaboration.dart';
import 'package:kolabing_app/features/collaboration/providers/collaborations_list_provider.dart';
import 'package:kolabing_app/features/community/screens/my_opportunities_screen.dart';

CollaborationListItem _item({
  required String id,
  required CollaborationStatus status,
  required String partnerName,
}) => CollaborationListItem(
  id: id,
  status: status,
  partnerName: partnerName,
  scheduledDate: DateTime(2026, 6, 15),
  opportunityTitle: 'Sunset Rooftop Collab',
);

void main() {
  testWidgets('My Kolabs shows Active and Finished sub-tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collaborationsListProvider(
            CollaborationsFilter.active,
          ).overrideWith((ref) async => const <CollaborationListItem>[]),
        ],
        child: const MaterialApp(home: MyOpportunitiesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MY KOLABS'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
  });

  testWidgets('tapping an active collaboration opens /collaboration/:id', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MyOpportunitiesScreen(),
        ),
        GoRoute(
          path: '/collaboration/:id',
          builder: (context, state) =>
              Scaffold(body: Text('detail:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collaborationsListProvider(CollaborationsFilter.active).overrideWith(
            (ref) async => [
              _item(
                id: 'collab-42',
                status: CollaborationStatus.inProgress,
                partnerName: 'Brew & Co',
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Brew & Co'), findsOneWidget);

    await tester.tap(find.text('Brew & Co'));
    await tester.pumpAndSettle();

    expect(find.text('detail:collab-42'), findsOneWidget);
  });

  testWidgets('Finished tab shows only completed collaborations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collaborationsListProvider(
            CollaborationsFilter.active,
          ).overrideWith((ref) async => const <CollaborationListItem>[]),
          collaborationsListProvider(
            CollaborationsFilter.finished,
          ).overrideWith(
            (ref) async => [
              _item(
                id: 'collab-99',
                status: CollaborationStatus.completed,
                partnerName: 'Roastery 21',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: MyOpportunitiesScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No active collaborations'), findsOneWidget);

    await tester.tap(find.text('Finished'));
    await tester.pumpAndSettle();

    expect(find.text('Roastery 21'), findsOneWidget);
  });
}
