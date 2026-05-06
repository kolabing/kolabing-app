import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/dashboard/services/dashboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'getDashboard refreshes once on 401 before returning community data',
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
                'applications_sent': <String, dynamic>{
                  'total': 5,
                  'pending': 2,
                  'accepted': 2,
                  'declined': 1,
                },
                'applications_received': <String, dynamic>{
                  'total': 1,
                  'pending': 1,
                  'accepted': 0,
                  'declined': 0,
                },
                'collaborations': <String, dynamic>{
                  'total': 3,
                  'active': 1,
                  'upcoming': 1,
                  'completed': 1,
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
      final service = DashboardService(
        authService: authService,
        httpClient: client,
      );

      final response = await service.getDashboard();

      expect(response.isCommunity, isTrue);
      expect(response.communityDashboard?.applicationsSent.pending, 2);
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
