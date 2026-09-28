import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/league_models.dart';

/// API configuration.
const String _baseUrl = ApiConfig.baseUrl;

/// Service for the organiser city league + organiser level.
///
/// Graceful degradation: a 403 (not a community profile) or 404 (endpoint not
/// deployed yet) resolves to `null`, which the UI treats as "hide this
/// surface". Anything else unexpected throws [LeagueException].
class LeagueService {
  LeagueService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// GET /api/v1/me/community-rank
  Future<CommunityRank?> getCommunityRank() async {
    final data = await _getData('$_baseUrl/me/community-rank');
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    return map == null ? null : CommunityRank.fromJson(map);
  }

  /// GET /api/v1/leagues/{city}/current
  Future<LeagueTable?> getCurrentLeague(String city) async {
    final data = await _getData(
      '$_baseUrl/leagues/${Uri.encodeComponent(city)}/current',
    );
    return data == null ? null : LeagueTable.fromJson(data);
  }

  /// GET /api/v1/me/organiser-level
  Future<OrganiserLevel?> getOrganiserLevel() async {
    final data = await _getData('$_baseUrl/me/organiser-level');
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    return map == null ? null : OrganiserLevel.fromJson(map);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the `data` member of a 200 response, or null for 403/404.
  Future<Object?> _getData(String url, {bool allowRetry = true}) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const LeagueException('Not authenticated');
    }

    debugPrint('League: GET $url');
    final http.Response response;
    try {
      response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      throw LeagueException('Network error: $e');
    }

    final status = response.statusCode;
    if (status == 401 && allowRetry) {
      await _authService.refreshSession();
      return _getData(url, allowRetry: false);
    }
    if (status == 403 || status == 404) {
      debugPrint('League: $status for $url, hiding surface');
      return null;
    }
    if (status != 200) {
      throw LeagueException(_messageFrom(response.body, status));
    }

    try {
      final json = jsonDecode(response.body);
      return json is Map ? json['data'] : null;
    } on FormatException {
      throw const LeagueException('Invalid response format');
    }
  }

  String _messageFrom(String body, int status) {
    try {
      final json = jsonDecode(body);
      final message = json is Map ? json['message'] : null;
      if (message is String && message.isNotEmpty) return message;
    } on FormatException {
      // fall through
    }
    return 'Request failed with status $status';
  }
}

/// Exception for league / organiser-level operations.
class LeagueException implements Exception {
  const LeagueException(this.message);

  final String message;

  @override
  String toString() => message;
}
