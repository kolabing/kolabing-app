import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/chat/models/chat_thread.dart';
import 'package:kolabing_app/features/chat/providers/chat_providers.dart';
import 'package:kolabing_app/features/chat/services/chat_service.dart';
import 'package:kolabing_app/features/chat/widgets/chat_management.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

ChatThread _thread({
  ChatThreadType type = ChatThreadType.communityCustom,
  String name = 'Socials',
}) =>
    ChatThread(
      id: 'thread-1',
      type: type,
      name: name,
      communityId: 'community-1',
      canManage: true,
      createdAt: DateTime(2026, 6, 1),
    );

Future<void> _pump(
  WidgetTester tester, {
  required _CaptureClient client,
  required void Function(BuildContext, WidgetRef) onTap,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatServiceProvider.overrideWith(
          (ref) => ChatService(
            authService: AuthService(
              secureStorage: const FlutterSecureStorage(),
              httpClient: client,
            ),
            httpClient: client,
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onTap(context, ref),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  testWidgets('createCustomChat prompts then POSTs the community chat',
      (tester) async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': _threadJson(name: 'New')}),
    );
    await _pump(
      tester,
      client: client,
      onTap: (context, ref) => ChatManagement.createCustomChat(
        context,
        ref,
        communityId: 'community-1',
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // The name dialog is shown.
    expect(find.text('New chat'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(client.lastMethod, 'POST');
    expect(client.lastUrl, contains('/communities/community-1/chats'));
    expect(jsonDecode(client.lastBody!)['name'], 'New');
  });

  testWidgets('renameChat prompts then PATCHes the thread', (tester) async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': _threadJson(name: 'Updated')}),
    );
    await _pump(
      tester,
      client: client,
      onTap: (context, ref) =>
          ChatManagement.renameChat(context, ref, _thread()),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Rename chat'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(client.lastMethod, 'PATCH');
    expect(client.lastUrl, contains('/chats/thread-1'));
    expect(jsonDecode(client.lastBody!)['name'], 'Updated');
  });

  testWidgets('deleteChat confirms (recoverable) then DELETEs', (tester) async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': null}),
    );
    await _pump(
      tester,
      client: client,
      onTap: (context, ref) =>
          ChatManagement.deleteChat(context, ref, _thread()),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this chat?'), findsOneWidget);
    // Body mentions recovery.
    expect(find.textContaining('recover'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(client.lastMethod, 'DELETE');
    expect(client.lastUrl, contains('/chats/thread-1'));
  });

  testWidgets('joinChat POSTs the join endpoint', (tester) async {
    final client = _CaptureClient(
      jsonEncode(<String, dynamic>{'data': _threadJson(name: 'Open')}),
    );
    await _pump(
      tester,
      client: client,
      onTap: (context, ref) => ChatManagement.joinChat(
        context,
        ref,
        _thread(name: 'Open'),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(client.lastMethod, 'POST');
    expect(client.lastUrl, endsWith('/chats/thread-1/join'));
  });
}

Map<String, dynamic> _threadJson({required String name}) => <String, dynamic>{
      'id': 'thread-1',
      'type': 'community_custom',
      'name': name,
      'community_id': 'community-1',
      'is_open': true,
      'can_manage': true,
      'is_member': true,
      'is_participant': false,
      'unread_count': 0,
      'participant_summary': const <dynamic>[],
      'created_at': '2026-06-01T10:00:00Z',
    };

/// A single captured request (method, url, optional body).
class _Call {
  _Call(this.method, this.url, this.body);
  final String method;
  final String url;
  final String? body;
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  final List<_Call> calls = <_Call>[];

  /// The first non-GET call — the action under test. Background provider
  /// reloads fire GET /chats afterwards, so the *last* call is unreliable.
  _Call get mutating => calls.firstWhere((c) => c.method != 'GET');

  String? get lastMethod => calls.isEmpty ? null : mutating.method;
  String? get lastUrl => calls.isEmpty ? null : mutating.url;
  String? get lastBody => calls.isEmpty ? null : mutating.body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request && request.body.isNotEmpty
        ? request.body
        : null;
    calls.add(_Call(request.method, request.url.toString(), body));
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[utf8.encode(this.body)]),
      statusCode,
      headers: const <String, String>{'content-type': 'application/json'},
      request: request,
    );
  }
}
