import 'dart:io';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/services/upload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('upload retries once after refreshing an expired session', () async {
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
              'url': 'https://cdn.kolabing.com/uploads/photo.jpg',
            },
          }),
        ),
      ],
    );

    final authService = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    );
    final uploadService = UploadService(
      authService: authService,
      httpClient: client,
    );

    final filePath = await _createTempUploadFile();
    addTearDown(() async {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    final url = await uploadService.upload(
      filePath: filePath,
      folder: 'kolabs',
    );

    expect(url, 'https://cdn.kolabing.com/uploads/photo.jpg');
    expect(await authService.getToken(), 'token-456');
    expect(await authService.getRefreshToken(), 'refresh-456');
    expect(client.sentAuthHeaders, <String?>[
      'Bearer token-123',
      null,
      'Bearer token-456',
    ]);
  });
}

Future<String> _createTempUploadFile() async {
  final directory = await Directory.systemTemp.createTemp('kolab-upload-test');
  final file = File('${directory.path}/photo.jpg');
  await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);
  return file.path;
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
