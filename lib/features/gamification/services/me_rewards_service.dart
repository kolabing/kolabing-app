import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/me_rewards_overview.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// API client for the Personal Rewards Screen (P3): `GET /me/rewards-overview`.
///
/// Contract: docs/tickets/2026-06-12-community-gamification-rewards-contract.md.
/// SELF-GATES: a 404/405 (route not deployed) resolves to `null` so the screen
/// renders a graceful empty/coming-soon state instead of throwing. The redeem
/// call for a community reward is NOT here — it reuses P2's
/// `CommunityRewardsService.redeemReward`.
class MeRewardsService {
  MeRewardsService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const MeRewardsException('Not authenticated');
    }
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  /// True when a status means "endpoint not deployed yet" — treat as empty.
  bool _notDeployed(int status) => status == 404 || status == 405;

  /// `GET /me/rewards-overview`. Returns null when the route isn't deployed yet
  /// (404/405) so the screen shows a coming-soon/empty state instead of crashing.
  Future<MeRewardsOverview?> getOverview() async {
    try {
      final res = await _httpClient.get(
        Uri.parse('$_baseUrl/me/rewards-overview'),
        headers: await _headers(),
      );
      if (_notDeployed(res.statusCode)) return null;

      final body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = (body['data'] ?? body) as Map<String, dynamic>;
        return MeRewardsOverview.fromJson(data);
      }
      throw MeRewardsException(
        body['message'] as String? ?? 'Request failed (${res.statusCode})',
      );
    } on MeRewardsException {
      rethrow;
    } catch (e) {
      debugPrint('🎁 MeRewards getOverview error: $e');
      throw MeRewardsException('Failed to connect to server: $e');
    }
  }
}

/// Exception for personal rewards operations.
class MeRewardsException implements Exception {
  const MeRewardsException(this.message);

  final String message;

  @override
  String toString() => message;
}
