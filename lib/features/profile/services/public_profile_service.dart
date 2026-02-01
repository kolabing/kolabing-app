import 'package:flutter/foundation.dart';

import '../models/public_profile.dart';
import '../providers/gallery_provider.dart';
import 'gallery_service.dart';

/// Service for fetching public profile data.
///
/// Currently uses mock data for profile info and past collaborations.
/// Gallery photos are fetched from the real API.
///
/// TODO: Replace mock data with real API when available:
/// - GET /api/v1/profiles/{id} — Public profile data
/// - GET /api/v1/profiles/{id}/collaborations — Past collaborations
class PublicProfileService {
  PublicProfileService({
    GalleryService? galleryService,
  }) : _galleryService = galleryService ?? GalleryService();

  final GalleryService _galleryService;

  /// Fetch a public profile by ID.
  ///
  /// Combines mock profile data with real gallery photos from the API.
  Future<PublicProfile> getPublicProfile(String profileId) async {
    // Fetch gallery photos from real API
    List<GalleryPhoto> gallery = [];
    try {
      gallery = await _galleryService.getProfileGallery(profileId);
    } catch (e) {
      debugPrint('PublicProfileService: gallery fetch failed: $e');
    }

    // Mock profile data — will be replaced with API call
    final mockProfile = _getMockProfile(profileId);

    return mockProfile.copyWith(gallery: gallery);
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
