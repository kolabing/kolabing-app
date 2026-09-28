import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/league/services/league_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  LeagueService serviceFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = MockClient(handler);
    return LeagueService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );
  }

  http.Response ok(Object data) => http.Response(
    jsonEncode(<String, dynamic>{'success': true, 'data': data}),
    200,
  );

  test('getCommunityRank parses a 200 and sends the bearer token', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return ok(<String, dynamic>{
        'city': 'Barcelona',
        'city_id': 17,
        'rank': 4,
        'total': 12,
      });
    });

    final rank = await service.getCommunityRank();

    expect(sent.url.path, endsWith('/me/community-rank'));
    expect(sent.headers['Authorization'], 'Bearer token-123');
    expect(rank?.rank, 4);
    expect(rank?.city?.name, 'Barcelona');
    expect(rank?.city?.key, '17');
  });

  for (final status in <int>[403, 404]) {
    test('a $status hides the surface (returns null)', () async {
      final service = serviceFor(
        (_) async =>
            http.Response('{"success":false,"message":"Nope"}', status),
      );
      expect(await service.getCommunityRank(), isNull);
      expect(await service.getOrganiserLevel(), isNull);
      expect(await service.getCurrentLeague('barcelona'), isNull);
    });
  }

  test('a 500 throws LeagueException with the backend message', () async {
    final service = serviceFor(
      (_) async => http.Response('{"message":"Boom"}', 500),
    );
    expect(
      service.getOrganiserLevel,
      throwsA(
        isA<LeagueException>().having((e) => e.message, 'message', 'Boom'),
      ),
    );
  });

  test('a non-JSON 200 throws LeagueException', () async {
    final service = serviceFor((_) async => http.Response('<html>', 200));
    expect(service.getCommunityRank, throwsA(isA<LeagueException>()));
  });

  test('a 200 without data resolves to null', () async {
    final service = serviceFor((_) async => http.Response('{}', 200));
    expect(await service.getCommunityRank(), isNull);
  });

  test('getCurrentLeague requests the city id path', () async {
    late Uri url;
    final service = serviceFor((request) async {
      url = request.url;
      return ok(<String, dynamic>{
        'city': 'Barcelona',
        'city_id': '17',
        'divisions_enabled': false,
        'divisions': <dynamic>[
          <String, dynamic>{
            'key': 'city',
            'label': 'City',
            'rows': <dynamic>[
              <String, dynamic>{'rank': 1, 'display_name': 'A', 'points': 3},
            ],
          },
        ],
      });
    });

    final table = await service.getCurrentLeague('17');

    expect(url.path, endsWith('/leagues/17/current'));
    expect(table?.divisions.single.rows.single.displayName, 'A');
  });

  test('getOrganiserLevel parses the level', () async {
    final service = serviceFor(
      (_) async => ok(<String, dynamic>{
        'level': 'trusted',
        'criteria': <dynamic>[],
        'perks': <dynamic>['Shown first to venues'],
      }),
    );
    final level = await service.getOrganiserLevel();
    expect(level?.levelRaw, 'trusted');
    expect(level?.perks, <String>['Shown first to venues']);
  });

  test('throws when not authenticated', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final service = serviceFor((_) async => ok(<String, dynamic>{}));
    expect(service.getCommunityRank, throwsA(isA<LeagueException>()));
  });
}
