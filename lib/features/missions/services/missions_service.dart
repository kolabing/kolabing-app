import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/mission.dart';

/// API configuration.
const String _baseUrl = ApiConfig.baseUrl;

/// Service for the gamification missions surface.
///
/// Single endpoint: `GET /api/v1/me/missions` (Bearer auth). The backend
/// returns role-scoped, already-filtered missions, so the app just displays
/// what it gets.
class MissionsService {
  MissionsService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Fetch the signed-in user's missions.
  ///
  /// GET /api/v1/me/missions
  Future<List<Mission>> getMyMissions() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const MissionException('Not authenticated');
    }

    const url = '$_baseUrl/me/missions';
    debugPrint('🎯 Get My Missions: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎯 Get My Missions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        final missionsJson = data is Map<String, dynamic>
            ? data['missions']
            : null;
        if (missionsJson is! List) {
          return const <Mission>[];
        }
        return missionsJson
            .whereType<Map<String, dynamic>>()
            .map(Mission.fromJson)
            .toList();
      } else {
        String? message;
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          message = json['message'] as String?;
        } catch (_) {
          // Non-JSON error body; fall through to generic message.
        }
        throw MissionException(message ?? 'Failed to load missions');
      }
    } catch (e) {
      if (e is MissionException) rethrow;
      debugPrint('🎯 Get My Missions error: $e');
      throw MissionException('Failed to connect to server: $e');
    }
  }
}

/// Exception for mission operations.
class MissionException implements Exception {
  const MissionException(this.message);

  final String message;

  @override
  String toString() => 'MissionException: $message';
}
