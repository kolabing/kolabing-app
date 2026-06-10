import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/chat/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  ChatService serviceWith(http.Client client) => ChatService(
        authService: AuthService(
          secureStorage: const FlutterSecureStorage(),
          httpClient: client,
        ),
        httpClient: client,
      );

  Map<String, dynamic> threadJson({
    String type = 'community_custom',
    String? name = 'Renamed',
  }) =>
      <String, dynamic>{
        'id': 'thread-1',
        'type': type,
        'name': name,
        'is_open': true,
        'can_manage': true,
        'is_member': true,
        'is_participant': false,
        'unread_count': 0,
        'participant_summary': const <dynamic>[],
        'created_at': '2026-06-01T10:00:00Z',
      };

  test('renameThread PATCHes /chats/{id} with the new name', () async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': threadJson()}),
    );

    final thread = await serviceWith(client).renameThread('thread-1', 'Renamed');

    expect(client.lastMethod, 'PATCH');
    expect(client.lastUrl, contains('/chats/thread-1'));
    expect(jsonDecode(client.lastBody!)['name'], 'Renamed');
    expect(thread.name, 'Renamed');
  });

  test('deleteThread DELETEs /chats/{id}', () async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': null}),
    );

    await serviceWith(client).deleteThread('thread-1');

    expect(client.lastMethod, 'DELETE');
    expect(client.lastUrl, contains('/chats/thread-1'));
  });

  test('joinThread POSTs /chats/{id}/join and returns the thread', () async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{
        'data': threadJson()..['is_participant'] = true,
      }),
    );

    final thread = await serviceWith(client).joinThread('thread-1');

    expect(client.lastMethod, 'POST');
    expect(client.lastUrl, endsWith('/chats/thread-1/join'));
    expect(thread.isParticipant, isTrue);
  });

  test('removeMember POSTs /chats/{id}/members/{profile}/remove', () async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': null}),
    );

    await serviceWith(client).removeMember('thread-1', 'profile-9');

    expect(client.lastMethod, 'POST');
    expect(client.lastUrl, endsWith('/chats/thread-1/members/profile-9/remove'));
  });

  test('rename surfaces a backend ChatException', () async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{
        'message': 'Only custom chats can be renamed.',
        'error': 'cannot_rename_thread_type',
      }),
      statusCode: 422,
    );

    expect(
      () => serviceWith(client).renameThread('thread-1', 'X'),
      throwsA(
        isA<ChatException>()
            .having((e) => e.code, 'code', 'cannot_rename_thread_type'),
      ),
    );
  });
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  String? lastUrl;
  String? lastMethod;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUrl = request.url.toString();
    lastMethod = request.method;
    if (request is http.Request) {
      lastBody = request.body.isEmpty ? null : request.body;
    }
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(body)]),
      statusCode,
      headers: const <String, String>{'content-type': 'application/json'},
      request: request,
    );
  }
}
