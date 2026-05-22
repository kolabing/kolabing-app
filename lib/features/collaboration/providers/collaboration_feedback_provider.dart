import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/collaboration.dart';
import '../models/collaboration_feedback.dart';

/// Thrown when the backend feedback endpoint hasn't shipped yet (404). The UI
/// treats this as a soft warning rather than a hard error so the user isn't
/// blocked from completing their collaboration.
class FeedbackEndpointMissingException implements Exception {
  const FeedbackEndpointMissingException();

  @override
  String toString() => 'FeedbackEndpointMissingException';
}

/// Submit a post-completion feedback survey for a collaboration.
///
/// `POST /api/v1/collaborations/{id}/feedback`
/// — see `kolabing-v2/.agent/todo/BE-XXX-collaboration-feedback-endpoint.md`.
Future<void> submitCollaborationFeedback(
  String collaborationId,
  CollaborationFeedbackDraft draft,
) async {
  final url = '${ApiConfig.baseUrl}/collaborations/$collaborationId/feedback';
  final payload = draft.toPayload();
  debugPrint('[FB] POST $url payload=$payload');
  await _post(url, payload, allowRetry: true);
}

/// Finish a collaboration AND submit the caller's feedback in one call.
///
/// `POST /api/v1/collaborations/{id}/finish` — body is the feedback payload
/// (REQUIRED, see `docs/ROLES-AND-PERMISSIONS.md` §4). The response is the
/// updated collaboration including the feedback/reviews array; we parse it back
/// into a [Collaboration] so the caller can refresh without a second fetch.
///
/// Feedback is mandatory: the UI must not call this until [draft.canSubmit] is
/// true. We assert here as a defensive backstop.
///
/// Callers should `ref.invalidate(collaborationDetailProvider(id))` after
/// awaiting this to refresh the detail screen.
Future<Collaboration> finishCollaborationWithFeedback(
  String collaborationId,
  CollaborationFeedbackDraft draft,
) async {
  assert(
    draft.canSubmit,
    'finishCollaborationWithFeedback called before feedback was complete',
  );
  final url = '${ApiConfig.baseUrl}/collaborations/$collaborationId/finish';
  final payload = draft.toPayload();
  debugPrint('[FB] POST $url payload=$payload');
  final json = await _postReturningJson(url, payload, allowRetry: true);
  // Unwrap the common `{ data: { collaboration: {...} } }` / `{ data: {...} }`
  // envelopes; fall back to the raw body.
  final data = json['data'];
  final raw = data is Map<String, dynamic>
      ? (data['collaboration'] as Map<String, dynamic>? ?? data)
      : json;
  return Collaboration.fromJson(raw);
}

Future<void> _post(
  String url,
  Map<String, dynamic> payload, {
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
    body: jsonEncode(payload),
  );

  debugPrint('[FB] response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    return;
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _post(url, payload, allowRetry: false);
  }

  if (response.statusCode == 404) {
    throw const FeedbackEndpointMissingException();
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to submit feedback'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Same transport as [_post] but returns the decoded JSON body. Used by the
/// finish endpoint, which returns the updated collaboration.
Future<Map<String, dynamic>> _postReturningJson(
  String url,
  Map<String, dynamic> payload, {
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
    body: jsonEncode(payload),
  );

  debugPrint('[FB] response status=${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _postReturningJson(url, payload, allowRetry: false);
  }

  if (response.statusCode == 404) {
    throw const FeedbackEndpointMissingException();
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to finish Kolab'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}
