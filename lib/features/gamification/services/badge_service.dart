import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/badge.dart';

/// API configuration
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for handling badge operations
class BadgeService {
  BadgeService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Get all system badges
  ///
  /// GET /api/v1/badges
  Future<BadgesResponse> getAllBadges() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const BadgeException('Not authenticated');
    }

    final url = '$_baseUrl/badges';
    debugPrint('Get All Badges: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get All Badges response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return BadgesResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw BadgeException(
          json['message'] as String? ?? 'Failed to get badges',
        );
      }
    } on BadgeException {
      rethrow;
    } catch (e) {
      debugPrint('Get All Badges error: $e');
      throw BadgeException('Network error: $e');
    }
  }

  /// Get user's earned badges
  ///
  /// GET /api/v1/me/badges
  Future<MyBadgesResponse> getMyBadges() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const BadgeException('Not authenticated');
    }

    final url = '$_baseUrl/me/badges';
    debugPrint('Get My Badges: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get My Badges response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return MyBadgesResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw BadgeException(
          json['message'] as String? ?? 'Failed to get badges',
        );
      }
    } on BadgeException {
      rethrow;
    } catch (e) {
      debugPrint('Get My Badges error: $e');
      throw BadgeException('Network error: $e');
    }
  }
}

/// Exception for badge operations
class BadgeException implements Exception {
  const BadgeException(this.message);

  final String message;

  @override
  String toString() => message;
}
