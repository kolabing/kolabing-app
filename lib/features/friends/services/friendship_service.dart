import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/friendship.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Error from a friendship API call. [code] carries the backend
/// machine-readable error code when present (e.g. `already_friends`,
/// `request_exists`, `cannot_friend_self`).
class FriendshipException implements Exception {
  const FriendshipException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  /// The endpoint isn't deployed yet (404). The UI must self-gate: hide the
  /// friends surfaces, never crash, never spam errors.
  bool get isFeatureOff => statusCode == 404;

  bool get alreadyFriends => code == 'already_friends';
  bool get requestExists => code == 'request_exists';
  bool get cannotFriendSelf => code == 'cannot_friend_self';

  @override
  String toString() => 'FriendshipException($code: $message)';
}

/// API client for the friend graph (NF-17).
///
/// Contract: docs/tickets/2026-06-10-friends-graph-NF17-contract.md. Every
/// endpoint self-gates — a 404 (backend not yet deployed) surfaces as a
/// [FriendshipException] with [FriendshipException.isFeatureOff] so callers can
/// silently degrade rather than crash.
class FriendshipService {
  FriendshipService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const FriendshipException(
        'Not authenticated',
        code: 'unauthenticated',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Unwraps a successful response body's `data`, or throws a typed exception.
  /// A 404 becomes a `feature off` exception (statusCode 404) so self-gating
  /// callers can detect it.
  dynamic _unwrap(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(res.body) as Map<String, dynamic>);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] ?? body;
    }
    throw FriendshipException(
      body['message'] as String? ?? 'Request failed (${res.statusCode})',
      code: body['code'] as String? ?? body['error'] as String?,
      statusCode: res.statusCode,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run, String label) async {
    try {
      return await run();
    } catch (e) {
      if (e is FriendshipException) rethrow;
      debugPrint('👥 Friends $label error: $e');
      throw FriendshipException('Failed to connect to server: $e');
    }
  }

  List<Map<String, dynamic>> _list(Object? data, String key) {
    final raw = data is Map ? (data[key] ?? const <dynamic>[]) : data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// `POST /friends/{profile}` — send a friend request (requester = me). If a
  /// reverse pending exists the backend auto-accepts (mutual).
  Future<void> sendRequest(String profileId) => _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/friends/$profileId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'sendRequest');

  /// `POST /friends/{profile}/accept` — accept an incoming pending request.
  Future<void> accept(String profileId) => _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/friends/$profileId/accept'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'accept');

  /// `POST /friends/{profile}/decline` — decline an incoming pending request.
  Future<void> decline(String profileId) => _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/friends/$profileId/decline'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'decline');

  /// `DELETE /friends/{profile}` — remove a friend OR cancel my outgoing
  /// request (deletes the row either way).
  Future<void> remove(String profileId) => _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/friends/$profileId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'remove');

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// `GET /me/friends` — accepted friends (first page).
  Future<List<FriendSummary>> getFriends({int page = 1}) => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/me/friends?page=$page'),
          headers: await _headers(),
        );
        return _list(_unwrap(res), 'friends')
            .map(FriendSummary.fromJson)
            .toList();
      }, 'getFriends');

  /// `GET /me/friend-requests` — incoming pending requests + count badge.
  Future<FriendRequests> getFriendRequests() => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/me/friend-requests'),
          headers: await _headers(),
        );
        final data = _unwrap(res);
        final list = _list(data, 'requests').isNotEmpty
            ? _list(data, 'requests')
            : _list(data, 'data');
        final requests = list.map(FriendSummary.fromJson).toList();
        final count = data is Map
            ? ((data['count'] as num?)?.toInt() ?? requests.length)
            : requests.length;
        return FriendRequests(requests: requests, count: count);
      }, 'getFriendRequests');
}
