import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/instagram/services/instagram_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  InstagramService serviceFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = MockClient(handler);
    return InstagramService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );
  }

  http.Response ok(Object? data) => http.Response(
    jsonEncode(<String, dynamic>{'success': true, 'data': data}),
    200,
  );

  test(
    'getStatus unwraps {success, data} and sends the bearer token',
    () async {
      late http.Request sent;
      final service = serviceFor((request) async {
        sent = request;
        return ok(<String, dynamic>{'enabled': true, 'connected': false});
      });

      final status = await service.getStatus();

      expect(sent.method, 'GET');
      expect(sent.url.path, endsWith('/api/v1/me/instagram'));
      expect(sent.headers['Authorization'], 'Bearer token-123');
      expect(status?.enabled, isTrue);
      expect(status?.connected, isFalse);
    },
  );

  for (final code in <int>[403, 404]) {
    test('getStatus: a $code hides the card (null)', () async {
      final service = serviceFor(
        (_) async => http.Response('{"message":"Not found"}', code),
      );
      expect(await service.getStatus(), isNull);
    });
  }

  test('getStatus: a 500 throws', () async {
    final service = serviceFor(
      (_) async => http.Response('{"message":"boom"}', 500),
    );
    expect(
      service.getStatus(),
      throwsA(
        isA<InstagramException>()
            .having((e) => e.message, 'message', 'boom')
            .having((e) => e.statusCode, 'statusCode', 500),
      ),
    );
  });

  test('getConnectUrl POSTs and returns the authorize URL', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return ok(<String, dynamic>{
        'url': 'https://www.instagram.com/oauth/authorize?client_id=1&state=s',
      });
    });

    final url = await service.getConnectUrl();

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/me/instagram/connect-url'));
    expect(url.host, 'www.instagram.com');
    expect(url.queryParameters['state'], 's');
  });

  test('getConnectUrl: a missing url throws', () async {
    final service = serviceFor((_) async => ok(<String, dynamic>{}));
    expect(service.getConnectUrl(), throwsA(isA<InstagramException>()));
  });

  test('getMedia passes the cursor and parses the page', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return ok(<String, dynamic>{
        'items': [
          {'id': '1', 'media_type': 'VIDEO'},
        ],
        'next_cursor': null,
      });
    });

    final page = await service.getMedia(cursor: 'QV/+=');

    expect(sent.url.path, endsWith('/me/instagram/media'));
    expect(sent.url.queryParameters['cursor'], 'QV/+=');
    expect(page.items.single.isVideo, isTrue);
    expect(page.hasMore, isFalse);
  });

  test('getMedia: a 404 here is an error, not a hidden state', () async {
    final service = serviceFor((_) async => http.Response('', 404));
    expect(service.getMedia(), throwsA(isA<InstagramException>()));
  });

  test('importMedia POSTs ids + target and counts the result', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return ok([
        {'id': 10},
        {'id': 11},
      ]);
    });

    final result = await service.importMedia(['a', 'b']);

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/me/instagram/media/import'));
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), <String, dynamic>{
      'ids': ['a', 'b'],
      'target': 'gallery',
    });
    expect(result.importedCount, 2);
  });

  test('sync POSTs and disconnect DELETEs', () async {
    final calls = <String>[];
    final service = serviceFor((request) async {
      calls.add('${request.method} ${request.url.path}');
      return ok(null);
    });

    await service.sync();
    await service.disconnect();

    expect(calls, [
      'POST /api/v1/me/instagram/sync',
      'DELETE /api/v1/me/instagram',
    ]);
  });

  test('non-JSON body throws', () async {
    final service = serviceFor((_) async => http.Response('<html>', 200));
    expect(service.getStatus(), throwsA(isA<InstagramException>()));
  });
}
