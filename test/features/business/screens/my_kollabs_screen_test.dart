import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/business/screens/my_kollabs_screen.dart';
import 'package:kolabing_app/features/collaboration/models/collaboration.dart';
import 'package:kolabing_app/features/collaboration/providers/collaborations_list_provider.dart';

CollaborationListItem _item({
  required String id,
  required CollaborationStatus status,
  required String partnerName,
}) => CollaborationListItem(
  id: id,
  status: status,
  partnerName: partnerName,
  scheduledDate: DateTime(2026, 6, 15),
  opportunityTitle: 'Spring Launch',
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
        child: const MaterialApp(home: MyKollabsScreen()),
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
          builder: (context, state) => const MyKollabsScreen(),
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
                id: 'collab-7',
                status: CollaborationStatus.scheduled,
                partnerName: 'Move Club',
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Move Club'), findsOneWidget);

    await tester.tap(find.text('Move Club'));
    await tester.pumpAndSettle();

    expect(find.text('detail:collab-7'), findsOneWidget);
  });

  testWidgets('switching to Finished loads the completed bucket', (
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
                id: 'collab-9',
                status: CollaborationStatus.completed,
                partnerName: 'Book Lovers',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: MyKollabsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No active collaborations'), findsOneWidget);

    await tester.tap(find.text('Finished'));
    await tester.pumpAndSettle();

    expect(find.text('Book Lovers'), findsOneWidget);
  });
}
