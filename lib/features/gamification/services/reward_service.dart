import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/event_reward.dart';
import '../models/reward_claim.dart';

/// API configuration
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for handling reward operations
class RewardService {
  RewardService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  // ---------------------------------------------------------------------------
  // Event Rewards CRUD (Organizer)
  // ---------------------------------------------------------------------------

  /// Get rewards for an event
  ///
  /// GET /api/v1/events/{event_id}/rewards
  Future<List<EventReward>> getEventRewards(String eventId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/rewards';
    debugPrint('Get Event Rewards: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get Event Rewards response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final rewardsJson = json['data'] as List<dynamic>;
        return rewardsJson
            .map((e) => EventReward.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to get rewards',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Get Event Rewards error: $e');
      throw RewardException('Network error: $e');
    }
  }

  /// Create a new reward for an event
  ///
  /// POST /api/v1/events/{event_id}/rewards
  Future<EventReward> createReward(
    String eventId, {
    required String name,
    String? description,
    required int totalQuantity,
    required double probability,
    DateTime? expiresAt,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/rewards';
    debugPrint('Create Reward: POST $url');

    final body = <String, dynamic>{
      'name': name,
      'total_quantity': totalQuantity,
      'probability': probability,
    };

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (expiresAt != null) {
      body['expires_at'] = expiresAt.toIso8601String();
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('Create Reward response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return EventReward.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to create reward',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Create Reward error: $e');
      throw RewardException('Network error: $e');
    }
  }

  /// Update an existing reward
  ///
  /// PUT /api/v1/event-rewards/{eventReward_id}
  Future<EventReward> updateReward(
    String rewardId, {
    String? name,
    String? description,
    int? totalQuantity,
    double? probability,
    DateTime? expiresAt,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/event-rewards/$rewardId';
    debugPrint('Update Reward: PUT $url');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (totalQuantity != null) body['total_quantity'] = totalQuantity;
    if (probability != null) body['probability'] = probability;
    if (expiresAt != null) body['expires_at'] = expiresAt.toIso8601String();

    try {
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('Update Reward response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return EventReward.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to update reward',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Update Reward error: $e');
      throw RewardException('Network error: $e');
    }
  }

  /// Delete a reward
  ///
  /// DELETE /api/v1/event-rewards/{eventReward_id}
  Future<void> deleteReward(String rewardId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/event-rewards/$rewardId';
    debugPrint('Delete Reward: DELETE $url');

    try {
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Delete Reward response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to delete reward',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Delete Reward error: $e');
      throw RewardException('Network error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Spin the Wheel
  // ---------------------------------------------------------------------------

  /// Spin the wheel for a verified challenge completion
  ///
  /// POST /api/v1/rewards/spin
  Future<SpinResult> spin(String challengeCompletionId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/rewards/spin';
    debugPrint('Spin Wheel: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'challenge_completion_id': challengeCompletionId,
        }),
      );

      debugPrint('Spin Wheel response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SpinResult.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to spin',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Spin Wheel error: $e');
      throw RewardException('Network error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reward Wallet
  // ---------------------------------------------------------------------------

  /// Get user's reward claims (wallet)
  ///
  /// GET /api/v1/me/rewards
  Future<RewardWalletResponse> getMyRewards({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/me/rewards?page=$page&limit=$limit';
    debugPrint('Get My Rewards: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get My Rewards response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RewardWalletResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to get rewards',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Get My Rewards error: $e');
      throw RewardException('Network error: $e');
    }
  }

  /// Generate redeem QR token for a reward claim
  ///
  /// POST /api/v1/reward-claims/{rewardClaim_id}/generate-redeem-qr
  Future<RewardClaim> generateRedeemQR(String rewardClaimId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/reward-claims/$rewardClaimId/generate-redeem-qr';
    debugPrint('Generate Redeem QR: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Generate Redeem QR response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RewardClaim.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to generate QR',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Generate Redeem QR error: $e');
      throw RewardException('Network error: $e');
    }
  }

  /// Confirm reward redemption (organizer)
  ///
  /// POST /api/v1/reward-claims/confirm-redeem
  Future<RewardClaim> confirmRedeem(String redeemToken) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const RewardException('Not authenticated');
    }

    final url = '$_baseUrl/reward-claims/confirm-redeem';
    debugPrint('Confirm Redeem: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': redeemToken,
        }),
      );

      debugPrint('Confirm Redeem response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RewardClaim.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw RewardException(
          json['message'] as String? ?? 'Failed to confirm redemption',
        );
      }
    } on RewardException {
      rethrow;
    } catch (e) {
      debugPrint('Confirm Redeem error: $e');
      throw RewardException('Network error: $e');
    }
  }
}

/// Response wrapper for reward wallet
class RewardWalletResponse {
  const RewardWalletResponse({
    required this.rewards,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory RewardWalletResponse.fromJson(Map<String, dynamic> json) {
    final rewardsJson = json['rewards'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return RewardWalletResponse(
      rewards: rewardsJson
          .map((e) => RewardClaim.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      totalPages: pagination['total_pages'] as int,
      totalCount: pagination['total_count'] as int,
      perPage: pagination['per_page'] as int,
    );
  }

  final List<RewardClaim> rewards;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasMore => currentPage < totalPages;
}

/// Exception for reward operations
class RewardException implements Exception {
  const RewardException(this.message);

  final String message;

  @override
  String toString() => message;
}
