import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/public_profile.dart';
import '../providers/gallery_provider.dart';
import 'gallery_service.dart';

/// Service for fetching public profile data.
///
/// Canonical endpoints (backend `kolabing-v2`, confirmed 2026-05-22):
/// - Profile:        `GET /api/v1/profiles/{profileId}` -> `PublicProfileResource`
///   Returns the logo as an ABSOLUTE URL under `avatar_url` / `logo_url` /
///   `profile_photo`, plus a server-formatted `type_label` (e.g. "Run Club").
///   The `{profileId}` path segment is a `profiles.id` (NOT a business/community
///   profile id).
/// - Collaborations: `GET /api/v1/profiles/{profileId}/collaborations`
///   -> paginated `PublicCollaborationResource` (`title`, `partner_name`,
///   `partner_avatar_url`, `completed_at`, `status`). The backend eager-loads
///   the event and only returns completed collaborations.
///
/// Both endpoints work for business AND community profiles, so there is no
/// longer a per-type branch. Gallery photos still come from the gallery API.
class PublicProfileService {
  PublicProfileService({
    GalleryService? galleryService,
    AuthService? authService,
    http.Client? httpClient,
  }) : _galleryService = galleryService ?? GalleryService(),
       _authService = authService ?? AuthService(),
       _httpClient = httpClient ?? http.Client();

  final GalleryService _galleryService;
  final AuthService _authService;
  final http.Client _httpClient;

  /// Fetch a public profile by ID.
  ///
  /// Loads the profile, its completed collaborations, and its gallery in
  /// parallel-ish (sequential awaits, each failure isolated) and merges them.
  /// Falls back to mock profile data only if the profile endpoint itself
  /// fails, so the screen still renders something during development.
  Future<PublicProfile> getPublicProfile(String profileId) async {
    PublicProfile? remote;
    try {
      remote = await _fetchPublicProfile(profileId);
    } on Exception catch (e) {
      debugPrint('PublicProfileService: remote profile fetch failed: $e');
    }

    // Past collaborations live on a dedicated endpoint, not embedded in the
    // profile resource. Fetch them separately; an empty list is a valid
    // (and common) result that the UI renders as an empty state.
    var pastCollaborations = const <PastCollaboration>[];
    try {
      pastCollaborations = await _fetchPastCollaborations(profileId);
    } on Exception catch (e) {
      debugPrint('PublicProfileService: collaborations fetch failed: $e');
    }

    // Fetch gallery photos from real API
    var gallery = const <GalleryPhoto>[];
    try {
      gallery = await _galleryService.getProfileGallery(profileId);
    } catch (e) {
      debugPrint('PublicProfileService: gallery fetch failed: $e');
    }

    final base = remote ?? _getMockProfile(profileId);
    return base.copyWith(
      gallery: gallery,
      // Prefer the live collaborations. Only keep the (mock) fallback list when
      // the profile itself fell back to mock AND the live fetch returned empty.
      pastCollaborations: pastCollaborations.isNotEmpty
          ? pastCollaborations
          : (remote == null ? base.pastCollaborations : const []),
    );
  }

  // ---------------------------------------------------------------------------
  // GET /profiles/{id}
  // ---------------------------------------------------------------------------

  Future<PublicProfile?> _fetchPublicProfile(String id) {
    return _fetchPublicProfileInner(id, allowRetry: true);
  }

  Future<PublicProfile?> _fetchPublicProfileInner(
    String id, {
    required bool allowRetry,
  }) async {
    final url = '${ApiConfig.baseUrl}/profiles/$id';
    final token = await _authService.getToken();
    debugPrint('PublicProfileService: GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint('PublicProfileService: profile status=${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final raw = data is Map<String, dynamic> ? data : json;
      return PublicProfile.fromJson(raw);
    }

    if (response.statusCode == 401 && allowRetry) {
      await _authService.refreshSession();
      return _fetchPublicProfileInner(id, allowRetry: false);
    }

    if (response.statusCode == 404) {
      // Profile not found (e.g. a stale or wrong id). Surface as null so the
      // caller can fall back rather than throwing a hard error.
      return null;
    }

    final body = response.body.isEmpty
        ? <String, dynamic>{'message': 'Failed to load profile'}
        : jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(
      error: ApiError.fromJson(body, statusCode: response.statusCode),
    );
  }

  // ---------------------------------------------------------------------------
  // GET /profiles/{id}/collaborations
  // ---------------------------------------------------------------------------

  Future<List<PastCollaboration>> _fetchPastCollaborations(String id) {
    return _fetchPastCollaborationsInner(id, allowRetry: true);
  }

  Future<List<PastCollaboration>> _fetchPastCollaborationsInner(
    String id, {
    required bool allowRetry,
  }) async {
    final url = '${ApiConfig.baseUrl}/profiles/$id/collaborations';
    final token = await _authService.getToken();
    debugPrint('PublicProfileService: GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint(
      'PublicProfileService: collaborations status=${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // The endpoint is paginated: `data` is the list of completed
      // collaborations (each a PublicCollaborationResource), with `meta` for
      // paging. We only render the first page on the profile screen.
      final data = json['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PastCollaboration.fromJson)
            .toList();
      }
      return const [];
    }

    if (response.statusCode == 401 && allowRetry) {
      await _authService.refreshSession();
      return _fetchPastCollaborationsInner(id, allowRetry: false);
    }

    if (response.statusCode == 404) {
      return const [];
    }

    final body = response.body.isEmpty
        ? <String, dynamic>{'message': 'Failed to load collaborations'}
        : jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(
      error: ApiError.fromJson(body, statusCode: response.statusCode),
    );
  }

  // ---------------------------------------------------------------------------
  // Mock Data (fallback only when the profile endpoint is unreachable)
  // ---------------------------------------------------------------------------

  PublicProfile _getMockProfile(String profileId) {
    return PublicProfile(
      id: profileId,
      userType: 'community',
      displayName: 'Kolabing Community',
      about:
          'We organize tech events, meetups, and workshops to bring people together. Our community focuses on creating meaningful connections between businesses and local groups.',
      type: 'Technology',
      cityName: 'Istanbul',
      instagram: 'kolabing',
      tiktok: 'kolabing',
      website: 'https://kolabing.com',
      pastCollaborations: _getMockCollaborations(),
    );
  }

  List<PastCollaboration> _getMockCollaborations() {
    return [
      PastCollaboration(
        id: 'collab_1',
        title: 'Tech Meetup v4',
        partnerName: 'CafeX',
        completedAt: DateTime(2025, 1, 15),
      ),
      PastCollaboration(
        id: 'collab_2',
        title: 'Summer Networking Event',
        partnerName: 'CoWork Hub',
        completedAt: DateTime(2024, 8, 22),
      ),
      PastCollaboration(
        id: 'collab_3',
        title: 'Startup Weekend',
        partnerName: 'Innovation Lab',
        completedAt: DateTime(2024, 6, 10),
      ),
    ];
  }
}
