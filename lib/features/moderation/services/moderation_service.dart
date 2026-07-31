import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';

/// API base URL — the single source of truth ([ApiConfig.baseUrl]).
const String _baseUrl = ApiConfig.baseUrl;

/// The report target kinds understood by the backend (`content_reports.target_type`).
///
/// Wire values are a stable contract — match the backend snake_case exactly.
enum ReportTargetType {
  profile('profile'),
  kolab('kolab'),
  review('review'),
  chatMessage('chat_message');

  const ReportTargetType(this.wire);

  /// The exact string sent to / stored by the backend.
  final String wire;
}

/// The report reasons offered to the user (`content_reports.reason`).
///
/// Wire values are a stable contract — match the backend enum exactly.
enum ReportReason {
  spam('spam'),
  harassment('harassment'),
  inappropriate('inappropriate'),
  other('other');

  const ReportReason(this.wire);

  final String wire;
}

/// UGC-moderation API client — report content and block/unblock users.
///
/// Built to the App-Review 1.2 contract:
/// - `GET    /me/blocks`            → `{ "data": ["<profileId>", ...] }`
/// - `POST   /me/blocks/{id}`       → 200/201 (idempotent)
/// - `DELETE /me/blocks/{id}`       → 200
/// - `POST   /reports`             → 201
///
/// All calls are Sanctum Bearer authenticated. The backend for this feature may
/// not be deployed yet, so every call **self-gates on HTTP 404**: the moderation
/// surfaces stay safe and inert (`blockedProfileIds` → `[]`; `block`/`unblock`/
/// `report` → no-op) until the endpoints ship.
class ModerationService {
  ModerationService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // Blocked profile IDs
  // ---------------------------------------------------------------------------

  /// GET /me/blocks — the profile IDs the viewer has blocked.
  ///
  /// Returns `[]` on 404 (feature not yet deployed) or any error, so the app
  /// degrades safely rather than surfacing a moderation failure to the user.
  Future<List<String>> blockedProfileIds() async {
    return _blockedProfileIds(allowRetry: true);
  }

  Future<List<String>> _blockedProfileIds({required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/me/blocks');
    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? const [];
        return data.map((e) => e.toString()).toList();
      } else if (response.statusCode == 401 && allowRetry) {
        await _authService.refreshSession();
        return _blockedProfileIds(allowRetry: false);
      } else if (response.statusCode == 404) {
        // Feature-off: backend not deployed yet.
        return const [];
      }
      debugPrint('ModerationService.blockedProfileIds: ${response.statusCode}');
      return const [];
    } on Exception catch (e) {
      debugPrint('ModerationService.blockedProfileIds error: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Block / unblock
  // ---------------------------------------------------------------------------

  /// POST /me/blocks/{profileId} — idempotent. Throws on a genuine failure so
  /// callers can revert an optimistic UI update; a 404 (feature-off) is a no-op.
  Future<void> block(String profileId) async {
    await _setBlocked(profileId, blocked: true, allowRetry: true);
  }

  /// DELETE /me/blocks/{profileId}. Throws on failure; 404 is a no-op.
  Future<void> unblock(String profileId) async {
    await _setBlocked(profileId, blocked: false, allowRetry: true);
  }

  Future<void> _setBlocked(
    String profileId, {
    required bool blocked,
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/me/blocks/$profileId');
    try {
      final headers = await _getHeaders();
      final response = blocked
          ? await _httpClient.post(uri, headers: headers)
          : await _httpClient.delete(uri, headers: headers);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401 && allowRetry) {
        await _authService.refreshSession();
        return _setBlocked(profileId, blocked: blocked, allowRetry: false);
      } else if (response.statusCode == 404) {
        // Feature-off: backend not deployed yet — treat as success (no-op).
        return;
      }
      throw ModerationException(
        'Block request failed (${response.statusCode}).',
      );
    } on ModerationException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('ModerationService._setBlocked error: $e');
      throw ModerationException('Block request failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Report content
  // ---------------------------------------------------------------------------

  /// POST /reports — flag objectionable content.
  ///
  /// [reportedProfileId] is the profile responsible for the content (optional
  /// for content not tied to a single author). Throws on failure so the sheet
  /// can show an error; a 404 (feature-off) resolves as a no-op success.
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? reportedProfileId,
    String? note,
  }) async {
    await _report(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      reportedProfileId: reportedProfileId,
      note: note,
      allowRetry: true,
    );
  }

  Future<void> _report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    required String? reportedProfileId,
    required String? note,
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/reports');
    final body = jsonEncode({
      'target_type': targetType.wire,
      'target_id': targetId,
      if (reportedProfileId != null && reportedProfileId.isNotEmpty)
        'reported_profile_id': reportedProfileId,
      'reason': reason.wire,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else if (response.statusCode == 401 && allowRetry) {
        await _authService.refreshSession();
        return _report(
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          reportedProfileId: reportedProfileId,
          note: note,
          allowRetry: false,
        );
      } else if (response.statusCode == 404) {
        // Feature-off: backend not deployed yet — treat as success (no-op).
        return;
      }
      throw ModerationException(
        'Report request failed (${response.statusCode}).',
      );
    } on ModerationException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('ModerationService._report error: $e');
      throw ModerationException('Report request failed: $e');
    }
  }
}

/// Thrown when a moderation request fails for a reason the UI should surface.
class ModerationException implements Exception {
  const ModerationException(this.message);

  final String message;

  @override
  String toString() => 'ModerationException: $message';
}
