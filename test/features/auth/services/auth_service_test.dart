import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('getCurrentUser does not clear stored auth on 401', () async {
    const user = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
      onboardingCompleted: true,
    );

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
      'auth_user': jsonEncode(user.toJson()),
    });

    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((_) async => http.Response(
            jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
            401,
          )),
    );

    await expectLater(
      service.getCurrentUser(),
      throwsA(isA<AuthException>()),
    );

    expect(await service.getToken(), 'token-123');
    expect((await service.getStoredUser())?.email, 'owner@example.com');
  });

  test('restoreSessionUser falls back to stored user when auth refresh fails',
      () async {
    const user = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
      onboardingCompleted: true,
    );

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
      'auth_user': jsonEncode(user.toJson()),
    });

    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((_) async => http.Response(
            jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
            401,
          )),
    );

    final restored = await service.restoreSessionUser();

    expect(restored?.email, 'owner@example.com');
    expect(await service.getToken(), 'token-123');
  });
}
