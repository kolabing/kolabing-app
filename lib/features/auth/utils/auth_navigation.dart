import '../../../config/routes/routes.dart';
import '../models/user_model.dart';

/// Resolves the next in-app route after authentication or session restore.
String resolveAuthDestination(UserModel user, {bool isNewUser = false}) {
  if (user.isAttendee) {
    return KolabingRoutes.attendeeDashboard;
  }

  if (isNewUser || !user.onboardingCompleted) {
    return user.isBusiness
        ? KolabingRoutes.businessOnboardingStep2
        : KolabingRoutes.communityOnboardingStep1;
  }

  return user.isBusiness
      ? KolabingRoutes.businessDashboard
      : KolabingRoutes.communityDashboard;
}
