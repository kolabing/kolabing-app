import 'package:shared_preferences/shared_preferences.dart';

/// A Kolabing team link (`/o/{offerId}`) that arrived while nobody was signed
/// in (SERR-1344).
///
/// A link carries no state through the store, so the phone that installs the
/// app from it opens a blank app. The offer itself waits in the recipient's
/// "Kolabing team" thread on the backend; this remembers the route for the
/// phone that *did* have the link tapped, so after sign-in the person lands on
/// the card instead of the home screen. Only team routes are ever stored.
class PendingTeamLink {
  PendingTeamLink._();

  static const String _key = 'pending_team_link_route';

  /// The only routes a link may park here.
  static bool isTeamRoute(String route) =>
      RegExp(r'^/team-offer/[0-9a-f-]{36}$').hasMatch(route);

  static Future<void> save(String route) async {
    if (!isTeamRoute(route)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, route);
  }

  /// The parked route, once; null when there is none.
  static Future<String?> take() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_key);
    if (route == null) return null;
    await prefs.remove(_key);
    return isTeamRoute(route) ? route : null;
  }
}
