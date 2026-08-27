import 'package:flutter/foundation.dart';

import '../../friends/models/friendship.dart';

/// A matched public profile card from `GET /profiles/lookup` (identity contract
/// §4): `{ id, name, handle, avatar_url, user_type, friend_status }`. No PII
/// beyond the public card.
@immutable
class ProfileLookupResult {
  const ProfileLookupResult({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
    required this.userType,
    this.friendStatus,
  });

  factory ProfileLookupResult.fromJson(Map<String, dynamic> json) =>
      ProfileLookupResult(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        handle: json['handle'] as String?,
        avatarUrl: _firstNonEmpty([
          json['avatar_url'] as String?,
          json['logo_url'] as String?,
          json['profile_photo'] as String?,
        ]),
        userType: json['user_type'] as String? ?? '',
        // Absent → null so callers that key off friendship self-gate (no CTA).
        friendStatus: json.containsKey('friend_status')
            ? FriendStatus.fromApi(json['friend_status'] as String?)
            : null,
      );

  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;
  final String userType;
  final FriendStatus? friendStatus;

  String get initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  bool get isAttendee => userType == 'attendee';
}

String? _firstNonEmpty(List<String?> candidates) {
  for (final value in candidates) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
