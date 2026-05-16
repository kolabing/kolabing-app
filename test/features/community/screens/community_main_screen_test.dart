import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/application/providers/application_provider.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/community/screens/community_main_screen.dart';
import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';
import 'package:kolabing_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity_filter.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';

void main() {
  testWidgets(
    'closing the create flow refreshes both dashboard and my opportunities providers',
    (WidgetTester tester) async {
      var dashboardBuilds = 0;
      var myOpportunitiesBuilds = 0;

      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const CommunityMainScreen(),
          ),
          GoRoute(
            path: KolabingRoutes.communityOpportunitiesNew,
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
            authProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthState(status: AuthStatus.authenticated),
              ),
            ),
            dashboardProvider.overrideWith(
              () =>
                  _CountingDashboardNotifier(onBuild: () => dashboardBuilds++),
            ),
            notificationProvider.overrideWith(
              () => _FakeNotificationNotifier(const NotificationState()),
            ),
            discoveryFiltersProvider.overrideWith(
              _FakeDiscoveryFiltersNotifier.new,
            ),
            discoveryListProvider.overrideWith(_FakeDiscoveryListNotifier.new),
            opportunityFiltersProvider.overrideWith(
              () => _FakeOpportunityFiltersNotifier(OpportunityFilters.empty),
            ),
            opportunityListProvider.overrideWith(
              () => _FakeOpportunityListNotifier(const OpportunityListState()),
            ),
            myOpportunitiesProvider.overrideWith(
              () => _CountingMyOpportunitiesNotifier(
                onBuild: () => myOpportunitiesBuilds++,
              ),
            ),
            myApplicationsProvider.overrideWith(
              () => _FakeMyApplicationsNotifier(const ApplicationsState()),
            ),
            receivedApplicationsProvider.overrideWith(
              () =>
                  _FakeReceivedApplicationsNotifier(const ApplicationsState()),
            ),
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(
                const ProfileState(isLoading: false, isInitialized: true),
              ),
            ),
            walletProvider.overrideWith(
              () => _FakeWalletNotifier(const WalletState()),
            ),
            totalUnreadCountProvider.overrideWith((Ref ref) => 0),
            unreadNotificationCountProvider.overrideWith((Ref ref) => 0),
          ],
          child: MaterialApp.router(routerConfig: router),
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(dashboardBuilds, 2);
      expect(myOpportunitiesBuilds, 2);
    },
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
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

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(this._initialState);

  final NotificationState _initialState;

  @override
  NotificationState build() => _initialState;
}

class _FakeOpportunityFiltersNotifier extends OpportunityFiltersNotifier {
  _FakeOpportunityFiltersNotifier(this._initialState);

  final OpportunityFilters _initialState;

  @override
  OpportunityFilters build() => _initialState;
}

class _FakeOpportunityListNotifier extends OpportunityListNotifier {
  _FakeOpportunityListNotifier(this._initialState);

  final OpportunityListState _initialState;

  @override
  OpportunityListState build() => _initialState;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

class _FakeDiscoveryFiltersNotifier extends DiscoveryFiltersNotifier {
  @override
  DiscoveryFilters build() => const DiscoveryFilters();
}

class _FakeDiscoveryListNotifier extends DiscoveryListNotifier {
  @override
  DiscoveryListState build() => const DiscoveryListState();

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
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

class _FakeMyApplicationsNotifier extends MyApplicationsNotifier {
  _FakeMyApplicationsNotifier(this._initialState);

  final ApplicationsState _initialState;

  @override
  ApplicationsState build() => _initialState;
}

class _FakeReceivedApplicationsNotifier extends ReceivedApplicationsNotifier {
  _FakeReceivedApplicationsNotifier(this._initialState);

  final ApplicationsState _initialState;

  @override
  ApplicationsState build() => _initialState;
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;

  @override
  ProfileState build() => _initialState;
}

class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(this._initialState);

  final WalletState _initialState;

  @override
  WalletState build() => _initialState;
}
