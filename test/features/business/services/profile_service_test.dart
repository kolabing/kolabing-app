import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test('createCheckoutSession sends referral_code when present', () async {
    final service = ProfileService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/me/subscription/checkout');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['referral_code'], 'KOLAB-IRSC');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'checkout_url': 'https://checkout.stripe.com/test',
            },
          }),
          200,
        );
      }),
    );

    final url = await service.createCheckoutSession(
      successUrl: 'kolabing://subscription/success',
      cancelUrl: 'kolabing://subscription/cancel',
      referralCode: 'kolab-irsc',
    );

    expect(url, 'https://checkout.stripe.com/test');
  });

  test(
    'validateReferralCode sends normalized code and returns backend value',
    () async {
      final service = ProfileService(
        authService: AuthService(secureStorage: const FlutterSecureStorage()),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/referrals/validate');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['referral_code'], 'KOLAB-IRSC');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': <String, dynamic>{'referral_code': 'KOLAB-IRSC'},
            }),
            200,
          );
        }),
      );

      final validatedCode = await service.validateReferralCode(' kolab-irsc ');

      expect(validatedCode, 'KOLAB-IRSC');
    },
  );

  test('verifyApplePurchase sends referral_code when present', () async {
    final service = ProfileService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/me/subscription/apple-verify');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['referral_code'], 'KOLAB-IRSC');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'id': 'sub-1',
              'status': 'active',
              'is_active': true,
            },
          }),
          200,
        );
      }),
    );

    final subscription = await service.verifyApplePurchase(
      transactionId: 'tx-1',
      originalTransactionId: 'otx-1',
      productId: 'com.kolabing.app.subscription.monthly',
      referralCode: 'kolab-irsc',
    );

    expect(subscription.isActive, isTrue);
  });
}
