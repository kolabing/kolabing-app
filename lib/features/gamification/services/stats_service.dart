import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/gamification_stats.dart';

/// API configuration
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for handling gamification stats and game card operations
class StatsService {
  StatsService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Get current user's gamification stats
  ///
  /// GET /api/v1/me/gamification-stats
  Future<GamificationStats> getMyStats() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const StatsException('Not authenticated');
    }

    final url = '$_baseUrl/me/gamification-stats';
    debugPrint('Get My Stats: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get My Stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GamificationStats.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw StatsException(
          json['message'] as String? ?? 'Failed to get stats',
        );
      }
    } on StatsException {
      rethrow;
    } catch (e) {
      debugPrint('Get My Stats error: $e');
      throw StatsException('Network error: $e');
    }
  }

  /// Get a user's public game card
  ///
  /// GET /api/v1/profiles/{profile}/game-card
  Future<GameCard> getGameCard(String profileId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const StatsException('Not authenticated');
    }

    final url = '$_baseUrl/profiles/$profileId/game-card';
    debugPrint('Get Game Card: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get Game Card response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GameCard.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw StatsException(
          json['message'] as String? ?? 'Failed to get game card',
        );
      }
    } on StatsException {
      rethrow;
    } catch (e) {
      debugPrint('Get Game Card error: $e');
      throw StatsException('Network error: $e');
    }
  }
}

/// Exception for stats operations
class StatsException implements Exception {
  const StatsException(this.message);

  final String message;

  @override
  String toString() => message;
}
