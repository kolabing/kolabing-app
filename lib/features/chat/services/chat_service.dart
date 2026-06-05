import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Error from a chat API call. [code] carries the backend machine-readable
/// error code when present (e.g. `chat_limit_reached`, `not_a_member`).
class ChatException implements Exception {
  const ChatException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  /// A community already has its max custom chats (≤5) — reserve for an upsell,
  /// not a raw error.
  bool get isChatLimitReached => code == 'chat_limit_reached';

  @override
  String toString() => 'ChatException($code: $message)';
}

/// API client for Chat (NF-CHAT). Contract:
/// docs/tickets/2026-06-04-chat-feature-spec.md. Built tolerant since the
/// backend is still forming; envelopes/nesting are handled defensively.
class ChatService {
  ChatService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const ChatException('Not authenticated', code: 'unauthenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _unwrap(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] ?? body;
    }
    throw ChatException(
      body['message'] as String? ?? 'Request failed (${res.statusCode})',
      code: body['code'] as String? ?? body['error'] as String?,
      statusCode: res.statusCode,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run, String label) async {
    try {
      return await run();
    } catch (e) {
      if (e is ChatException) rethrow;
      debugPrint('💬 Chat $label error: $e');
      throw ChatException('Failed to connect to server: $e');
    }
  }

  /// `data` may be a flat list, or `{key: [...]}` (paginated). Pull the list.
  List<Map<String, dynamic>> _list(dynamic data, String key) {
    final raw = data is Map ? (data[key] ?? const <dynamic>[]) : data;
    return (raw as List<dynamic>).cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Threads
  // ---------------------------------------------------------------------------

  /// `GET /chats` — threads visible to the viewer (backend role-scopes them;
  /// business is pre-filtered to active threads).
  Future<List<ChatThread>> getThreads() => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/chats'),
          headers: await _headers(),
        );
        return _list(_unwrap(res), 'threads').map(ChatThread.fromJson).toList();
      }, 'getThreads');

  /// `GET /chats/unread-count` — total unread across visible threads.
  Future<int> getUnreadCount() => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/chats/unread-count'),
          headers: await _headers(),
        );
        final data = _unwrap(res);
        if (data is int) return data;
        // Backend returns { total: N }; keep count/unread as tolerant fallbacks.
        if (data is Map) {
          return (data['total'] ?? data['count'] ?? data['unread'] ?? 0) as int;
        }
        return 0;
      }, 'getUnreadCount');

  /// `POST /communities/{community}/chats` — create a custom community chat
  /// (≤5 cap → `chat_limit_reached`).
  Future<ChatThread> createCommunityChat(
    String communityId, {
    required String name,
  }) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/chats'),
          headers: await _headers(),
          body: jsonEncode({'name': name}),
        );
        return ChatThread.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'createCommunityChat');

  /// `POST /events/{event}/chat` — create the event chat (signup-gated).
  Future<ChatThread> createEventChat(String eventId, {String? name}) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/events/$eventId/chat'),
          headers: await _headers(),
          body: jsonEncode({if (name != null) 'name': name}),
        );
        return ChatThread.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'createEventChat');

  /// `POST /chats/{thread}/read` — mark the viewer's read pointer.
  Future<void> markRead(String threadId) => _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/chats/$threadId/read'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'markRead');

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  /// `GET /chats/{thread}/messages?page=` — newest-last.
  Future<List<ChatMessage>> getMessages(String threadId, {int page = 1}) =>
      _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/chats/$threadId/messages?page=$page'),
          headers: await _headers(),
        );
        return _list(_unwrap(res), 'messages')
            .map(ChatMessage.fromJson)
            .toList();
      }, 'getMessages');

  /// `POST /chats/{thread}/messages` — send a message. The backend field is
  /// `content` (verified against the live storeThreadMessage endpoint).
  Future<ChatMessage> sendMessage(String threadId, String content) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/chats/$threadId/messages'),
          headers: await _headers(),
          body: jsonEncode({'content': content}),
        );
        return ChatMessage.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'sendMessage');
}
