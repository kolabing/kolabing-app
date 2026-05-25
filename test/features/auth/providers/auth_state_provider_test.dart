import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/providers/auth_state_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initialize hydrates authProvider when a persisted session exists',
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

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith(
            (ref) => _FakeAuthService(
              token: 'token-123',
              storedUser: user,
              restoredUser: user,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final route = await container.read(splashStateProvider.notifier).initialize();

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.user?.id, user.id);
      expect(
        route,
        anyOf(
          KolabingRoutes.communityDashboard,
          '${KolabingRoutes.permissions}?destination='
              '${Uri.encodeComponent(KolabingRoutes.communityDashboard)}',
        ),
      );
    },
  );
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    required this.token,
    this.storedUser,
    this.restoredUser,
  });

  final String? token;
  final UserModel? storedUser;
  final UserModel? restoredUser;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> isAuthenticated() async => token != null;

  @override
  Future<UserModel?> getStoredUser() async => storedUser;

  @override
  Future<UserModel?> restoreSessionUser() async => restoredUser;
}
