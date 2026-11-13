import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../models/team_claim_preview.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// A claim link that cannot be used. [statusCode] 404 = unknown or used,
/// 410 = expired or already claimed.
class TeamClaimException implements Exception {
  const TeamClaimException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isExpiredOrUsed => statusCode == 410;
  bool get isUnknown => statusCode == 404;

  @override
  String toString() => 'TeamClaimException($statusCode: $message)';
}

/// The public half of the claim flow (SERR-1344): look a claim link up before
/// the owner has an account. The token in the link is the proof, so there is no
/// auth header. Signing in and claiming is `AuthService.claimTeamProfile`.
class TeamClaimService {
  TeamClaimService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// `GET /kolabing-team/claim/{token}`
  Future<TeamClaimPreview> preview(String token) async {
    try {
      final res = await _httpClient.get(
        Uri.parse(
          '$_baseUrl/kolabing-team/claim/${Uri.encodeComponent(token)}',
        ),
        headers: const {'Accept': 'application/json'},
      );
      final body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return TeamClaimPreview.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw TeamClaimException(
        body['message'] as String? ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    } on TeamClaimException {
      rethrow;
    } catch (e) {
      debugPrint('Team claim preview error: $e');
      throw TeamClaimException('Failed to connect to server: $e');
    }
  }
}
