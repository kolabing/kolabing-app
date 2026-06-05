import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/friend.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Error from a friends API call. [code] carries the backend's machine-readable
/// error code when present so callers can branch without string-matching.
class FriendException implements Exception {
  const FriendException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'FriendException($code: $message)';
}

/// API client for the friends system (Batch 5).
///
/// All routes are Sanctum-protected; build every URL from [ApiConfig.baseUrl]
/// and send the bearer token from [AuthService].
class FriendService {
  FriendService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const FriendException('Not authenticated', code: 'unauthenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Decode a `{ "data": ... }` envelope, or throw a typed [FriendException]
  /// carrying the backend `code`/`message` on a non-2xx response.
  dynamic _unwrap(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] ?? body;
    }
    throw FriendException(
      body['message'] as String? ?? 'Request failed (${res.statusCode})',
      code: body['code'] as String? ?? body['error'] as String?,
      statusCode: res.statusCode,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run, String label) async {
    try {
      return await run();
    } catch (e) {
      if (e is FriendException) {
        rethrow;
      }
      debugPrint('🤝 Friends $label error: $e');
      throw FriendException('Failed to connect to server: $e');
    }
  }

  List<Map<String, dynamic>> _asList(Object? data) =>
      (data! as List<dynamic>).cast<Map<String, dynamic>>();

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// `GET /me/friends` — the current user's accepted friends.
  Future<List<Friend>> getFriends() => _guard(() async {
    final res = await _httpClient.get(
      Uri.parse('$_baseUrl/me/friends'),
      headers: await _headers(),
    );
    return _asList(_unwrap(res)).map(Friend.fromJson).toList();
  }, 'getFriends');

  /// `GET /me/friends/requests` — incoming + sent pending requests.
  Future<FriendRequests> getRequests() => _guard(() async {
    final res = await _httpClient.get(
      Uri.parse('$_baseUrl/me/friends/requests'),
      headers: await _headers(),
    );
    return FriendRequests.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'getRequests');

  /// `GET /me/friends/suggested` — co-attendance suggestions (>= 3 shared
  /// events). Candidates have no friendship row yet.
  Future<List<Friend>> getSuggested() => _guard(() async {
    final res = await _httpClient.get(
      Uri.parse('$_baseUrl/me/friends/suggested'),
      headers: await _headers(),
    );
    return _asList(_unwrap(res)).map(Friend.fromJson).toList();
  }, 'getSuggested');

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// `POST /friends/requests` {profile_id} — send a friend request. Returns the
  /// created friendship (outgoing/pending).
  Future<Friend> sendRequest(String profileId) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/friends/requests'),
      headers: await _headers(),
      body: jsonEncode({'profile_id': profileId}),
    );
    return Friend.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'sendRequest');

  /// `POST /friends/requests/{id}/accept`.
  Future<Friend> acceptRequest(String friendshipId) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/friends/requests/$friendshipId/accept'),
      headers: await _headers(),
    );
    return Friend.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'acceptRequest');

  /// `POST /friends/requests/{id}/decline`.
  Future<void> declineRequest(String friendshipId) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/friends/requests/$friendshipId/decline'),
      headers: await _headers(),
    );
    _unwrap(res);
  }, 'declineRequest');

  /// `DELETE /friends/{profile}` — unfriend (or cancel a sent request).
  Future<void> unfriend(String profileId) => _guard(() async {
    final res = await _httpClient.delete(
      Uri.parse('$_baseUrl/friends/$profileId'),
      headers: await _headers(),
    );
    _unwrap(res);
  }, 'unfriend');

  /// `POST /friends/{profile}/block`.
  Future<void> block(String profileId) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/friends/$profileId/block'),
      headers: await _headers(),
    );
    _unwrap(res);
  }, 'block');

  /// `POST /friends/{profile}/unblock`.
  Future<void> unblock(String profileId) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/friends/$profileId/unblock'),
      headers: await _headers(),
    );
    _unwrap(res);
  }, 'unblock');
}
