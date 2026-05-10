import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/application/providers/application_provider.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/kolab/services/kolab_service.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/features/rewards/services/rewards_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth-backed service providers share the same AuthService instance', () {
    final sharedAuthService = AuthService(
      secureStorage: const FlutterSecureStorage(),
    );

    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWith((ref) => sharedAuthService)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(rewardsServiceProvider).authService,
      sharedAuthService,
    );
    expect(
      container.read(notificationServiceProvider).authService,
      sharedAuthService,
    );
    expect(
      container.read(applicationServiceProvider).authService,
      sharedAuthService,
    );
    expect(container.read(kolabServiceProvider).authService, sharedAuthService);
  });
}
