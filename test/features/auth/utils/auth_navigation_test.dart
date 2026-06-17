import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/utils/auth_navigation.dart';

void main() {
  const attendee = UserModel(
    id: 'a-1',
    email: 'a@example.com',
    userType: UserType.attendee,
  );
  const business = UserModel(
    id: 'b-1',
    email: 'b@example.com',
    userType: UserType.business,
  );

  // SHIP GATE (FeatureFlags.attendeeEnabled == false): the attendee/member
  // layer is not shipped, so resolveAuthDestination must NEVER route an
  // attendee into the attendee shell. New and existing attendees alike are sent
  // to login (the GoRouter redirect then signs them out). When the flag is
  // flipped back to true these expectations would change to the onboarding /
  // dashboard routes below.
  test('attendee is bounced to login while the member layer is gated (new)', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: true),
      KolabingRoutes.login,
    );
  });

  test(
    'attendee is bounced to login while the member layer is gated (existing)',
    () {
      expect(
        resolveAuthDestination(attendee, isNewUser: false),
        KolabingRoutes.login,
      );
    },
  );

  test('new business still routes to business onboarding (regression)', () {
    expect(
      resolveAuthDestination(business, isNewUser: true),
      KolabingRoutes.businessOnboardingStep5,
    );
  });
}
