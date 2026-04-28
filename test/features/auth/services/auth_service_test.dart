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
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          401,
        ),
      ),
    );

    await expectLater(service.getCurrentUser(), throwsA(isA<AuthException>()));

    expect(await service.getToken(), 'token-123');
    expect((await service.getStoredUser())?.email, 'owner@example.com');
  });

  test(
    'restoreSessionUser falls back to stored user when auth refresh fails',
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
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
            401,
          ),
        ),
      );

      final restored = await service.restoreSessionUser();

      expect(restored?.email, 'owner@example.com');
      expect(await service.getToken(), 'token-123');
    },
  );

  test('refreshSession stores the new token and refresh token', () async {
    const user = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
      onboardingCompleted: true,
    );

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
      'auth_refresh_token': 'refresh-123',
      'auth_user': jsonEncode(user.toJson()),
    });

    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'token': 'token-456',
              'refresh_token': 'refresh-456',
              'token_type': 'Bearer',
            },
          }),
          200,
        );
      }),
    );

    final token = await service.refreshSession();

    expect(token, 'token-456');
    expect(await service.getToken(), 'token-456');
    expect(await service.getRefreshToken(), 'refresh-456');
    expect((await service.getStoredUser())?.email, 'owner@example.com');
  });

  test(
    'restoreSessionUser refreshes the token after a 401 and retries me',
    () async {
      const staleUser = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
        onboardingCompleted: true,
      );
    const freshUser = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
      onboardingCompleted: true,
    );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
        'auth_user': jsonEncode(staleUser.toJson()),
      });

      var meCalls = 0;
      final service = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/me') {
            meCalls++;
            final authHeader = request.headers['Authorization'];
            if (authHeader == 'Bearer token-123') {
              return http.Response(
                jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
                401,
              );
            }

            expect(authHeader, 'Bearer token-456');
            return http.Response(
              jsonEncode(<String, dynamic>{'data': freshUser.toJson()}),
              200,
            );
          }

          if (request.url.path == '/api/v1/auth/refresh') {
            return http.Response(
              jsonEncode(<String, dynamic>{
                'data': <String, dynamic>{
                  'token': 'token-456',
                  'refresh_token': 'refresh-456',
                  'token_type': 'Bearer',
                },
              }),
              200,
            );
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );

      final restored = await service.restoreSessionUser();

    expect(restored?.email, 'owner@example.com');
      expect(await service.getToken(), 'token-456');
      expect(await service.getRefreshToken(), 'refresh-456');
      expect(meCalls, 2);
    },
  );
}
