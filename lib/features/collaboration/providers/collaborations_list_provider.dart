import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/collaboration.dart';
import 'collaboration_detail_provider.dart';

/// Fetches the authenticated viewer's collaborations.
///
/// `GET /api/v1/collaborations` returns every collaboration the viewer is part
/// of (as creator or applicant), newest first, under Laravel's nested
/// `data.data[]` shape. Each item carries the same raw fields the detail
/// endpoint returns, so we reuse [normalizeCollaborationResponse] to map them
/// onto the [Collaboration] model.
///
/// We deliberately fetch unfiltered and partition by status on the client:
/// the backend's `?status=` filter only accepts a single value (comma lists are
/// ignored and return everything), and the My Kolabs hub needs two buckets that
/// each span multiple statuses (Active = scheduled/active; Finished =
/// completed/cancelled).
Future<List<Collaboration>> _fetchCollaborations({
  required bool allowRetry,
  required AuthService authService,
  int perPage = 100,
}) async {
  String? token = await authService.getToken();
  if (token == null || token.isEmpty) {
    // Token missing — attempt a silent refresh before giving up. This handles
    // the case where secure-storage hasn't been read yet on first mount.
    try {
      token = await authService.refreshSession();
    } on Exception {
      throw const AuthException('Session expired. Please sign in again.');
    }
  }

  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/collaborations',
  ).replace(queryParameters: {'per_page': perPage.toString()});
  debugPrint('[collabs] GET $uri');

  final response = await http.get(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );

  debugPrint('[collabs] status=${response.statusCode}');

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    final list = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? const [])
        : data is List<dynamic>
        ? data
        : const <dynamic>[];

    final collaborations = <Collaboration>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        collaborations.add(
          Collaboration.fromJson(normalizeCollaborationResponse(item)),
        );
      } catch (e) {
        debugPrint('[collabs] skip unparseable item: $e');
      }
    }
    return collaborations;
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _fetchCollaborations(allowRetry: false, authService: authService, perPage: perPage);
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to load kolabs'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// All of the viewer's collaborations (both roles), unfiltered.
///
/// The My Kolabs hub invalidates this on mount (see [MyKolabsHubScreen]) so a
/// stale session-cached snapshot is never shown — e.g. an empty Active tab
/// after new collaborations were formed. Pull-to-refresh also forces a refetch.
final collaborationsListProvider = FutureProvider<List<Collaboration>>(
  (ref) => _fetchCollaborations(
    allowRetry: true,
    authService: ref.read(authServiceProvider),
  ),
);

/// Active = ongoing work: a collaboration exists and has not yet ended.
/// Per the lifecycle: accepted from both sides → scheduled/active.
final activeCollaborationsProvider = Provider<AsyncValue<List<Collaboration>>>((
  ref,
) {
  return ref.watch(collaborationsListProvider).whenData(
    (all) => all
        .where(
          (c) =>
              c.status == CollaborationStatus.scheduled ||
              c.status == CollaborationStatus.inProgress ||
              c.status == CollaborationStatus.pendingConfirmation,
        )
        .toList(),
  );
});

/// Finished = completed or cancelled collaborations.
final finishedCollaborationsProvider =
    Provider<AsyncValue<List<Collaboration>>>((ref) {
      return ref.watch(collaborationsListProvider).whenData(
        (all) => all
            .where(
              (c) =>
                  c.status == CollaborationStatus.completed ||
                  c.status == CollaborationStatus.cancelled,
            )
            .toList(),
      );
    });
