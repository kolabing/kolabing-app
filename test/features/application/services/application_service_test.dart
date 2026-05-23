import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/application/services/application_service.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'getMyApplications refreshes once on 401 before returning paginated data',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
      });

      final client = _QueuedClient(
        responses: [
          _QueuedResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'token': 'token-456',
                'refresh_token': 'refresh-456',
                'token_type': 'Bearer',
              },
            }),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'app-1',
                    'collab_opportunity_id': 'opp-1',
                    'message': 'Excited to collaborate',
                    'availability': 'Next Thursday evening',
                    'status': 'pending',
                    'created_at': '2026-04-28T10:00:00Z',
                  },
                ],
                'current_page': 1,
                'last_page': 2,
                'total': 2,
              },
            }),
          ),
        ],
      );

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      );
      final service = ApplicationService(
        authService: authService,
        httpClient: client,
      );

      final response = await service.getMyApplications();

      expect(response.data.single.id, 'app-1');
      expect(response.currentPage, 1);
      expect(response.lastPage, 2);
      expect(response.total, 2);
      expect(await authService.getToken(), 'token-456');
      expect(await authService.getRefreshToken(), 'refresh-456');
      expect(client.sentAuthHeaders, <String?>[
        'Bearer token-123',
        null,
        'Bearer token-456',
      ]);
    },
  );

  test(
    'getReceivedApplications refreshes once on 401 before returning paginated data',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
      });

      final client = _QueuedClient(
        responses: [
          _QueuedResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'token': 'token-456',
                'refresh_token': 'refresh-456',
                'token_type': 'Bearer',
              },
            }),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'app-2',
                    'collab_opportunity_id': 'opp-2',
                    'message': 'We would love to host you',
                    'availability': 'Every Friday',
                    'status': 'pending',
                    'created_at': '2026-04-29T10:00:00Z',
                  },
                ],
                'current_page': 1,
                'last_page': 1,
                'total': 1,
              },
            }),
          ),
        ],
      );

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      );
      final service = ApplicationService(
        authService: authService,
        httpClient: client,
      );

      final response = await service.getReceivedApplications();

      expect(response.data.single.id, 'app-2');
      expect(response.currentPage, 1);
      expect(response.lastPage, 1);
      expect(response.total, 1);
      expect(await authService.getToken(), 'token-456');
      expect(await authService.getRefreshToken(), 'refresh-456');
      expect(client.sentAuthHeaders, <String?>[
        'Bearer token-123',
        null,
        'Bearer token-456',
      ]);
    },
  );

  test(
    'acceptApplication refreshes once on 401 and parses 201 responses',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
      });

      final client = _QueuedClient(
        responses: [
          _QueuedResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'token': 'token-456',
                'refresh_token': 'refresh-456',
                'token_type': 'Bearer',
              },
            }),
          ),
          _QueuedResponse(
            statusCode: 201,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'application': <String, dynamic>{
                  'id': 'app-1',
                  'collab_opportunity_id': 'opp-1',
                  'message': 'Excited to collaborate',
                  'availability': 'Next Thursday evening',
                  'status': 'accepted',
                  'created_at': '2026-04-28T10:00:00Z',
                },
              },
            }),
          ),
        ],
      );

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      );
      final service = ApplicationService(
        authService: authService,
        httpClient: client,
      );

      final application = await service.acceptApplication(
        'app-1',
        scheduledDate: '2026-05-01',
        contactMethods: const <String, String>{'email': 'owner@kolabing.com'},
      );

      expect(application.id, 'app-1');
      expect(application.status.name, 'accepted');
      expect(await authService.getToken(), 'token-456');
      expect(await authService.getRefreshToken(), 'refresh-456');
      expect(client.sentAuthHeaders, <String?>[
        'Bearer token-123',
        null,
        'Bearer token-456',
      ]);
    },
  );

  test(
    'submitApplication refreshes once on 401 before succeeding',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
      });

      final client = _QueuedClient(
        responses: [
          _QueuedResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'token': 'token-456',
                'refresh_token': 'refresh-456',
                'token_type': 'Bearer',
              },
            }),
          ),
          _QueuedResponse(
            statusCode: 201,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'id': 'app-3',
                'collab_opportunity_id': 'opp-3',
                'message': 'Count us in',
                'availability': 'Saturday morning',
                'status': 'pending',
                'created_at': '2026-05-01T10:00:00Z',
              },
            }),
          ),
        ],
      );

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      );
      final service = ApplicationService(
        authService: authService,
        httpClient: client,
      );

      final application = await service.submitApplication(
        opportunityId: 'opp-3',
        message: 'Count us in',
        availability: 'Saturday morning',
      );

      expect(application.id, 'app-3');
      expect(application.status.name, 'pending');
      expect(await authService.getToken(), 'token-456');
      expect(await authService.getRefreshToken(), 'refresh-456');
      expect(client.sentAuthHeaders, <String?>[
        'Bearer token-123',
        null,
        'Bearer token-456',
      ]);
    },
  );

  test(
    'getApplication refreshes once on 401 before returning details',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
        'auth_refresh_token': 'refresh-123',
      });

      final client = _QueuedClient(
        responses: [
          _QueuedResponse(
            statusCode: 401,
            body: jsonEncode(<String, dynamic>{'message': 'Unauthenticated'}),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'token': 'token-456',
                'refresh_token': 'refresh-456',
                'token_type': 'Bearer',
              },
            }),
          ),
          _QueuedResponse(
            statusCode: 200,
            body: jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'id': 'app-4',
                'collab_opportunity_id': 'opp-4',
                'message': 'Details please',
                'availability': 'Weeknights',
                'status': 'accepted',
                'created_at': '2026-05-02T10:00:00Z',
              },
            }),
          ),
        ],
      );

      final authService = AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      );
      final service = ApplicationService(
        authService: authService,
        httpClient: client,
      );

      final application = await service.getApplication('app-4');

      expect(application.id, 'app-4');
      expect(application.status.name, 'accepted');
      expect(await authService.getToken(), 'token-456');
      expect(await authService.getRefreshToken(), 'refresh-456');
      expect(client.sentAuthHeaders, <String?>[
        'Bearer token-123',
        null,
        'Bearer token-456',
      ]);
    },
  );
}

class _QueuedClient extends http.BaseClient {
  _QueuedClient({required this.responses});

  final List<_QueuedResponse> responses;
  final List<String?> sentAuthHeaders = <String?>[];
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_index >= responses.length) {
      throw StateError('No queued response for ${request.url}');
    }

    sentAuthHeaders.add(request.headers['Authorization']);
    final response = responses[_index++];

    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(response.body)]),
      response.statusCode,
      headers: const <String, String>{'content-type': 'application/json'},
      request: request,
    );
  }
}

class _QueuedResponse {
  const _QueuedResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
