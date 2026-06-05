import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  EventService serviceWith(MockClient client) => EventService(
    authService: AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    ),
    httpClient: client,
  );

  test('getDiscovery parses the public-events feed and pagination', () async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/events/discovery'));
      expect(request.url.queryParameters['page'], '1');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'events': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'event-1',
                'name': 'Rooftop Sundowner',
                'partner_name': 'BCN Runners',
                'date': '2026-07-01',
                'starts_at': '2026-07-01T18:00:00Z',
                'visibility': 'public',
                'location': 'Poble Sec',
                'capacity': 50,
                'going_count': 12,
                'photos': <String>['https://cdn/x.jpg'],
                'community': <String, dynamic>{
                  'id': 'community-1',
                  'name': 'BCN Runners',
                  'slug': 'bcn-runners',
                  'type': 'running',
                  'avatar_url': null,
                },
              },
            ],
            'pagination': <String, dynamic>{
              'current_page': 1,
              'total_pages': 3,
              'total_count': 42,
              'per_page': 15,
            },
          },
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final page = await serviceWith(client).getDiscovery();

    expect(page.events, hasLength(1));
    final event = page.events.first;
    expect(event.id, 'event-1');
    expect(event.visibility, EventVisibility.public);
    expect(event.isPublic, isTrue);
    expect(event.goingCount, 12);
    expect(event.coverPhotoUrl, 'https://cdn/x.jpg');
    expect(event.community?.slug, 'bcn-runners');
    expect(page.currentPage, 1);
    expect(page.totalPages, 3);
    expect(page.hasMore, isTrue);
  });

  test(
    'signup throws MembersOnlyRsvpException on 403 community_membership_required',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/events/event-9/signup'));
        return http.Response(
          jsonEncode(<String, dynamic>{
            'error': 'community_membership_required',
            'message': 'Join this community to RSVP.',
            'community': <String, dynamic>{
              'id': 'community-7',
              'name': 'Iron Club',
            },
          }),
          403,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = serviceWith(client);

      await expectLater(
        service.signup('event-9'),
        throwsA(
          isA<MembersOnlyRsvpException>()
              .having((e) => e.communityId, 'communityId', 'community-7')
              .having((e) => e.communityName, 'communityName', 'Iron Club'),
        ),
      );
    },
  );

  test('signup returns the updated event for a public RSVP', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'id': 'event-3',
            'name': 'Open Picnic',
            'partner_name': 'Park Friends',
            'date': '2026-08-10',
            'visibility': 'public',
            'going_count': 8,
            'my_signup': <String, dynamic>{'status': 'going'},
            'photos': const <dynamic>[],
            'created_at': '2026-08-01T10:00:00Z',
          },
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final event = await serviceWith(client).signup('event-3');

    expect(event.id, 'event-3');
    expect(event.isGoing, isTrue);
    expect(event.visibility, EventVisibility.public);
  });

  test(
    'createUpcomingEvent sends the visibility in the JSON payload',
    () async {
      Map<String, dynamic>? captured;
      final client = MockClient((request) async {
        captured = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'id': 'event-new',
              'name': 'Public Launch',
              'partner_name': 'Org',
              'date': '2026-09-01',
              'visibility': 'public',
              'photos': const <dynamic>[],
              'created_at': '2026-08-20T10:00:00Z',
            },
          }),
          201,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      await serviceWith(client).createUpcomingEvent(
        communityId: 'community-1',
        name: 'Public Launch',
        startsAt: DateTime.utc(2026, 9, 1, 18),
        visibility: EventVisibility.public,
      );

      expect(captured?['visibility'], 'public');
    },
  );
}
