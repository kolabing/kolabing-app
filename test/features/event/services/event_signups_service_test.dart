import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  EventService serviceWith(http.Client client) => EventService(
        authService: AuthService(
          secureStorage: const FlutterSecureStorage(),
          httpClient: client,
        ),
        httpClient: client,
      );

  test('getSignups parses the going + waitlist roster', () async {
    final client = _JsonClient(
      jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'going': [
            {
              'id': 's1',
              'profile_id': 'p1',
              'status': 'going',
              'profile': {'id': 'p1', 'name': 'Maria'},
            },
          ],
          'waitlist': [
            {
              'id': 's2',
              'profile_id': 'p2',
              'status': 'waitlisted',
              'waitlist_position': 1,
              'profile': {'id': 'p2', 'name': 'Lucia'},
            },
          ],
        },
      }),
    );

    final signups = await serviceWith(client).getSignups('event-1');

    expect(client.lastUrl, contains('/events/event-1/signups'));
    expect(signups.going.single.name, 'Maria');
    expect(signups.waitlist.single.waitlistPosition, 1);
  });

  test('addEventPhotos posts multipart photos[] and returns the event',
      () async {
    final photoPath = await _createTempFile('poster.jpg');
    addTearDown(() async {
      final f = File(photoPath);
      if (await f.exists()) await f.delete();
    });

    final client = _MultipartCaptureClient(
      responseBody: jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 'event-1',
          'name': 'Sat Long Run',
          'partner_name': 'Run Club',
          'partner_type': 'community',
          'date': '2026-06-14',
          'attendee_count': 0,
          'photos': const <Map<String, dynamic>>[],
          'created_at': '2026-06-01T10:00:00Z',
        },
      }),
    );

    final event =
        await serviceWith(client).addEventPhotos('event-1', [photoPath]);

    expect(client.multipartFieldNames, contains('photos[]'));
    expect(event.id, 'event-1');
  });
}

Future<String> _createTempFile(String fileName) async {
  final directory = await Directory.systemTemp.createTemp('kolab-signups-test');
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);
  return file.path;
}

class _JsonClient extends http.BaseClient {
  _JsonClient(this.body);

  final String body;
  String? lastUrl;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url.toString();
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]),
      200,
      headers: const <String, String>{'content-type': 'application/json'},
      request: request,
    );
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
