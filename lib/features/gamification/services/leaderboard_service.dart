import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/leaderboard.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Service for handling leaderboard operations
class LeaderboardService {
  LeaderboardService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Get event leaderboard
  ///
  /// GET /api/v1/events/{event_id}/leaderboard
  Future<LeaderboardResponse> getEventLeaderboard(
    String eventId, {
    int limit = 50,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const LeaderboardException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/leaderboard?limit=$limit';
    debugPrint('Get Event Leaderboard: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get Event Leaderboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LeaderboardResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw LeaderboardException(
          json['message'] as String? ?? 'Failed to get leaderboard',
        );
      }
    } on LeaderboardException {
      rethrow;
    } catch (e) {
      debugPrint('Get Event Leaderboard error: $e');
      throw LeaderboardException('Network error: $e');
    }
  }

  /// Get global leaderboard
  ///
  /// GET /api/v1/leaderboard/global
  Future<LeaderboardResponse> getGlobalLeaderboard({
    int limit = 50,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const LeaderboardException('Not authenticated');
    }

    final url = '$_baseUrl/leaderboard/global?limit=$limit';
    debugPrint('Get Global Leaderboard: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get Global Leaderboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LeaderboardResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw LeaderboardException(
          json['message'] as String? ?? 'Failed to get global leaderboard',
        );
      }
    } on LeaderboardException {
      rethrow;
    } catch (e) {
      debugPrint('Get Global Leaderboard error: $e');
      throw LeaderboardException('Network error: $e');
    }
  }
}

/// Exception for leaderboard operations
class LeaderboardException implements Exception {
  const LeaderboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
