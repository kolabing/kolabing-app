import '../../../config/routes/routes.dart';
import '../models/user_model.dart';

/// Resolves the next in-app route after authentication or session restore.
String resolveAuthDestination(UserModel user, {bool isNewUser = false}) {
  if (user.isAttendee) {
    return KolabingRoutes.attendeeDashboard;
  }

  // Onboarding is mandatory at registration. Existing accounts always have it
  // completed — the only signal that the user must run onboarding is the
  // `is_new_user` flag returned by OAuth (Google/Apple) when they create a
  // brand-new account.
  if (isNewUser) {
    return user.isBusiness
        ? KolabingRoutes.businessOnboardingStep5
        : KolabingRoutes.communityOnboardingStep1;
  }

  return user.isBusiness
      ? KolabingRoutes.businessDashboard
      : KolabingRoutes.communityDashboard;
}
