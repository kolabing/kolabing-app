import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/community_rewards.dart';
import 'community_service.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// API client for the community gamification "Rewards" tab — goals, rewards,
/// badges, the member rewards-hub, and redemption.
///
/// Contract: docs/tickets/2026-06-12-community-gamification-rewards-contract.md.
/// The backend (P1) ships in PARALLEL, so every read SELF-GATES: a 404/405
/// (route not deployed) or a missing field resolves to an empty/disabled state
/// (`null` hub, `[]` lists) rather than throwing. Writes surface a typed
/// [CommunityException] so the editor sheets can show a message.
class CommunityRewardsService {
  CommunityRewardsService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const CommunityException('Not authenticated',
          code: 'unauthenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// True when a status means "treat this read as empty/unavailable" rather than
  /// an error: endpoint not deployed yet (404/405) or a request that timed out /
  /// the gateway is unreachable (408/503/504 — see [_get]). Self-gating keeps a
  /// stuck request from spinning the Rewards tab forever; it degrades to the
  /// normal empty state, recoverable via pull-to-refresh.
  bool _notDeployed(int status) =>
      status == 404 ||
      status == 405 ||
      status == 408 ||
      status == 503 ||
      status == 504;

  /// GET with a hard timeout. On timeout the future ALWAYS completes (synthetic
  /// 408) so [_notDeployed] can self-gate it — a dropped/slow response can never
  /// hang a section spinner indefinitely.
  Future<http.Response> _get(String path) async {
    final sw = Stopwatch()..start();
    debugPrint('🎯 CommunityRewards GET $path ...');
    try {
      final res = await _httpClient
          .get(Uri.parse('$_baseUrl$path'), headers: await _headers())
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response('', 408),
          );
      debugPrint(
          '🎯 CommunityRewards GET $path -> ${res.statusCode} in ${sw.elapsedMilliseconds}ms');
      return res;
    } catch (e) {
      debugPrint(
          '🎯 CommunityRewards GET $path THREW after ${sw.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  dynamic _unwrap(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] ?? body;
    }
    throw CommunityException(
      body['message'] as String? ?? 'Request failed (${res.statusCode})',
      code: body['code'] as String? ?? body['error'] as String?,
      statusCode: res.statusCode,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run, String label) async {
    try {
      return await run();
    } catch (e) {
      if (e is CommunityException) rethrow;
      debugPrint('🎯 CommunityRewards $label error: $e');
      throw CommunityException('Failed to connect to server: $e');
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) =>
      (data as List<dynamic>).cast<Map<String, dynamic>>();

  // ---------------------------------------------------------------------------
  // Member read — rewards hub (self-gated → null when not deployed)
  // ---------------------------------------------------------------------------

  /// `GET /communities/{id}/rewards-hub`. Returns null when the route isn't
  /// deployed yet (404/405) so the Rewards tab renders a disabled/coming-soon
  /// state instead of crashing.
  Future<CommunityRewardsHub?> getRewardsHub(String communityId) =>
      _guard(() async {
        final res = await _get('/communities/$communityId/rewards-hub');
        if (_notDeployed(res.statusCode)) return null;
        return CommunityRewardsHub.fromJson(
            _unwrap(res) as Map<String, dynamic>);
      }, 'getRewardsHub');

  // ---------------------------------------------------------------------------
  // Leader reads (self-gated → [] when not deployed)
  // ---------------------------------------------------------------------------

  /// `GET /communities/{id}/goals` (leader CRUD list).
  Future<List<CommunityGoal>> getGoals(String communityId) => _guard(() async {
        final res = await _get('/communities/$communityId/goals');
        if (_notDeployed(res.statusCode)) return const <CommunityGoal>[];
        return _asList(_unwrap(res)).map(CommunityGoal.fromJson).toList();
      }, 'getGoals');

  /// `GET /communities/{id}/rewards` (leader CRUD list).
  Future<List<CommunityReward>> getRewards(String communityId) =>
      _guard(() async {
        final res = await _get('/communities/$communityId/rewards');
        if (_notDeployed(res.statusCode)) return const <CommunityReward>[];
        return _asList(_unwrap(res)).map(CommunityReward.fromJson).toList();
      }, 'getRewards');

  /// `GET /communities/{id}/badges` (leader CRUD list).
  Future<List<CommunityBadge>> getBadges(String communityId) =>
      _guard(() async {
        final res = await _get('/communities/$communityId/badges');
        if (_notDeployed(res.statusCode)) return const <CommunityBadge>[];
        return _asList(_unwrap(res)).map(CommunityBadge.fromJson).toList();
      }, 'getBadges');

  // ---------------------------------------------------------------------------
  // Goal CRUD
  // ---------------------------------------------------------------------------

  Future<CommunityGoal> createGoal(String communityId, CommunityGoal goal) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/goals'),
          headers: await _headers(),
          body: jsonEncode(goal.toCreateJson()),
        );
        return CommunityGoal.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'createGoal');

  Future<CommunityGoal> updateGoal(String goalId, CommunityGoal goal) =>
      _guard(() async {
        final res = await _httpClient.put(
          Uri.parse('$_baseUrl/goals/$goalId'),
          headers: await _headers(),
          body: jsonEncode(goal.toCreateJson()),
        );
        return CommunityGoal.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateGoal');

  Future<void> deleteGoal(String goalId) => _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/goals/$goalId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'deleteGoal');

  // ---------------------------------------------------------------------------
  // Reward CRUD + redeem
  // ---------------------------------------------------------------------------

  Future<CommunityReward> createReward(
          String communityId, CommunityReward reward) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/rewards'),
          headers: await _headers(),
          body: jsonEncode(reward.toCreateJson()),
        );
        return CommunityReward.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'createReward');

  Future<CommunityReward> updateReward(
          String rewardId, CommunityReward reward) =>
      _guard(() async {
        final res = await _httpClient.put(
          Uri.parse('$_baseUrl/rewards/$rewardId'),
          headers: await _headers(),
          body: jsonEncode(reward.toCreateJson()),
        );
        return CommunityReward.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateReward');

  Future<void> deleteReward(String rewardId) => _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/rewards/$rewardId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'deleteReward');

  /// `POST /communities/{id}/rewards/{rewardId}/redeem` — deduct points, create
  /// a redemption. Throws [CommunityException] (e.g. `insufficient_points`,
  /// `out_of_stock`) on a guard failure.
  Future<void> redeemReward(String communityId, String rewardId) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse(
              '$_baseUrl/communities/$communityId/rewards/$rewardId/redeem'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'redeemReward');

  // ---------------------------------------------------------------------------
  // Badge CRUD
  // ---------------------------------------------------------------------------

  Future<CommunityBadge> createBadge(
          String communityId, CommunityBadge badge) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/badges'),
          headers: await _headers(),
          body: jsonEncode(badge.toCreateJson()),
        );
        return CommunityBadge.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'createBadge');

  Future<CommunityBadge> updateBadge(String badgeId, CommunityBadge badge) =>
      _guard(() async {
        final res = await _httpClient.put(
          Uri.parse('$_baseUrl/badges/$badgeId'),
          headers: await _headers(),
          body: jsonEncode(badge.toCreateJson()),
        );
        return CommunityBadge.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateBadge');

  Future<void> deleteBadge(String badgeId) => _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/badges/$badgeId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'deleteBadge');
}
