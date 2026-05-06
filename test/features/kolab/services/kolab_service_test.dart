import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/services/kolab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test(
    'getMyKolabs parses a flat list response with pagination meta',
    () async {
      final service = KolabService(
        authService: AuthService(secureStorage: const FlutterSecureStorage()),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/kolabs/me');
          expect(request.url.queryParameters['status'], 'draft');
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParameters['per_page'], '10');
          expect(request.headers['Authorization'], 'Bearer token-123');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <Map<String, dynamic>>[
                _kolabJson(id: '1', title: 'Draft One'),
                _kolabJson(id: '2', title: 'Draft Two'),
              ],
              'meta': <String, dynamic>{
                'current_page': 2,
                'last_page': 3,
                'total': 7,
              },
            }),
            200,
          );
        }),
      );

      final response = await service.getMyKolabs(
        status: 'draft',
        page: 2,
        perPage: 10,
      );

      expect(response.data.map((kolab) => kolab.id), <String?>['1', '2']);
      expect(response.currentPage, 2);
      expect(response.lastPage, 3);
      expect(response.total, 7);
      expect(response.hasMore, isTrue);
    },
  );

  test('getMyKolabs parses a Laravel paginator response', () async {
    final service = KolabService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['per_page'], '15');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'data': <Map<String, dynamic>>[
                _kolabJson(id: '3', title: 'Published One'),
              ],
              'current_page': 1,
              'last_page': 1,
              'total': 1,
            },
          }),
          200,
        );
      }),
    );

    final response = await service.getMyKolabs();

    expect(response.data.single.id, '3');
    expect(response.currentPage, 1);
    expect(response.lastPage, 1);
    expect(response.total, 1);
    expect(response.hasMore, isFalse);
  });

  test('create sends venue_preference for community kolabs', () async {
    final service = KolabService(
      authService: AuthService(secureStorage: const FlutterSecureStorage()),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/kolabs');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['intent_type'], 'community_seeking');
        expect(body['venue_preference'], 'no_venue');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': _kolabJson(id: '10', title: 'Community draft')
              ..['venue_preference'] = 'no_venue',
          }),
          201,
        );
      }),
    );

    await service.create(
      const Kolab(
        intentType: IntentType.communitySeeking,
        title: 'Community draft',
        description: 'Looking for a sponsor for our meetup.',
        preferredCity: 'Madrid',
        venuePreference: VenuePreference.noVenue,
      ),
    );
  });
}

Map<String, dynamic> _kolabJson({required String id, required String title}) =>
    <String, dynamic>{
      'id': id,
      'intent_type': 'community_seeking',
      'status': 'draft',
      'title': title,
      'description': 'Description for $title',
      'preferred_city': 'Madrid',
    };
