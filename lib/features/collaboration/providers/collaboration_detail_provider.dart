import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../gamification/models/challenge.dart';
import '../models/collaboration.dart';

/// Provider for collaboration detail.
final collaborationDetailProvider = FutureProvider.family<Collaboration?, String>((
  ref,
  id,
) async {
  // No mock fallback: a failed fetch surfaces as an error/empty state so we
  // never render fabricated data (see docs/BACKEND-SCHEMA.md — never hardcode).
  return fetchCollaborationDetail(id);
});

Future<Collaboration?> fetchCollaborationDetail(String id) {
  return _fetchCollaborationDetail(id, allowRetry: true);
}

Future<Collaboration?> _fetchCollaborationDetail(
  String id, {
  required bool allowRetry,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$id';
  debugPrint('[D3] GET $url');

  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );

  debugPrint('[D3] detail response status=${response.statusCode}');

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    final raw = data is Map<String, dynamic>
        ? (data['collaboration'] as Map<String, dynamic>? ?? data)
        : json;
    return Collaboration.fromJson(normalizeCollaborationResponse(raw));
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _fetchCollaborationDetail(id, allowRetry: false);
  }

  if (response.statusCode == 404) {
    return null;
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to load collaboration'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Known `error_code` values the backend returns from
/// `POST /collaborations/{id}/complete`. As of the 2026-06-26 completion-flow
/// simplification (PR 1), `/complete` gates on the lightweight completion
/// CONFIRMATION (yes/no/not_yet) — not rich `/feedback` — so the
/// `awaiting*Feedback` codes below are dead on the wire but kept for a brief
/// transition window in case an old backend deploy is still live.
class CollaborationCompletionErrorCode {
  CollaborationCompletionErrorCode._();

  /// The caller has not yet submitted their own completion confirmation.
  static const awaitingOwnCompletionConfirmation =
      'awaiting_own_completion_confirmation';

  /// The caller's confirmation is in; the Kolab only completes once the
  /// partner confirms too. This is a SOFT SUCCESS, not an error.
  static const awaitingPartnerCompletionConfirmation =
      'awaiting_partner_completion_confirmation';

  /// Both parties confirmed, but at least one said 'no' or 'not_yet'.
  static const completionNotConfirmed = 'completion_not_confirmed';

  /// Generic "cannot complete" (e.g. already completed by the partner).
  static const cannotComplete = 'cannot_complete';

  /// The status cannot move to `completed` from its current value.
  static const invalidStatusTransition = 'invalid_status_transition';

  // --- Deprecated (pre-PR-1 feedback gate); kept only for transition safety.
  static const awaitingOwnFeedback = 'awaiting_own_feedback';
  static const awaitingPartnerFeedback = 'awaiting_partner_feedback';
}

/// Thrown by [markCollaborationCompleted] when `/complete` fails the feedback
/// gate or a status transition. Carries the backend `error_code` + `message`
/// so the UI can surface a specific, localized message (and treat
/// `awaiting_partner_feedback` as a soft success) instead of a generic error.
class CollaborationCompletionException implements Exception {
  const CollaborationCompletionException({
    required this.errorCode,
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// One of [CollaborationCompletionErrorCode], or null if the body had none.
  final String? errorCode;
  final String message;
  final int? statusCode;

  /// Raw `errors` object from the backend body. For `completion_not_confirmed`
  /// this carries `own_status` / `partner_status` so the UI can show the
  /// partner's specific answer (no/not_yet) instead of generic "waiting" copy.
  final Map<String, dynamic>? errors;

  /// The partner's completion status ('no' | 'not_yet'), if the backend
  /// reported one in `errors.partner_status`.
  String? get partnerStatus => errors?['partner_status'] as String?;

  @override
  String toString() =>
      'CollaborationCompletionException(errorCode: $errorCode, message: $message)';
}

/// Submit (or update) the caller's lightweight completion confirmation —
/// `POST /api/v1/collaborations/{id}/completion`. As of the 2026-06-26
/// completion-flow simplification (PR 1), THIS — not rich `/feedback` — gates
/// `/complete`. `status` is one of `yes` / `no` / `not_yet`; `note` is an
/// optional free-text note (max 500 chars). XP is awarded once, on first
/// submission; resubmitting to change your answer (e.g. `not_yet` → `yes`)
/// never re-awards it.
Future<void> submitCollaborationCompletion(
  String id, {
  required String status,
  String? note,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$id/completion';
  final payload = <String, dynamic>{
    'status': status,
    if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
  };
  debugPrint('[D3] POST $url payload=$payload');

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  debugPrint('[D3] completion response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.collaborationCompletionConfirmed,
        properties: {'collaboration_id': id, 'status': status},
      ),
    );
    return;
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to submit completion confirmation'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Submit OPTIONAL post-Kolab feedback — `POST /api/v1/collaborations/{id}/feedback`.
///
/// As of PR 1 (2026-06-26) this is optional impact data and no longer gates
/// `/complete` (see [submitCollaborationCompletion] above). This is distinct
/// from the public `POST /{id}/review` (a decoupled star review shown
/// post-completion) — do not conflate the two.
///
/// Payload (per the backend contract):
///   - `rating` (int 1-5, required)
///   - `expectation_match` (bool, required)
///   - `would_recommend` (bool, required)
///   - `would_collaborate_again` (bool, required) — the backend MIRRORS this
///     feedback into the public review automatically, so the app no longer
///     POSTs the separate `/review` at completion.
///   - `posts_reels` (int 0-10000, nullable) — both roles
///   - BUSINESS only: `stories_posted` (int nullable), `revenue` (num nullable)
///   - COMMUNITY only: `benefits` (string ≤2000, nullable)
///
/// Sending a field reserved for the other role is rejected (`prohibited`), so
/// callers MUST pass the correct [isBusiness] for the signed-in user.
///
/// Returns normally on 201. If the caller already submitted feedback the
/// backend errors; we swallow that as "already done" and return without
/// throwing so the caller can proceed straight to `/complete`.
Future<void> submitCollaborationFeedback(
  String id, {
  required bool isBusiness,
  required int rating,
  required bool expectationMatch,
  required bool wouldRecommend,
  required bool wouldCollaborateAgain,
  int? postsReels,
  int? storiesPosted,
  num? revenue,
  String? benefits,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$id/feedback';
  final payload = <String, dynamic>{
    'rating': rating,
    'expectation_match': expectationMatch,
    'would_recommend': wouldRecommend,
    'would_collaborate_again': wouldCollaborateAgain,
    if (postsReels != null) 'posts_reels': postsReels,
    if (isBusiness && storiesPosted != null) 'stories_posted': storiesPosted,
    if (isBusiness && revenue != null) 'revenue': revenue,
    if (!isBusiness && benefits != null && benefits.trim().isNotEmpty)
      'benefits': benefits.trim(),
  };
  debugPrint('[D3] POST $url payload=$payload');

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  debugPrint('[D3] feedback response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.feedbackSubmitted,
        properties: {'collaboration_id': id, 'rating': rating},
      ),
    );
    return;
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(response.body) as Map<String, dynamic>;
  final message = (body['message'] as String?)?.toLowerCase() ?? '';
  final errorCode = (body['error_code'] as String?)?.toLowerCase() ?? '';

  // Already submitted → treat as "done" and let the caller proceed to /complete.
  final alreadySubmitted =
      message.contains('already') ||
      errorCode.contains('already') ||
      errorCode == 'feedback_already_submitted' ||
      errorCode == 'feedback_exists';
  if (alreadySubmitted) {
    debugPrint('[D3] feedback already submitted — continuing to /complete');
    return;
  }

  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Submit the OPTIONAL public 5-star Kolab review —
/// `POST /api/v1/collaborations/{id}/review`.
///
/// PR 2 (2026-06-28) of the completion-flow simplification: this is the
/// decoupled, optional "how good was it?" review, separate from the
/// completion confirmation ("did it happen?"). All five ratings (1-5) are
/// required by the backend when using this new format; `publicComment` is
/// optional (max 2000 chars). Idempotent on the backend — resubmitting
/// returns the existing review without awarding XP again, so callers don't
/// need to guard against double-submission themselves.
Future<void> submitCollaborationReview(
  String id, {
  required int communicationRating,
  required int reliabilityRating,
  required int fitRating,
  required int valueRating,
  required int repeatRating,
  String? publicComment,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$id/review';
  final payload = <String, dynamic>{
    'communication_rating': communicationRating,
    'reliability_rating': reliabilityRating,
    'fit_rating': fitRating,
    'value_rating': valueRating,
    'repeat_rating': repeatRating,
    if (publicComment != null && publicComment.trim().isNotEmpty)
      'public_comment': publicComment.trim(),
  };
  debugPrint('[D3] POST $url payload=$payload');

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  debugPrint('[D3] review response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.feedbackSubmitted,
        properties: {'collaboration_id': id, 'kind': 'star_review'},
      ),
    );
    return;
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to submit review'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Mark a collaboration as completed (D3).
///
/// `POST /api/v1/collaborations/{id}/complete` — empty body. On 200 it returns
/// the updated collaboration JSON. On a 4xx the body is
/// `{success:false, message, error_code, errors}`; this throws a
/// [CollaborationCompletionException] carrying the parsed `error_code` +
/// `message` so the UI can branch (notably treating
/// `awaiting_partner_feedback` as a soft success).
///
/// The backend enforces a COMPLETION-CONFIRMATION GATE (PR 1, 2026-06-26):
/// `/complete` only succeeds once BOTH participant user types have POSTed
/// `/completion` with `status: 'yes'`. Call [submitCollaborationCompletion]
/// first. Rich `/feedback` is now optional and does not affect this gate.
///
/// Callers should `ref.invalidate(collaborationDetailProvider(id))` after
/// awaiting this to refresh the detail screen.
Future<Collaboration> markCollaborationCompleted(String id) async {
  final url = '${ApiConfig.baseUrl}/collaborations/$id/complete';
  debugPrint('[D3] POST $url');
  return _markCompleted(id, url, allowRetry: true);
}

Future<Collaboration> _markCompleted(
  String id,
  String url, {
  required bool allowRetry,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  debugPrint('[D3] response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    final raw = data is Map<String, dynamic>
        ? (data['collaboration'] as Map<String, dynamic>? ?? data)
        : json;
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.collaborationCompleted,
        properties: {'collaboration_id': id},
      ),
    );
    return Collaboration.fromJson(normalizeCollaborationResponse(raw));
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _markCompleted(id, url, allowRetry: false);
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to complete collaboration'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  // The completion endpoint signals gate/transition failures via `error_code`.
  // Surface it so the UI can branch (awaiting_partner_feedback = soft success).
  throw CollaborationCompletionException(
    errorCode: (body['error_code'] as String?)?.toLowerCase(),
    message: (body['message'] as String?) ?? 'Failed to complete collaboration',
    statusCode: response.statusCode,
    errors: body['errors'] is Map<String, dynamic>
        ? body['errors'] as Map<String, dynamic>
        : null,
  );
}

/// Update a collaboration's scheduled date and/or time (§4: either party can
/// edit the date or time).
///
/// `PATCH /api/v1/collaborations/{id}` — body carries the new `scheduled_date`
/// (ISO yyyy-MM-dd) and optional `scheduled_time` (free-text range string, e.g.
/// "14:00 - 18:00"). Returns the updated collaboration JSON.
///
/// TODO(backend): confirm the exact verb/path and field names. The companion
/// `kolabing-v2` API map does not yet document a collaboration-update route;
/// this is built to the most likely REST shape (PATCH on the resource). If the
/// backend ships a different contract (e.g. POST `/reschedule`), update the
/// `url`/method here only — callers and the UI need no change.
///
/// Callers should `ref.invalidate(collaborationDetailProvider(id))` afterwards.
Future<Collaboration> updateCollaborationSchedule(
  String id, {
  required DateTime scheduledDate,
  String? scheduledTime,
}) async {
  final url = '${ApiConfig.baseUrl}/collaborations/$id';
  final payload = <String, dynamic>{
    'scheduled_date': scheduledDate.toIso8601String().split('T').first,
    if (scheduledTime != null && scheduledTime.trim().isNotEmpty)
      'scheduled_time': scheduledTime.trim(),
  };
  debugPrint('[D3] PATCH $url payload=$payload');
  return _patchSchedule(id, url, payload, allowRetry: true);
}

Future<Collaboration> _patchSchedule(
  String id,
  String url,
  Map<String, dynamic> payload, {
  required bool allowRetry,
}) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final response = await http.patch(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(payload),
  );

  debugPrint('[D3] reschedule response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    final raw = data is Map<String, dynamic>
        ? (data['collaboration'] as Map<String, dynamic>? ?? data)
        : json;
    return Collaboration.fromJson(normalizeCollaborationResponse(raw));
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _patchSchedule(id, url, payload, allowRetry: false);
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to update collaboration'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Result of generating a check-in QR for a collaboration.
class CollaborationQr {
  const CollaborationQr({required this.eventId, this.qrCodeUrl});

  /// The event the QR belongs to. The backend creates the event on demand if
  /// the collaboration had none yet, so this is always populated on success.
  final String eventId;

  /// Optional pre-rendered QR image URL the backend may return.
  final String? qrCodeUrl;
}

/// Generate (or fetch) the check-in QR for a collaboration —
/// `POST /api/v1/collaborations/{id}/qr-code`.
///
/// This endpoint is idempotent: it CREATES the underlying event on demand if
/// the collaboration doesn't have one yet, generates the check-in token, and
/// returns `{ event_id, qr_code_url }`. The app calls it whenever the user taps
/// "View QR", so there is no "event must be created first" dead-end.
///
/// Callers should `ref.invalidate(collaborationDetailProvider(id))` afterwards
/// so the freshly created `event_id` is reflected on the detail screen.
Future<CollaborationQr> generateCollaborationQr(String id) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$id/qr-code';
  debugPrint('[D3] POST $url');

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  debugPrint('[D3] qr-code response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    // Tolerate both a flat body and a `data`-wrapped body.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final eventId = data['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) {
      throw const ApiException(
        error: ApiError(message: 'QR code response was missing an event id'),
      );
    }
    return CollaborationQr(
      eventId: eventId,
      qrCodeUrl: data['qr_code_url']?.toString(),
    );
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to generate QR code'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Provider for the system challenge catalogue (the pool a collaboration can
/// pick from). Fetches the real backend list — `GET /api/v1/challenges/system`.
final availableChallengesProvider = FutureProvider<List<Challenge>>((
  ref,
) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/challenges/system';
  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Challenge.fromJson)
        .toList();
  }
  throw const ApiException(
    error: ApiError(message: 'Failed to load challenges'),
  );
});

/// Persist the selected challenge ids for a collaboration —
/// `PUT /api/v1/collaborations/{id}/challenges` with `selected_challenge_ids`.
Future<void> saveCollaborationChallenges(
  String collaborationId,
  List<String> selectedChallengeIds,
) async {
  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final url = '${ApiConfig.baseUrl}/collaborations/$collaborationId/challenges';
  final response = await http.put(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'selected_challenge_ids': selectedChallengeIds}),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    final body = response.body.isEmpty
        ? <String, dynamic>{'message': 'Failed to save challenges'}
        : jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(
      error: ApiError.fromJson(body, statusCode: response.statusCode),
    );
  }
}

/// Notifier for selected challenge IDs within a collaboration.
class ChallengeSelectionNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setInitial(List<String> ids) {
    state = ids;
  }

  void toggle(String challengeId) {
    if (state.contains(challengeId)) {
      state = state.where((id) => id != challengeId).toList();
    } else {
      state = [...state, challengeId];
    }
  }
}

final challengeSelectionProvider =
    NotifierProvider<ChallengeSelectionNotifier, List<String>>(
      ChallengeSelectionNotifier.new,
    );

Map<String, dynamic> normalizeCollaborationResponse(Map<String, dynamic> raw) {
  final creator = raw['creator_profile'] is Map<String, dynamic>
      ? raw['creator_profile'] as Map<String, dynamic>
      : null;
  final applicant = raw['applicant_profile'] is Map<String, dynamic>
      ? raw['applicant_profile'] as Map<String, dynamic>
      : null;
  final opportunity = raw['kolab'] is Map<String, dynamic>
      ? raw['kolab'] as Map<String, dynamic>
      : raw['collab_opportunity'] is Map<String, dynamic>
      ? raw['collab_opportunity'] as Map<String, dynamic>
      : null;
  final businessProfile = raw['business_profile'] is Map<String, dynamic>
      ? raw['business_profile'] as Map<String, dynamic>
      : null;
  final communityProfile = raw['community_profile'] is Map<String, dynamic>
      ? raw['community_profile'] as Map<String, dynamic>
      : null;

  final businessSummary = creator?['user_type'] == 'business'
      ? creator
      : applicant?['user_type'] == 'business'
      ? applicant
      : null;
  final communitySummary = creator?['user_type'] == 'community'
      ? creator
      : applicant?['user_type'] == 'community'
      ? applicant
      : null;

  final scheduledDate =
      raw['scheduled_date']?.toString() ??
      opportunity?['availability_start']?.toString() ??
      DateTime.now().toIso8601String().split('T').first;

  return <String, dynamic>{
    'id': raw['id'],
    'status': raw['status'],
    'scheduled_date': scheduledDate,
    'scheduled_time':
        raw['scheduled_time']?.toString() ??
        opportunity?['selected_time']?.toString(),
    'business_partner': <String, dynamic>{
      'id': businessSummary?['id']?.toString() ?? '',
      'name':
          businessProfile?['name']?.toString() ??
          businessSummary?['display_name']?.toString() ??
          'Business Partner',
      'profile_photo':
          businessProfile?['profile_photo']?.toString() ??
          businessSummary?['avatar_url']?.toString(),
      'category':
          businessProfile?['type_label']?.toString() ??
          businessProfile?['business_type']?.toString(),
      'city': businessProfile?['city'] ?? businessSummary?['city'],
      'user_type': 'business',
    },
    'community_partner': <String, dynamic>{
      'id': communitySummary?['id']?.toString() ?? '',
      'name':
          communityProfile?['name']?.toString() ??
          communitySummary?['display_name']?.toString() ??
          'Community Partner',
      'profile_photo':
          communityProfile?['profile_photo']?.toString() ??
          communitySummary?['avatar_url']?.toString(),
      'category':
          communityProfile?['type_label']?.toString() ??
          communityProfile?['community_type']?.toString(),
      'city': communityProfile?['city'] ?? communitySummary?['city'],
      'user_type': 'community',
    },
    'opportunity': opportunity,
    'contact_methods': raw['contact_methods'] ?? const <String, dynamic>{},
    'business_offer':
        opportunity?['business_offer'] ?? const <String, dynamic>{},
    'community_deliverables':
        opportunity?['community_deliverables'] ?? const <String, dynamic>{},
    'event_id': raw['event_id'],
    'qr_code_url': raw['qr_code_url'],
    'challenges': raw['challenges'] ?? const <dynamic>[],
    'selected_challenge_ids':
        raw['selected_challenge_ids'] ?? const <dynamic>[],
    'created_at': raw['created_at'],
    'updated_at': raw['updated_at'],
    'completed_at': raw['completed_at'],
    'my_role': raw['my_role'],
    'has_reviewed': raw['has_reviewed'],
    'viewer_must_resubscribe': raw['viewer_must_resubscribe'],
    // Two-sided feedback gate (Collaboration.fromJson reads these). Pass through
    // verbatim; the model tolerates missing/null values with safe defaults.
    if (raw.containsKey('viewer_must_submit_feedback'))
      'viewer_must_submit_feedback': raw['viewer_must_submit_feedback'],
    'own_feedback': raw['own_feedback'],
    'partner_feedback': raw['partner_feedback'],
    'pending_feedback_from': raw['pending_feedback_from'],
    // Lightweight completion confirmation (PR 1, 2026-06-26) — this, not
    // feedback above, gates /complete. Pass through verbatim.
    if (raw.containsKey('viewer_must_confirm_completion'))
      'viewer_must_confirm_completion': raw['viewer_must_confirm_completion'],
    'own_completion': raw['own_completion'],
    'partner_completion_status': raw['partner_completion_status'],
    'pending_completion_from': raw['pending_completion_from'],
  };
}
