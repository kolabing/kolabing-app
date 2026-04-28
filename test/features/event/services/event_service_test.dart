import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('createEvent uploads both photos and videos when provided', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });

    final photoPath = await _createTempFile('poster.jpg');
    final videoPath = await _createTempFile('recap.mp4');
    addTearDown(() async {
      await _deleteIfExists(photoPath);
      await _deleteIfExists(videoPath);
    });

    final client = _MultipartCaptureClient(
      responseBody: jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 'event-1',
          'name': 'Sunset Rooftop Meetup',
          'partner_name': 'Barcelona Builders',
          'partner_type': 'community',
          'date': '2026-04-28',
          'attendee_count': 120,
          'photos': const <Map<String, dynamic>>[],
          'created_at': '2026-04-28T10:00:00Z',
        },
      }),
    );

    final service = EventService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );

    await service.createEvent(
      EventCreateRequest(
        name: 'Sunset Rooftop Meetup',
        partnerName: 'Barcelona Builders',
        partnerType: PartnerType.community,
        date: DateTime(2026, 4, 28),
        attendeeCount: 120,
        photoPaths: [photoPath],
        videoPaths: [videoPath],
      ),
    );

    expect(client.multipartFieldNames, contains('photos[]'));
    expect(client.multipartFieldNames, contains('videos[]'));
  });
}

Future<String> _createTempFile(String fileName) async {
  final directory = await Directory.systemTemp.createTemp('kolab-event-test');
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);
  return file.path;
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

class _MultipartCaptureClient extends http.BaseClient {
  _MultipartCaptureClient({required this.responseBody});

  final String responseBody;
  final List<String> multipartFieldNames = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.MultipartRequest) {
      multipartFieldNames.addAll(request.files.map((file) => file.field));
    }

    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(responseBody)]),
      201,
      headers: const <String, String>{'content-type': 'application/json'},
      request: request,
    );
  }
}
