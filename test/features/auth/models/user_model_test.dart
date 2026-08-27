import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';

void main() {
  test('businessTypesSummary humanizes underscored type labels', () {
    const profile = BusinessProfile(
      id: 'bp-1',
      name: 'Run House',
      businessTypes: ['run_club', 'food_brand'],
    );

    expect(profile.businessTypesSummary, 'Run Club · Food Brand');
  });

  test('communityTypeLabel humanizes underscored type labels', () {
    const profile = CommunityProfile(
      id: 'cp-1',
      name: 'Morning Crew',
      communityType: 'run_club',
    );

    expect(profile.communityTypeLabel, 'Run Club');
  });

  // #176: `fromJson` read cover_photo and `toJson` did not write it, so a
  // community round-tripped through the cached copy came back with no cover —
  // silently, because every other field survived.
  test(
    'CommunityProfile survives a fromJson/toJson round trip with its cover',
    () {
      final original = CommunityProfile.fromJson({
        'id': 'cp-1',
        'name': 'Morning Crew',
        'community_type': 'run_club',
        'profile_photo': 'https://example.test/logo.jpg',
        'cover_photo': 'https://example.test/cover.jpg',
        'community_size': 40,
      });

      expect(original.coverPhoto, 'https://example.test/cover.jpg');

      final round = CommunityProfile.fromJson(original.toJson());

      expect(round.coverPhoto, original.coverPhoto);
      expect(round.profilePhoto, original.profilePhoto);
      expect(round.communitySize, original.communitySize);
    },
  );
}
