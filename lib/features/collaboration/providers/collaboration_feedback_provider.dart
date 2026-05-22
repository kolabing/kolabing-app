import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
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
