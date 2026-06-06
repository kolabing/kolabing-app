import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_membership.dart';
import '../models/community_tier.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Error from a community/roster/tier API call. [code] carries the backend's
/// machine-readable error code when present (e.g. `community_limit_reached`,
/// `invite_only`) so callers can branch without string-matching messages.
class CommunityException implements Exception {
  const CommunityException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  /// The free-plan cap was hit (creating a 2nd community → NF-7 Community
  /// Premium gate). Reserved here so the UI can show the upsell, not an error.
  bool get isCommunityLimitReached => code == 'community_limit_reached';

  /// Tried to self-join an `invite_only` community.
  bool get isInviteOnly => code == 'invite_only';

  /// Invite-by-email matched no Kolabing account.
  bool get isProfileNotFound => code == 'profile_not_found' || statusCode == 404;

  @override
  String toString() => 'CommunityException($code: $message)';
}

/// API client for Community Members + tiers (NF-6).
///
/// Contract: docs/tickets/2026-06-02-community-members-tiers-backend-prompt.md.
/// All routes are Sanctum-protected; build every URL from [ApiConfig.baseUrl]
/// and send the bearer token from [AuthService].
class CommunityService {
  CommunityService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const CommunityException('Not authenticated', code: 'unauthenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Decode a `{ "data": ... }` envelope, or throw a typed [CommunityException]
  /// carrying the backend `code`/`message` on a non-2xx response.
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
      debugPrint('🏘️ Community $label error: $e');
      throw CommunityException('Failed to connect to server: $e');
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) =>
      (data as List<dynamic>).cast<Map<String, dynamic>>();

  // ---------------------------------------------------------------------------
  // Communities (leader-owned)
  // ---------------------------------------------------------------------------

