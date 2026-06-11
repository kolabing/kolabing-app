import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/constants/feature_flags.dart';

void main() {
  test(
    'attendee Apple signup is enabled (App Store 4.8 requires Sign in with '
    'Apple alongside Google; backend /auth/apple user_type via kolabing-v2 #24)',
    () {
      expect(FeatureFlags.attendeeAppleSignupEnabled, isTrue);
    },
  );
}
