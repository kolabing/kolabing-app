import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('getCurrentUser clears stored auth on 401 without a refresh token', () async {
    const user = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
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

    expect(await service.getToken(), isNull);
    expect(await service.getStoredUser(), isNull);
  });

  test(
    'restoreSessionUser falls back to stored user on network failure',
    () async {
      const user = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
      );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_user': jsonEncode(user.toJson()),
      });

      final service = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: MockClient(
          (_) async => throw Exception('network down'),
        ),
      );

      final restored = await service.restoreSessionUser();

      expect(restored?.email, 'owner@example.com');
      expect(await service.getToken(), 'token-123');
      expect((await service.getStoredUser())?.email, 'owner@example.com');
    },
  );

  test('refreshSession stores the new token and refresh token', () async {
    const user = UserModel(
      id: 'user-1',
      email: 'owner@example.com',
      userType: UserType.business,
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
      );
      const freshUser = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
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

  test(
    'logout prevents an in-flight refresh from restoring the session',
    () async {
      const user = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
      );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
        'auth_user': jsonEncode(user.toJson()),
      });

      final refreshResponse = Completer<http.Response>();
      final service = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            return refreshResponse.future;
          }

          if (request.url.path == '/api/v1/auth/logout') {
            return http.Response(
              jsonEncode(<String, dynamic>{'success': true}),
              200,
            );
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );

      final pendingRefresh = service.refreshSession();
      await Future<void>.delayed(Duration.zero);

      await service.logout();

      refreshResponse.complete(
        http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'token': 'token-456',
              'refresh_token': 'refresh-456',
              'token_type': 'Bearer',
            },
          }),
          200,
        ),
      );

      await expectLater(
        pendingRefresh,
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Session expired. Please sign in again.',
          ),
        ),
      );
      expect(await service.getToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getStoredUser(), isNull);
    },
  );

  test(
    'logout from another auth service instance prevents restoring the session',
    () async {
      const user = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
      );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
        'auth_user': jsonEncode(user.toJson()),
      });

      final refreshResponse = Completer<http.Response>();
      final sharedStorage = const FlutterSecureStorage();
      final refreshingService = AuthService(
        secureStorage: sharedStorage,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            return refreshResponse.future;
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );
      final logoutService = AuthService(
        secureStorage: sharedStorage,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/logout') {
            return http.Response(
              jsonEncode(<String, dynamic>{'success': true}),
              200,
            );
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );

      final pendingRefresh = refreshingService.refreshSession();
      await Future<void>.delayed(Duration.zero);

      await logoutService.logout();

      refreshResponse.complete(
        http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'token': 'token-456',
              'refresh_token': 'refresh-456',
              'token_type': 'Bearer',
            },
          }),
          200,
        ),
      );

      await expectLater(
        pendingRefresh,
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Session expired. Please sign in again.',
          ),
        ),
      );
      expect(await refreshingService.getToken(), isNull);
      expect(await refreshingService.getRefreshToken(), isNull);
      expect(await refreshingService.getStoredUser(), isNull);
    },
  );

  test(
    'restoreSessionUser clears persisted auth when both me and refresh are unauthorized',
    () async {
      const user = UserModel(
        id: 'user-1',
        email: 'owner@example.com',
        userType: UserType.business,
      );

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
        'auth_user': jsonEncode(user.toJson()),
      });

      final service = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/me') {
            return http.Response(
              jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
              401,
            );
          }

          if (request.url.path == '/api/v1/auth/refresh') {
            return http.Response(
              jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
              401,
            );
          }

          throw AssertionError('Unexpected request: ${request.url}');
        }),
      );

      final restored = await service.restoreSessionUser();

      expect(restored, isNull);
      expect(await service.getToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getStoredUser(), isNull);
    },
  );

  test('registerBusiness sends referral_code when present', () async {
    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/register/business');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['referral_code'], 'KOLAB-IRSC');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'token': 'token-123',
              'token_type': 'Bearer',
              'is_new_user': true,
              'user': const UserModel(
                id: 'business-1',
                email: 'business@example.com',
                userType: UserType.business,
              ).toJson(),
            },
          }),
          201,
        );
      }),
    );

    await service.registerBusiness(
      email: 'business@example.com',
      password: 'password123',
      onboardingData: const OnboardingData(
        userType: UserType.business,
        name: 'Venue Works',
        businessTypeIds: ['1'],
        businessTypeSlugs: ['cafe'],
        businessTypeNames: ['Cafe'],
        location: PlaceSuggestion(
          placeId: 'place-1',
          title: 'Venue Works',
          formattedAddress: 'Carrer 1',
          city: 'Barcelona',
          cityId: 'city-1',
        ),
        venueName: 'Venue Works',
        venueType: 'cafe',
        venueCapacity: 80,
        referralCode: 'kolab-irsc',
      ),
    );
  });

  test('registerDeviceToken sends richer metadata when provided', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });

    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/me/device-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'fcm-token-123');
        expect(body['platform'], isNotEmpty);
        expect(body['app_version'], '1.4.0');
        expect(body['locale'], 'tr');
        expect(body['timezone'], 'Europe/Istanbul');
        return http.Response(
          jsonEncode(<String, dynamic>{'success': true}),
          200,
        );
      }),
    );

    await service.registerDeviceToken(
      'fcm-token-123',
      appVersion: '1.4.0',
      locale: 'tr',
      timezone: 'Europe/Istanbul',
    );
  });

  test('removeDeviceToken calls delete endpoint with token body', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });

    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/me/device-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['token'], 'fcm-token-123');
        return http.Response(
          jsonEncode(<String, dynamic>{'success': true}),
          200,
        );
      }),
    );

    await service.removeDeviceToken('fcm-token-123');
  });
}
