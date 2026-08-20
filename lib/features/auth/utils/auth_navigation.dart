import 'package:flutter/foundation.dart';

import '../../../config/routes/routes.dart';
import '../../../services/permission_service.dart';
import '../models/user_model.dart';

/// Destinations that drop the user inside the authenticated app, and therefore
/// must not be reached before the notification consent prompt has been raised.
const Set<String> _kPermissionGatedDestinations = <String>{
  KolabingRoutes.businessDashboard,
  KolabingRoutes.communityDashboard,
  KolabingRoutes.attendeeDashboard,
};

/// Routes [destination] through `/permissions` while notification consent is
/// still outstanding.
///
/// Apple guideline 4.5.4 requires the system consent prompt *before* the app
/// registers for or delivers any push notification. Every post-authentication
/// path funnels through here so no role can slip past the prompt — an
/// attendee-shaped destination silently bypassing the gate is what caused the
/// 1.5 (36) rejection. Onboarding destinations pass straight through; each
/// onboarding flow calls this helper again on its final step.
Future<String> gateDestinationOnPermissions(String destination) async {
  if (!_kPermissionGatedDestinations.contains(destination)) {
    return destination;
  }

  final settled = await PermissionService.instance.hasShownPermissionScreen();
  if (settled) {
    return destination;
  }

  return '${KolabingRoutes.permissions}?destination='
      '${Uri.encodeComponent(destination)}';
}

/// Resolves the next in-app route after authentication or session restore.
String resolveAuthDestination(UserModel user, {bool isNewUser = false}) {
  if (user.isAttendee) {
    // A brand-new social attendee (Google/Apple is_new_user) runs the 4-step
    // onboarding (name/handle/interests/join) just like the email/password
    // path; an existing attendee goes straight to their dashboard.
    return isNewUser
        ? KolabingRoutes.attendeeOnboardingStep1
        : KolabingRoutes.attendeeDashboard;
  }

  // Onboarding is mandatory at registration. Existing accounts always have it
  // completed — the only signal that the user must run onboarding is the
  // `is_new_user` flag returned by OAuth (Google/Apple) when they create a
  // brand-new account.
  if (isNewUser) {
    if (user.isBusiness) return KolabingRoutes.businessOnboardingStep5;
    if (user.isCommunity) return KolabingRoutes.communityOnboardingStep1;
    debugPrint(
      '[B2] resolveAuthDestination: unknown new-user type=${user.userType} '
      '— falling back to welcome',
    );
    return KolabingRoutes.welcome;
  }

  if (user.isBusiness) return KolabingRoutes.businessDashboard;
  if (user.isCommunity) return KolabingRoutes.communityDashboard;

  // Unknown user type — log loudly and route to a known landing instead of
  // silently defaulting to /community (which would bounce the user).
  debugPrint(
    '[B2] resolveAuthDestination: unknown user type=${user.userType} '
    '(id=${user.id}) — falling back to welcome',
  );
  return KolabingRoutes.welcome;
}
