import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/profile/models/public_profile.dart';

void main() {
  test('typeLabel humanizes underscored profile type labels', () {
    const profile = PublicProfile(
      id: 'profile-1',
      userType: 'community',
      displayName: 'Morning Crew',
      type: 'run_club',
    );

    expect(profile.typeLabel, 'Run Club');
  });

  test('fromJson parses reputation summary when present', () {
    final profile = PublicProfile.fromJson({
      'id': 'profile-1',
      'user_type': 'community',
      'display_name': 'Morning Crew',
      'reputation': {
        'average_rating': 4.8,
        'review_count': 12,
        'unique_partner_count': 9,
        'breakdown': {
          'communication': 4.9,
          'reliability': 4.7,
          'fit': 4.8,
          'value': 4.6,
          'repeat': 4.5,
        },
      },
    });

    expect(profile.reputation, isNotNull);
    expect(profile.reputation!.averageRating, 4.8);
    expect(profile.reputation!.reviewCount, 12);
    expect(profile.reputation!.uniquePartnerCount, 9);
    expect(profile.reputation!.breakdown, isNotNull);
    expect(profile.reputation!.breakdown!.communication, 4.9);
  });

  test('fromJson leaves reputation null when key is absent', () {
    final profile = PublicProfile.fromJson({
      'id': 'profile-1',
      'user_type': 'community',
      'display_name': 'Morning Crew',
    });

    expect(profile.reputation, isNull);
  });
}
