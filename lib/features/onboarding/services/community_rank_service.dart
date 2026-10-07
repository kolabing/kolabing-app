import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/community_rank.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Service for the organiser's city-league standing (incentives v1, A).
/// Community profiles only — a non-community caller gets a 403, surfaced as
/// [CommunityRankForbiddenException] so the UI can fall back quietly.
class CommunityRankService {
  CommunityRankService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// GET /me/community-rank
  Future<CommunityRank> getMyCommunityRank() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const CommunityRankException('Not authenticated');
    }

    const url = '$_baseUrl/me/community-rank';
    debugPrint('Get Community Rank: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get Community Rank response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CommunityRank.fromJson(json['data'] as Map<String, dynamic>);
      }
      if (response.statusCode == 403) {
        throw const CommunityRankForbiddenException();
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw CommunityRankException(
        json['message'] as String? ?? 'Failed to get community rank',
      );
    } on CommunityRankException {
      rethrow;
    } catch (e) {
      debugPrint('Get Community Rank error: $e');
      throw CommunityRankException('Network error: $e');
    }
  }
}

class CommunityRankException implements Exception {
  const CommunityRankException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The caller is not a community profile (403) — not an error state, just
/// "this screen has nothing to show for you."
class CommunityRankForbiddenException extends CommunityRankException {
  const CommunityRankForbiddenException() : super('Not a community profile');
}
