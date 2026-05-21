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
/// Community profiles: `GET /api/v1/communities/{id}/public-profile`
/// (live as of 2026-05-21 contract update).
///
/// Business profile endpoint is still TBD; for businesses we fall back to
/// mock data until the equivalent endpoint ships.
class PublicProfileService {
  PublicProfileService({
    GalleryService? galleryService,
    AuthService? authService,
    http.Client? httpClient,
  })  : _galleryService = galleryService ?? GalleryService(),
        _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final GalleryService _galleryService;
  final AuthService _authService;
  final http.Client _httpClient;

  /// Fetch a public profile by ID.
  ///
  /// Tries the live community endpoint first. Falls back to mock data if the
  /// endpoint is not available for this profile type (e.g. business viewers).
  /// Gallery photos always come from the real API.
  Future<PublicProfile> getPublicProfile(String profileId) async {
    PublicProfile? remote;
    try {
      remote = await _fetchCommunityPublicProfile(profileId);
    } on Exception catch (e) {
      debugPrint('PublicProfileService: remote profile fetch failed: $e');
    }

    // Fetch gallery photos from real API
    List<GalleryPhoto> gallery = [];
    try {
      gallery = await _galleryService.getProfileGallery(profileId);
    } catch (e) {
      debugPrint('PublicProfileService: gallery fetch failed: $e');
    }

    final base = remote ?? _getMockProfile(profileId);
    return base.copyWith(gallery: gallery);
  }

  Future<PublicProfile?> _fetchCommunityPublicProfile(String id) async {
    return _fetchCommunityPublicProfileInner(id, allowRetry: true);
  }

  Future<PublicProfile?> _fetchCommunityPublicProfileInner(
    String id, {
    required bool allowRetry,
  }) async {
    final url = '${ApiConfig.baseUrl}/communities/$id/public-profile';
    final token = await _authService.getToken();
    debugPrint('[C9] GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    debugPrint('[C9] response status=${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final raw = data is Map<String, dynamic> ? data : json;
      return PublicProfile.fromJson(raw);
    }

    if (response.statusCode == 401 && allowRetry) {
      await _authService.refreshSession();
      return _fetchCommunityPublicProfileInner(id, allowRetry: false);
    }

    if (response.statusCode == 404) {
      // Likely a business profile id — endpoint is community-only for now.
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
  // Mock Data
  // ---------------------------------------------------------------------------

  PublicProfile _getMockProfile(String profileId) {
    // Return mock data with the given profile ID
    // This will be replaced by: GET /api/v1/profiles/{profileId}
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
    // This will be replaced by: GET /api/v1/profiles/{id}/collaborations
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
