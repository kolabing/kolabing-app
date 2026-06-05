import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/friends/models/friend.dart';
import 'package:kolabing_app/features/friends/services/friend_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  FriendService buildService(MockClientHandler handler) => FriendService(
    authService: AuthService(secureStorage: const FlutterSecureStorage()),
    httpClient: MockClient(handler),
  );

  Map<String, dynamic> friendJson(
    String friendshipId,
    String profileId, {
    String status = 'accepted',
    String direction = 'mutual',
  }) => <String, dynamic>{
    'id': friendshipId,
    'status': status,
    'direction': direction,
    'profile': <String, dynamic>{
      'id': profileId,
      'name': 'Profile $profileId',
      'avatar_url': null,
      'user_type': 'attendee',
    },
  };

  test('getFriends parses the accepted list with auth header', () async {
    final service = buildService((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/me/friends');
      expect(request.headers['Authorization'], 'Bearer token-123');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <Map<String, dynamic>>[friendJson('fr-1', 'p-1')],
        }),
        200,
      );
    });

    final friends = await service.getFriends();

    expect(friends, hasLength(1));
    expect(friends.single.friendshipId, 'fr-1');
    expect(friends.single.profileId, 'p-1');
    expect(friends.single.isAccepted, isTrue);
  });

  test('getRequests splits incoming and sent buckets', () async {
    final service = buildService((request) async {
      expect(request.url.path, '/api/v1/me/friends/requests');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'incoming': <Map<String, dynamic>>[
              friendJson('fr-in', 'p-in', status: 'pending'),
            ],
            'sent': <Map<String, dynamic>>[
              friendJson('fr-out', 'p-out', status: 'pending'),
            ],
          },
        }),
        200,
      );
    });

    final requests = await service.getRequests();

    expect(requests.incoming.single.profileId, 'p-in');
    expect(requests.incoming.single.isIncoming, isTrue);
    expect(requests.sent.single.profileId, 'p-out');
    expect(requests.sent.single.isOutgoing, isTrue);
  });

  test('getSuggested parses co-attendance candidates', () async {
    final service = buildService((request) async {
      expect(request.url.path, '/api/v1/me/friends/suggested');
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'shared_event_count': 4,
              'profile': <String, dynamic>{
                'id': 'p-sug',
                'name': 'Suggested One',
              },
            },
          ],
        }),
        200,
      );
    });

    final suggested = await service.getSuggested();

    expect(suggested.single.profileId, 'p-sug');
    expect(suggested.single.sharedEventCount, 4);
    expect(suggested.single.friendshipId, isNull);
  });

  test('sendRequest posts the profile_id body', () async {
    late Map<String, dynamic> sentBody;
    final service = buildService((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/friends/requests');
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode(<String, dynamic>{
          'data': friendJson(
            'fr-new',
            'p-target',
            status: 'pending',
            direction: 'outgoing',
          ),
        }),
        201,
      );
    });

    final created = await service.sendRequest('p-target');

    expect(sentBody['profile_id'], 'p-target');
    expect(created.isPending, isTrue);
    expect(created.isOutgoing, isTrue);
  });

  test('acceptRequest hits the accept route', () async {
    final service = buildService((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/friends/requests/fr-1/accept');
      return http.Response(
        jsonEncode(<String, dynamic>{'data': friendJson('fr-1', 'p-1')}),
        200,
      );
    });

    final friend = await service.acceptRequest('fr-1');

    expect(friend.isAccepted, isTrue);
  });

  test('declineRequest hits the decline route', () async {
    var called = false;
    final service = buildService((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/friends/requests/fr-1/decline');
      called = true;
      return http.Response('', 204);
    });

    await service.declineRequest('fr-1');

    expect(called, isTrue);
  });

  test('unfriend DELETEs the profile route', () async {
    final service = buildService((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/v1/friends/p-1');
      return http.Response('', 204);
    });

    await service.unfriend('p-1');
  });

  test('block and unblock hit their routes', () async {
    final blockService = buildService((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/friends/p-1/block');
      return http.Response('', 200);
    });
    await blockService.block('p-1');

    final unblockService = buildService((request) async {
      expect(request.url.path, '/api/v1/friends/p-1/unblock');
      return http.Response('', 200);
    });
    await unblockService.unblock('p-1');
  });

  test('non-2xx responses throw a typed FriendException with code', () async {
    final service = buildService(
      (request) async => http.Response(
        jsonEncode(<String, dynamic>{
          'message': 'You already sent a request.',
          'code': 'duplicate_request',
        }),
        422,
      ),
    );

    expect(
      () => service.sendRequest('p-1'),
      throwsA(
        isA<FriendException>()
            .having((e) => e.code, 'code', 'duplicate_request')
            .having((e) => e.statusCode, 'statusCode', 422),
      ),
    );
  });

  test('FriendRequests.fromJson stamps bucket direction when omitted', () {
    final requests = FriendRequests.fromJson(<String, dynamic>{
      'incoming': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'a',
          'profile': <String, dynamic>{'id': 'p-a', 'name': 'A'},
        },
      ],
      'sent': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'b',
          'profile': <String, dynamic>{'id': 'p-b', 'name': 'B'},
        },
      ],
    });

    expect(requests.incoming.single.direction, FriendshipDirection.incoming);
    expect(requests.sent.single.direction, FriendshipDirection.outgoing);
  });
}
