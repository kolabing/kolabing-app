import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/community/screens/my_opportunities_screen.dart';
import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';
import 'package:kolabing_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';

void main() {
  testWidgets(
    'closing the create flow refreshes both dashboard and my opportunities providers',
    (WidgetTester tester) async {
      var dashboardBuilds = 0;
      var myOpportunitiesBuilds = 0;

      // B1 (2026-05-22): the create entry now routes to the unified
      // /kolab/flow via /kolab/new (KolabingRoutes.kolabNew, literal '/kolab/new'
      // here to avoid importing routes.dart, whose transitive collaboration
      // imports are owned by another agent), replacing the legacy
      // CreateOpportunityScreen route. On return, MyOpportunitiesScreen
      // invalidates the dashboard and my-opportunities providers so a freshly
      // created kolab is visible immediately. This test asserts that refresh
      // through the new routing.
      const kolabNewPath = '/kolab/new';
      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            // MyOpportunitiesScreen owns the create entry + the
            // dashboard/my-opportunities refresh-on-return. The dashboard
            // provider is watched here (as CommunityMainScreen does in app)
            // so its invalidation is observable as a rebuild.
            builder: (BuildContext context, GoRouterState state) => Consumer(
              builder: (context, ref, _) {
                ref.watch(dashboardProvider);
                return const MyOpportunitiesScreen();
              },
            ),
          ),
          GoRoute(
            path: kolabNewPath,
            builder: (BuildContext context, GoRouterState state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close create flow'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(
              () =>
                  _CountingDashboardNotifier(onBuild: () => dashboardBuilds++),
            ),
            myOpportunitiesProvider.overrideWith(
              () => _CountingMyOpportunitiesNotifier(
                onBuild: () => myOpportunitiesBuilds++,
              ),
            ),
            myOpportunitiesStatusProvider.overrideWith(
              MyOpportunitiesStatusNotifier.new,
            ),
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(
                const ProfileState(isLoading: false, isInitialized: true),
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(dashboardBuilds, 1);
      expect(myOpportunitiesBuilds, 1);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Close create flow'), findsOneWidget);

      await tester.tap(find.text('Close create flow'));
      await tester.pump();
      // _onCreateNew waits ~300ms after the push returns before invalidating.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(dashboardBuilds, 2);
      expect(myOpportunitiesBuilds, 2);
    },
  );
}

class _CountingDashboardNotifier extends DashboardNotifier {
  _CountingDashboardNotifier({required this.onBuild});

  final VoidCallback onBuild;

  @override
  DashboardState build() {
    onBuild();
    return const DashboardState(
      communityData: CommunityDashboard(),
      isLoading: false,
      isInitialized: true,
    );
  }
}

class _CountingMyOpportunitiesNotifier extends MyOpportunitiesNotifier {
  _CountingMyOpportunitiesNotifier({required this.onBuild});

  final VoidCallback onBuild;

  @override
  OpportunityListState build() {
    onBuild();
    return const OpportunityListState();
  }
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;
}
