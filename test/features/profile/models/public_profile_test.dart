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
}
