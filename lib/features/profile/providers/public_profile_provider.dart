import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_profile.dart';
import '../services/public_profile_service.dart';

/// Provider for fetching public profile data by profile ID.
///
/// Usage:
/// ```dart
/// final profileAsync = ref.watch(publicProfileProvider(profileId));
/// ```
final publicProfileProvider =
    FutureProvider.family<PublicProfile, String>((ref, profileId) {
  final service = PublicProfileService();
  return service.getPublicProfile(profileId);
});
