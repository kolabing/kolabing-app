import '../../../config/routes/routes.dart';

String resolveNotificationRoute({
  String? type,
  String? id,
  String? deeplink,
  String? targetType,
}) {
  // Community / group / event chat messages carry targetType 'chat_thread' and a
  // THREAD id (not an application id). There is no path route to a specific thread
  // (they open ChatThreadScreen with the loaded object), and the backend deeplink
  // wrongly points at /application/{threadId}/chat — so send these to the chats
  // list, where tapping the thread opens it. Handled before the deeplink/type
  // branches to override that bad deeplink.
  if (targetType == 'chat_thread') {
    return KolabingRoutes.chats;
  }

  final normalizedDeeplink = normalizeNotificationDeeplink(deeplink);
  if (normalizedDeeplink != null) {
    return normalizedDeeplink;
  }

  final normalizedId = id?.trim();
  if (normalizedId == null || normalizedId.isEmpty) {
    return KolabingRoutes.notifications;
  }

  switch (type) {
    case 'new_message':
      return KolabingRoutes.applicationChat.replaceFirst(':id', normalizedId);
    case 'application_received':
    case 'application_accepted':
    case 'application_declined':
    case 'application_withdrawn':
      return KolabingRoutes.applicationDetails.replaceFirst(
        ':id',
        normalizedId,
      );
    case 'collab_day_reminder':
    case 'collab_followup_reminder':
    case 'collaboration_created':
    case 'collaboration_activated':
    case 'collaboration_feedback_received':
    case 'collaboration_completed':
    case 'collaboration_cancelled':
      return KolabingRoutes.collaborationDetails.replaceFirst(
        ':id',
        normalizedId,
      );
    // Event reminders carry the EVENT id in `target_id`.
    case 'event_reminder_24h':
    case 'event_reminder_1h':
      return KolabingRoutes.eventDetail.replaceFirst(':id', normalizedId);
    default:
      return KolabingRoutes.notifications;
  }
}

String? normalizeNotificationDeeplink(String? deeplink) {
  final raw = deeplink?.trim();
  if (raw == null || raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  final path = (uri?.hasScheme ?? false) ? uri?.path : raw;
  if (path == null || path.isEmpty) return null;

  return _isSupportedNotificationPath(path) ? path : null;
}

bool _isSupportedNotificationPath(String path) {
  const exactRoutes = <String>{
    KolabingRoutes.notifications,
    KolabingRoutes.businessDashboard,
    KolabingRoutes.businessBrowse,
    KolabingRoutes.communityDashboard,
    KolabingRoutes.communityOffers,
    KolabingRoutes.attendeeDashboard,
    KolabingRoutes.communityWallet,
    KolabingRoutes.communityReferrals,
    KolabingRoutes.businessReferrals,
  };

  if (exactRoutes.contains(path)) {
    return true;
  }

  final segments = Uri.parse(path).pathSegments;
  if (segments.length == 2 && segments[0] == 'application') {
    return true;
  }
  if (segments.length == 3 &&
      segments[0] == 'application' &&
      segments[2] == 'chat') {
    return true;
  }
  if (segments.length == 2 && segments[0] == 'collaboration') {
    return true;
  }
  if (segments.length == 2 && segments[0] == 'event') {
    return true;
  }

  return false;
}
