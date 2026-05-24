import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/application/providers/application_provider.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';
import 'package:kolabing_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity_filter.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';
import 'package:kolabing_app/main.dart';

void main() {
  testWidgets(
    'authenticated shell redirects to login when auth becomes unauthenticated',
    (tester) async {
      final authNotifier = _MutableAuthNotifier(
        const AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(
            id: 'community-1',
            email: 'community@example.com',
            userType: UserType.community,
            communityProfile: CommunityProfile(
              id: 'profile-1',
              name: 'Barcelona Creators',
            ),
          ),
          token: 'token-123',
        ),
      );

      kolabingRouter.go(KolabingRoutes.communityDashboard);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => authNotifier),
            dashboardProvider.overrideWith(
              () => _FakeDashboardNotifier(
                const DashboardState(
                  communityData: CommunityDashboard(),
                  isLoading: false,
                  isInitialized: true,
                ),
              ),
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
              () => _FakeMyOpportunitiesNotifier(const OpportunityListState()),
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
            totalUnreadCountProvider.overrideWith((ref) => 0),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const KolabingApp(),
        ),
      );

      await tester.pump();

      expect(
        kolabingRouter.routeInformationProvider.value.uri.path,
        KolabingRoutes.communityDashboard,
      );

      authNotifier.expireSession();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        kolabingRouter.routeInformationProvider.value.uri.path,
        KolabingRoutes.login,
      );
    },
  );
}

class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  void expireSession() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _FakeDashboardNotifier extends DashboardNotifier {
  _FakeDashboardNotifier(this._initialState);

  final DashboardState _initialState;

  @override
  DashboardState build() => _initialState;
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

class _FakeMyOpportunitiesNotifier extends MyOpportunitiesNotifier {
  _FakeMyOpportunitiesNotifier(this._initialState);

  final OpportunityListState _initialState;

  @override
  OpportunityListState build() => _initialState;
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
