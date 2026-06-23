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

  test('new attendee routes into onboarding step 1', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: true),
      KolabingRoutes.attendeeOnboardingStep1,
    );
  });

  test('existing attendee routes to the attendee dashboard', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: false),
      KolabingRoutes.attendeeDashboard,
    );
  });

  test('new business still routes to business onboarding (regression)', () {
    expect(
      resolveAuthDestination(business, isNewUser: true),
      KolabingRoutes.businessOnboardingStep5,
    );
  });
}
