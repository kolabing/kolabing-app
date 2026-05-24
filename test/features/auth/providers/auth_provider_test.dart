import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';
import 'package:kolabing_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:kolabing_app/features/dashboard/services/dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'session purge from auth service forces authProvider to unauthenticated',
    () async {
      const user = UserModel(
        id: 'community-1',
        email: 'community@example.com',
        userType: UserType.community,
        communityProfile: CommunityProfile(
          id: 'profile-1',
          name: 'Barcelona Creators Club',
        ),
      );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
        'auth_user': jsonEncode(user.toJson()),
      });

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            return http.Response(
              jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
              401,
            );
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );

      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWith((ref) => authService)],
      );
      addTearDown(container.dispose);

      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: 'token-123',
      );

      await expectLater(
        authService.refreshSession(),
        throwsA(isA<AuthException>()),
      );
      await Future<void>.delayed(Duration.zero);

      final authState = container.read(authProvider);
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.user, isNull);
      expect(authState.token, isNull);
    },
  );

  test(
    'signInWithEmail succeeds while dashboardProvider is mounted',
    () async {
      final authService = _SuccessfulLoginAuthService();
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => authService),
          dashboardServiceProvider.overrideWith(
            (ref) => _FakeDashboardService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(dashboardProvider);
      await Future<void>.delayed(Duration.zero);

      final result = await container.read(authProvider.notifier).signInWithEmail(
        email: 'business@example.com',
        password: 'Password123',
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);

      final authState = container.read(authProvider);
      expect(authState.status, AuthStatus.authenticated);
      expect(authState.user?.id, 'business-1');
      expect(authState.token, 'token-123');
    },
  );
}

class _SuccessfulLoginAuthService extends AuthService {
  @override
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthResponse(
      success: true,
      message: 'Login successful',
      token: 'token-123',
      refreshToken: 'refresh-123',
      tokenType: 'Bearer',
      isNewUser: false,
      user: UserModel(
        id: 'business-1',
        email: 'business@example.com',
        userType: UserType.business,
        businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
      ),
    );
  }
}

class _FakeDashboardService extends DashboardService {
  @override
  Future<DashboardResponse> getDashboard() async {
    return const DashboardResponse(
      businessDashboard: BusinessDashboard(
        opportunities: OpportunityStats(total: 1),
      ),
    );
  }
}