  /// `GET /me/communities` — communities the current leader owns.
  Future<List<Community>> getMyCommunities() => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/me/communities'),
          headers: await _headers(),
        );
        return _asList(_unwrap(res)).map(Community.fromJson).toList();
      }, 'getMyCommunities');

  /// `GET /me/memberships` — communities the current member belongs to; each
  /// item nests the `community` and the member's `tier` in it.
  Future<List<CommunityMembership>> getMyMemberships() => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/me/memberships'),
          headers: await _headers(),
        );
        return _asList(_unwrap(res)).map(CommunityMembership.fromJson).toList();
      }, 'getMyMemberships');

  /// `GET /communities/{id}`.
  Future<Community> getCommunity(String id) => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/communities/$id'),
          headers: await _headers(),
        );
        return Community.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'getCommunity');

  /// `POST /communities` — create. Throws [CommunityException] with
  /// `isCommunityLimitReached` when the 1-free cap is hit (NF-7 gate).
  Future<Community> createCommunity({
    required String name,
    required CommunityType type,
    String? description,
    CommunityJoinPolicy joinPolicy = CommunityJoinPolicy.open,
    String? avatarUrl,
  }) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name,
            'type': type.toApiValue(),
            if (description != null) 'description': description,
            'join_policy': joinPolicy.toApiValue(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }),
        );
        final community = Community.fromJson(
          _unwrap(res) as Map<String, dynamic>,
        );
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.communityCreated,
            properties: {
              'community_id': community.id,
              'type': type.toApiValue(),
            },
          ),
        );
        return community;
      }, 'createCommunity');

  /// `PATCH /communities/{id}`.
  Future<Community> updateCommunity(
    String id, {
    String? name,
    String? description,
    CommunityJoinPolicy? joinPolicy,
    String? avatarUrl,
  }) =>
      _guard(() async {
        final res = await _httpClient.patch(
          Uri.parse('$_baseUrl/communities/$id'),
          headers: await _headers(),
          body: jsonEncode({
            if (name != null) 'name': name,
            if (description != null) 'description': description,
            if (joinPolicy != null) 'join_policy': joinPolicy.toApiValue(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }),
        );
        return Community.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateCommunity');

  /// `POST /communities/{id}/join` — member self-join (open communities only;
  /// `invite_only` throws with `isInviteOnly`).
  Future<CommunityMember> joinCommunity(String communityId) => _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/join'),
          headers: await _headers(),
        );
        final member = CommunityMember.fromJson(
          _unwrap(res) as Map<String, dynamic>,
        );
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.communityJoined,
            properties: {'community_id': communityId},
          ),
        );
        return member;
      }, 'joinCommunity');

  // ---------------------------------------------------------------------------
  // Tiers
  // ---------------------------------------------------------------------------

  /// `GET /communities/{id}/tiers`.
  Future<List<CommunityTier>> getTiers(String communityId) => _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/communities/$communityId/tiers'),
          headers: await _headers(),
        );
        return _asList(_unwrap(res)).map(CommunityTier.fromJson).toList();
      }, 'getTiers');

  /// `POST /communities/{id}/tiers`.
  Future<CommunityTier> createTier(
    String communityId, {
    required String name,
    required int rank,
    required TierAssignmentRule assignmentRule,
    String? color,
    int? threshold,
    TierPermissions? permissions,
  }) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/tiers'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name,
            'rank': rank,
            'assignment_rule': assignmentRule.toApiValue(),
            if (color != null) 'color': color,
            if (threshold != null) 'threshold': threshold,
            if (permissions != null) 'permissions': permissions.toJson(),
          }),
        );
        final tier = CommunityTier.fromJson(_unwrap(res) as Map<String, dynamic>);
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.tierCreated,
            properties: {'community_id': communityId},
          ),
        );
        return tier;
      }, 'createTier');

  /// `PATCH /tiers/{tier}`.
  Future<CommunityTier> updateTier(
    String tierId, {
    String? name,
    int? rank,
    TierAssignmentRule? assignmentRule,
    String? color,
    int? threshold,
    TierPermissions? permissions,
  }) =>
      _guard(() async {
        final res = await _httpClient.patch(
          Uri.parse('$_baseUrl/tiers/$tierId'),
          headers: await _headers(),
          body: jsonEncode({
            if (name != null) 'name': name,
            if (rank != null) 'rank': rank,
            if (assignmentRule != null)
              'assignment_rule': assignmentRule.toApiValue(),
            if (color != null) 'color': color,
            if (threshold != null) 'threshold': threshold,
            if (permissions != null) 'permissions': permissions.toJson(),
          }),
        );
        return CommunityTier.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateTier');

  /// `DELETE /tiers/{tier}`.
  Future<void> deleteTier(String tierId) => _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/tiers/$tierId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'deleteTier');

  // ---------------------------------------------------------------------------
  // Roster
  // ---------------------------------------------------------------------------

  /// `GET /communities/{id}/members` — roster. The backend paginates and
  /// nests the list as `data: { members: [...], pagination: {...} }`; tolerate
  /// a flat `data: [...]` too.
  Future<List<CommunityMember>> getMembers(
    String communityId, {
    int page = 1,
  }) =>
      _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/communities/$communityId/members?page=$page'),
          headers: await _headers(),
        );
        final data = _unwrap(res);
        final list = data is Map
            ? (data['members'] as List<dynamic>? ?? const [])
            : data as List<dynamic>;
        return list
            .cast<Map<String, dynamic>>()
            .map(CommunityMember.fromJson)
            .toList();
      }, 'getMembers');

  /// `POST /communities/{id}/members` — invite/add a member by the email on
  /// their Kolabing account. (Backend resolves email → profile; throws with
  /// `isProfileNotFound` when no account matches.)
  Future<CommunityMember> addMember(
    String communityId, {
    required String email,
    String? tierId,
  }) =>
      _guard(() async {
        final res = await _httpClient.post(
          Uri.parse('$_baseUrl/communities/$communityId/members'),
          headers: await _headers(),
          body: jsonEncode({
            'email': email,
            if (tierId != null) 'tier_id': tierId,
          }),
        );
        return CommunityMember.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'addMember');

  /// `PATCH /communities/{id}/members/{member}` — set tier / can_manage / status.
  Future<CommunityMember> updateMember(
    String communityId,
    String memberId, {
    String? tierId,
    bool? canManage,
    MembershipStatus? status,
  }) =>
      _guard(() async {
        final res = await _httpClient.patch(
          Uri.parse('$_baseUrl/communities/$communityId/members/$memberId'),
          headers: await _headers(),
          body: jsonEncode({
            if (tierId != null) 'tier_id': tierId,
            if (canManage != null) 'can_manage': canManage,
            if (status != null) 'status': status.toApiValue(),
          }),
        );
        return CommunityMember.fromJson(_unwrap(res) as Map<String, dynamic>);
      }, 'updateMember');

  /// `DELETE /communities/{id}/members/{member}`.
  Future<void> removeMember(String communityId, String memberId) =>
      _guard(() async {
        final res = await _httpClient.delete(
          Uri.parse('$_baseUrl/communities/$communityId/members/$memberId'),
          headers: await _headers(),
        );
        _unwrap(res);
      }, 'removeMember');
}
