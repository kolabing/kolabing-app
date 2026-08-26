import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';
import 'package:kolabing_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:kolabing_app/features/dashboard/services/dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dashboard provider ignores stale load completion from a previous session',
    () async {
      final authNotifier = _MutableAuthNotifier(_communityUser('community-1'));
      final service = _ScriptedDashboardService(
        responses: <Object>[
          Completer<DashboardResponse>(),
          const DashboardResponse(
            communityDashboard: CommunityDashboard(
              applicationsSent: ApplicationsSentStats(total: 7),
            ),
          ),
        ],
      );

      final firstLoad = service.responses.first as Completer<DashboardResponse>;

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => authNotifier),
          dashboardServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      container.read(authProvider);
      container.read(dashboardProvider);
      await Future<void>.delayed(Duration.zero);

      authNotifier.signOut();
      await Future<void>.delayed(Duration.zero);

      authNotifier.signIn(_communityUser('community-2'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      firstLoad.complete(
        const DashboardResponse(
          businessDashboard: BusinessDashboard(
            opportunities: OpportunityStats(total: 99),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(dashboardProvider);
      expect(state.businessData, isNull);
      expect(state.communityData?.applicationsSent.total, 7);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    },
  );
}

UserModel _communityUser(String id) => UserModel(
  id: id,
  email: '$id@example.com',
  userType: UserType.community,
  communityProfile: CommunityProfile(id: 'profile-$id', name: 'User $id'),
);

class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(this._initialUser);

  final UserModel _initialUser;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _initialUser,
    token: 'token-${_initialUser.id}',
  );

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void signIn(UserModel user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: 'token-${user.id}',
    );
  }
}

class _ScriptedDashboardService extends DashboardService {
  _ScriptedDashboardService({required this.responses});

  final List<Object> responses;
  int _index = 0;

  @override
  Future<DashboardResponse> getDashboard({UserType? userType}) async {
    final response =
        responses[_index < responses.length ? _index++ : responses.length - 1];
    if (response is Completer<DashboardResponse>) {
      return response.future;
    }
    if (response is DashboardResponse) {
      return response;
    }
    throw StateError('Unexpected dashboard response: $response');
  }
}
