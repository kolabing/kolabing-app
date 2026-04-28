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
