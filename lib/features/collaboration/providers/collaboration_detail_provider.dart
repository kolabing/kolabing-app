import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/collaboration.dart';

/// Provider for collaboration detail.
final collaborationDetailProvider =
    FutureProvider.family<Collaboration?, String>((ref, id) async {
      try {
        return await fetchCollaborationDetail(id);
      } on Exception catch (e) {
        debugPrint('CollaborationDetailProvider: remote fetch failed: $e');
        return _mockCollaboration(id);
      }
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
    return Collaboration.fromJson(_normalizeCollaborationResponse(raw));
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

/// Mark a collaboration as completed (D3).
///
/// `POST /api/v1/collaborations/{id}/complete` — empty body, returns the
/// updated collaboration JSON. Backend enforces the `scheduled|active →
/// completed` transition; repeat completion returns `422 invalid_status_transition`.
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
    return Collaboration.fromJson(_normalizeCollaborationResponse(raw));
  }

  if (response.statusCode == 401 && allowRetry) {
    await authService.refreshSession();
    return _markCompleted(id, url, allowRetry: false);
  }

  final body = response.body.isEmpty
      ? <String, dynamic>{'message': 'Failed to complete collaboration'}
      : jsonDecode(response.body) as Map<String, dynamic>;
  throw ApiException(
    error: ApiError.fromJson(body, statusCode: response.statusCode),
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
    return Collaboration.fromJson(_normalizeCollaborationResponse(raw));
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

/// Provider for available challenges (system + custom)
final availableChallengesProvider =
    FutureProvider.family<List<Challenge>, String>((
      ref,
      collaborationId,
    ) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return _mockChallenges;
    });

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

Map<String, dynamic> _normalizeCollaborationResponse(Map<String, dynamic> raw) {
  final creator = raw['creator_profile'] as Map<String, dynamic>?;
  final applicant = raw['applicant_profile'] as Map<String, dynamic>?;
  final opportunity = raw['collab_opportunity'] as Map<String, dynamic>?;
  final businessProfile = raw['business_profile'] as Map<String, dynamic>?;
  final communityProfile = raw['community_profile'] as Map<String, dynamic>?;

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
  };
}

// =============================================================================
// Mock Data
// =============================================================================

Collaboration? _mockCollaboration(String id) {
  final now = DateTime.now();
  return Collaboration(
    id: id,
    status: CollaborationStatus.scheduled,
    scheduledDate: now.add(const Duration(days: 12)),
    scheduledTime: '14:00 - 18:00',
    businessPartner: const CollaborationPartner(
      id: 'biz-001',
      name: 'Nomad Coffee Roasters',
      profilePhoto: null,
      category: 'Food & Drink',
      city: 'Barcelona',
      userType: 'business',
    ),
    communityPartner: const CollaborationPartner(
      id: 'com-001',
      name: 'Barcelona Runners Club',
      profilePhoto: null,
      category: 'Sports & Fitness',
      city: 'Barcelona',
      userType: 'community',
    ),
    opportunity: null,
    contactMethods: const ContactMethods(
      whatsapp: '+34612345678',
      email: 'contact@nomadcoffee.com',
      instagram: '@nomadcoffee',
    ),
    businessOffer: const BusinessOffer(
      venue: true,
      foodDrink: true,
      socialMediaExposure: true,
      contentCreation: false,
      discount: DiscountOffer(enabled: true, percentage: 15),
      products: ['Specialty Coffee Tasting Kit'],
      other: 'Exclusive use of our rooftop terrace',
    ),
    communityDeliverables: const CommunityDeliverables(
      socialMediaContent: true,
      eventActivation: true,
      productPlacement: false,
      communityReach: true,
      reviewFeedback: false,
      other: 'Post-run group photo with branding',
    ),
    eventId: 'evt-001',
    qrCodeUrl: null,
    challenges: _mockChallenges,
    selectedChallengeIds: ['ch-001', 'ch-003'],
    createdAt: now.subtract(const Duration(days: 3)),
  );
}

final List<Challenge> _mockChallenges = [
  Challenge(
    id: 'ch-001',
    name: 'Check-in at Venue',
    description: 'Scan the QR code when you arrive at the event',
    difficulty: ChallengeDifficulty.easy,
    points: 5,
    isSystem: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-002',
    name: 'Share on Instagram',
    description: 'Post a story or photo from the event and tag us',
    difficulty: ChallengeDifficulty.medium,
    points: 15,
    isSystem: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-003',
    name: 'Try 3 Different Brews',
    description: 'Taste at least 3 different coffee brews during the event',
    difficulty: ChallengeDifficulty.medium,
    points: 20,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-004',
    name: 'Group Photo Challenge',
    description: 'Take a group photo with at least 5 attendees',
    difficulty: ChallengeDifficulty.easy,
    points: 10,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'ch-005',
    name: 'Complete 5K Run',
    description: 'Finish the full 5K running route before the coffee tasting',
    difficulty: ChallengeDifficulty.hard,
    points: 30,
    isSystem: false,
    eventId: 'evt-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
