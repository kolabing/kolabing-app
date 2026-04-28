import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/screens/my_kollabs_screen.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/my_kolabs_provider.dart';

void main() {
  testWidgets(
    'tapping Edit opens the unified kolab flow with the existing draft',
    (tester) async {
      final kolab = Kolab(
        id: '42',
        intentType: IntentType.venuePromotion,
        status: 'draft',
        title: 'Spring Launch',
        description: 'Need a community partner for our launch event.',
        preferredCity: 'Madrid',
        venueName: 'Launch Hub',
        venueAddress: 'Madrid',
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MyKollabsScreen(),
          ),
          GoRoute(
            path: KolabingRoutes.kolabNew,
            builder: (context, state) =>
                const Scaffold(body: Text('new-collab-screen')),
          ),
          GoRoute(
            path: KolabingRoutes.kolabFlow,
            builder: (context, state) {
              final extra = state.extra as Kolab?;
              return Scaffold(body: Text('edit-kolab-flow:${extra?.id}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myKolabsProvider.overrideWith(
              () => _FakeMyKolabsNotifier(
                MyKolabsState(kolabs: [kolab], total: 1),
              ),
            ),
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(
                const ProfileState(isLoading: false, isInitialized: true),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('EDIT'), findsOneWidget);

      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      expect(find.text('edit-kolab-flow:42'), findsOneWidget);
      expect(find.text('new-collab-screen'), findsNothing);
    },
  );
}

class _FakeMyKolabsNotifier extends MyKolabsNotifier {
  _FakeMyKolabsNotifier(this._initialState);

  final MyKolabsState _initialState;

  @override
  MyKolabsState build() => _initialState;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;
}
