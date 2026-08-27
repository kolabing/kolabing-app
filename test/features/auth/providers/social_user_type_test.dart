import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

class _RecordingAuthService extends AuthService {
  String? googleUserType;
  String? appleUserType;

  AuthResponse _attendee() => const AuthResponse(
    success: true,
    message: 'ok',
    token: 't-1',
    tokenType: 'Bearer',
    isNewUser: true,
    user: UserModel(
      id: 'a-1',
      email: 'a@example.com',
      userType: UserType.attendee,
      name: 'Jane Doe',
    ),
  );

  @override
  Future<AuthResponse> loginWithGoogle({String? userType}) async {
    googleUserType = userType;
    return _attendee();
  }

  @override
  Future<AuthResponse> loginWithApple({String? userType}) async {
    appleUserType = userType;
    return _attendee();
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test(
    'signInWithGoogle forwards attendee hint and honors is_new_user',
    () async {
      final service = _RecordingAuthService();
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .signInWithGoogle(userTypeHint: UserType.attendee);
      await Future<void>.delayed(Duration.zero);

      expect(service.googleUserType, 'attendee');
      expect(result.success, isTrue);
      expect(result.isNewUser, isTrue);
      expect(result.user?.isAttendee, isTrue);
    },
  );

  test(
    'signInWithGoogle WITHOUT a hint keeps isNewUser false (login screens '
    'stay existing-users-only even if backend returns is_new_user:true)',
    () async {
      final service = _RecordingAuthService();
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(service.googleUserType, isNull);
      expect(result.success, isTrue);
      // Backend mock returns is_new_user:true, but with no signup hint the
      // provider must NOT route into onboarding.
      expect(result.isNewUser, isFalse);
    },
  );

  test('signInWithApple forwards attendee hint', () async {
    final service = _RecordingAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(authProvider.notifier)
        .signInWithApple(userTypeHint: UserType.attendee);
    await Future<void>.delayed(Duration.zero);

    expect(service.appleUserType, 'attendee');
    expect(result.isNewUser, isTrue);
  });
}
