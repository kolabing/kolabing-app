import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/collaboration.dart';

/// A lightweight collaboration item parsed from the LIST endpoint
/// (`GET /api/v1/collaborations`).
///
/// IMPORTANT: the list resource (`CollaborationResource` in `kolabing-v2`) has a
/// DIFFERENT shape than the detail resource. The list returns
/// `creator_profile` / `applicant_profile` (`ProfileSummaryResource`: `id`,
/// `user_type`, `display_name`, `avatar_url`, `community_type`, ...) and the
/// status enum values `scheduled|active|completed|cancelled`. It does NOT
/// return the `business_partner` / `community_partner` keys that the full
/// [Collaboration.fromJson] requires, so we parse a slim model here for the
/// "My Kolabs" list. Tapping a card opens `/collaboration/:id`, which fetches
/// the full [Collaboration] via `collaborationDetailProvider`.
@immutable
class CollaborationListItem {
  const CollaborationListItem({
    required this.id,
    required this.status,
    this.scheduledDate,
    required this.partnerName,
    this.partnerAvatarUrl,
    this.opportunityTitle,
  });

  /// Build from a single list-resource entry. Resolves the "partner" as the
  /// profile whose `user_type` differs from the viewer's [myUserType] (the
  /// other side of the match). Falls back to the applicant, then creator, when
  /// the viewer's type is unknown.
  factory CollaborationListItem.fromJson(
    Map<String, dynamic> json, {
    String? myUserType,
  }) {
    final creator = json['creator_profile'] as Map<String, dynamic>?;
    final applicant = json['applicant_profile'] as Map<String, dynamic>?;

    Map<String, dynamic>? partner;
    if (myUserType != null) {
      // The partner is the profile that is NOT the same user_type as the viewer.
      if (creator != null && creator['user_type'] != myUserType) {
        partner = creator;
      } else if (applicant != null && applicant['user_type'] != myUserType) {
        partner = applicant;
      }
    }
    // Fallbacks: prefer applicant, then creator.
    partner ??= applicant ?? creator;

    final opportunity = json['collab_opportunity'] as Map<String, dynamic>?;

    return CollaborationListItem(
      id: json['id'] as String,
      status: CollaborationStatus.fromString(json['status'] as String? ?? ''),
      scheduledDate: _parseDate(json['scheduled_date']),
      partnerName: (partner?['display_name'] as String?) ?? 'Partner',
      partnerAvatarUrl: partner?['avatar_url'] as String?,
      opportunityTitle: opportunity?['title'] as String?,
    );
  }

  final String id;
  final CollaborationStatus status;
  final DateTime? scheduledDate;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String? opportunityTitle;

  String get partnerInitial =>
      partnerName.isNotEmpty ? partnerName.substring(0, 1).toUpperCase() : '?';

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Which bucket of collaborations to fetch for the "My Kolabs" screen.
///
/// - [active]: collaborations the user is still running (`scheduled` or
///   `active`/in-progress), accepted by both sides and not yet closed.
/// - [finished]: completed collaborations ONLY (cancelled is excluded).
enum CollaborationsFilter { active, finished }

/// Fetches the current user's collaborations from `GET /api/v1/collaborations`.
///
/// The backend (`CollaborationService::getForProfile`) returns collaborations
/// where the profile is EITHER the creator OR the applicant, so this is the
/// user's both-sided list. We request server-side status filtering and also
/// filter client-side for safety.
///
/// Response shape (note the double-nested `data`):
/// ```json
/// {
///   "success": true,
///   "data": { "data": [ { "id", "status", "scheduled_date",
///     "creator_profile": {...}, "applicant_profile": {...},
///     "collab_opportunity": {...} } ] },
///   "meta": { "current_page", "last_page", "per_page", "total" }
/// }
/// ```
final collaborationsListProvider =
    FutureProvider.family<List<CollaborationListItem>, CollaborationsFilter>((
      ref,
      filter,
    ) async {
      return _fetchCollaborations(filter, allowRetry: true);
    });

Future<List<CollaborationListItem>> _fetchCollaborations(
  CollaborationsFilter filter, {
  required bool allowRetry,
}) async {
  // The list endpoint accepts a single `status` query param. "Active" spans two
  // statuses (scheduled + active), so we fetch without a server status filter
  // there and bucket client-side; "Finished" can use the server filter.
  final query = filter == CollaborationsFilter.finished
      ? '?status=completed&per_page=100'
      : '?per_page=100';
  final url = '${ApiConfig.baseUrl}/collaborations$query';
  debugPrint('[Collaborations] GET $url');

  final authService = AuthService();
  final token = await authService.getToken();
  if (token == null || token.isEmpty) {
    throw const AuthException('Session expired. Please sign in again.');
  }

  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );

  debugPrint('[Collaborations] response status=${response.statusCode}');

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final myUserType = (await authService.getStoredUser())?.userType
        .toApiValue();
    final items = _extractItems(json, myUserType);
    return _applyFilter(items, filter);
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _fetchCollaborations(filter, allowRetry: false);
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to load collaborations'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
  );
}

/// Pull the collaboration list out of the nested envelope. The controller wraps
/// the `CollaborationCollection` (itself `{ "data": [...] }`) in `data`, giving
/// `data.data`. Tolerate both single- and double-nested shapes.
List<CollaborationListItem> _extractItems(
  Map<String, dynamic> json,
  String? myUserType,
) {
  final data = json['data'];
  List<dynamic>? rawList;
  if (data is List) {
    rawList = data;
  } else if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is List) {
      rawList = inner;
    }
  }
  rawList ??= const [];

  return rawList
      .whereType<Map<String, dynamic>>()
      .map((e) => CollaborationListItem.fromJson(e, myUserType: myUserType))
      .toList();
}

/// Bucket items into the requested filter. Active = scheduled or in-progress
/// (not closed); Finished = completed ONLY (cancelled excluded).
List<CollaborationListItem> _applyFilter(
  List<CollaborationListItem> items,
  CollaborationsFilter filter,
) {
  switch (filter) {
    case CollaborationsFilter.active:
      return items
          .where(
            (i) =>
                i.status == CollaborationStatus.scheduled ||
                i.status == CollaborationStatus.inProgress,
          )
          .toList();
    case CollaborationsFilter.finished:
      return items
          .where((i) => i.status == CollaborationStatus.completed)
          .toList();
  }
}
