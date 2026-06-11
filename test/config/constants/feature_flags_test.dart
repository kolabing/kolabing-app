import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/constants/feature_flags.dart';

void main() {
  test('attendee Apple signup is off by default (pending backend user_type)', () {
    expect(FeatureFlags.attendeeAppleSignupEnabled, isFalse);
  });
}
