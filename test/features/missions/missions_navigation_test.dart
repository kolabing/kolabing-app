import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/missions/models/mission.dart';
import 'package:kolabing_app/features/missions/providers/missions_provider.dart';
import 'package:kolabing_app/features/missions/screens/missions_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

void main() {
  // Guards the Profile → Missions navigation chain (kolabing-app#48): a
  // `context.push(KolabingRoutes.missions)` must actually swap in MissionsScreen.
  // The missions list is overridden to empty so the screen settles
  // deterministically (no real network), isolating the route/push wiring.
  testWidgets('tapping the Missions route pushes MissionsScreen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(KolabingRoutes.missions),
              child: const Text('Go to missions'),
            ),
          ),
        ),
        GoRoute(
          path: KolabingRoutes.missions,
          name: 'missions',
          builder: (context, state) => const MissionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myMissionsProvider.overrideWith((ref) async => const <Mission>[]),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    expect(find.text('Go to missions'), findsOneWidget);

    await tester.tap(find.text('Go to missions'));
    await tester.pumpAndSettle();

    expect(find.byType(MissionsScreen), findsOneWidget);
  });
}
