// The business community directory (ROLES §2.24, kolabing-v2 BE-NF-78):
// the app reads the server's mask and never re-derives it.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/discovery/services/discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test('reads a page of the directory, masked rows included', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'c-1',
              'identity_masked': true,
              'display_name': null,
              'avatar_url': null,
              'community_type': 'running',
              'community_size': 120,
              'city_name': 'Barcelona',
              'is_verified': true,
              'published_kolabs_count': 0,
            },
            <String, dynamic>{
              'id': 'c-2',
              'identity_masked': false,
              'display_name': 'Gràcia Book Club',
              'avatar_url': 'https://cdn.test/a.png',
              'community_type': 'book_club',
              'community_size': null,
              'city_name': null,
              'is_verified': false,
              'published_kolabs_count': 3,
            },
          ],
          'meta': <String, dynamic>{
            'current_page': 2,
            'last_page': 5,
            'per_page': 20,
            'total': 93,
          },
        }),
        200,
      );
    });

    final service = DiscoveryService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: client,
    );
    final page = await service.getCommunityDirectory(page: 2);

    expect(requested.path, endsWith('/discovery/communities'));
    expect(requested.queryParameters['page'], '2');
    expect(page.total, 93);
    expect(page.hasMore, isTrue);

    final masked = page.data.first;
    expect(masked.identityMasked, isTrue);
    expect(masked.displayName, isNull);
    expect(masked.avatarUrl, isNull);
    expect(masked.communitySize, 120);
    expect(masked.isVerified, isTrue);

    final open = page.data.last;
    expect(open.identityMasked, isFalse);
    expect(open.displayName, 'Gràcia Book Club');
    expect(open.publishedKolabsCount, 3);
  });

  test('a 403 surfaces as an API error, not an empty list', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'success': false,
          'message': 'Only businesses can browse the community directory.',
        }),
        403,
      ),
    );
    final service = DiscoveryService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: client,
    );

    expect(service.getCommunityDirectory(), throwsA(isA<Exception>()));
  });
}
