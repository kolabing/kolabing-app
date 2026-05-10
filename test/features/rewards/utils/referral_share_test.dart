import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/rewards/utils/referral_share.dart';

void main() {
  test('buildReferralCodeShareMessage shares the referral code without link', () {
    expect(
      buildReferralCodeShareMessage('KOLAB-IRSC'),
      'Register your business on Kolabing and use my referral code KOLAB-IRSC during signup.',
    );
  });
}
