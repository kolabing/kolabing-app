import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  http.Response ok() => http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'token': 't-1',
            'token_type': 'Bearer',
            'is_new_user': true,
            'user': <String, dynamic>{
              'id': 'a-1',
              'email': 'a@example.com',
              'user_type': 'attendee',
            },
          },
        }),
        200,
      );

  test('authenticateWithApple includes user_type when provided', () async {
    Map<String, dynamic>? sentBody;
    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return ok();
      }),
    );

    await service.authenticateWithApple(
      'id-tok',
      'Jane Doe',
      userType: 'attendee',
    );

    expect(sentBody?['identity_token'], 'id-tok');
    expect(sentBody?['name'], 'Jane Doe');
    expect(sentBody?['user_type'], 'attendee');
  });

  test('authenticateWithApple omits user_type and name when null', () async {
    Map<String, dynamic>? sentBody;
    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return ok();
      }),
    );

    await service.authenticateWithApple('id-tok', null);

    expect(sentBody?['identity_token'], 'id-tok');
    expect(sentBody?.containsKey('user_type'), isFalse);
    expect(sentBody?.containsKey('name'), isFalse);
  });
}
