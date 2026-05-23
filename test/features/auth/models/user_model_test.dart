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
}
