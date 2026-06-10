import 'package:flutter/foundation.dart';

/// Relationship between the viewer and another profile, as reported on profile
/// payloads (`PublicProfileResource` / game-card) under `friend_status`.
///
/// Contract: docs/tickets/2026-06-10-friends-graph-NF17-contract.md.
enum FriendStatus {
  /// Viewing your own profile — no CTA.
  self,

  /// No relationship — show "Add friend".
  none,

  /// I sent a request — show "Pending" + cancel.
  pendingOutgoing,

  /// They sent me a request — show "Accept / Decline".
  pendingIncoming,

  /// Accepted — show "Friends" + remove.
  friends;

  /// Map a backend wire value (snake_case) to a [FriendStatus]. Unknown or
  /// missing values default to [FriendStatus.none] so the feature self-gates
  /// (CTA hidden, no crash) until the backend deploys.
  static FriendStatus fromApi(String? value) {
    switch (value) {
      case 'self':
        return FriendStatus.self;
      case 'pending_outgoing':
        return FriendStatus.pendingOutgoing;
      case 'pending_incoming':
        return FriendStatus.pendingIncoming;
      case 'friends':
        return FriendStatus.friends;
      case 'none':
        return FriendStatus.none;
      default:
        return FriendStatus.none;
    }
  }
}

/// A single accepted friend (from `GET /me/friends`) or an incoming requester
/// (from `GET /me/friend-requests`). Both endpoints return the same item shape:
/// `{ profile_id, name, avatar_url, user_type }`.
@immutable
class FriendSummary {
  const FriendSummary({
    required this.profileId,
    required this.name,
    this.avatarUrl,
    required this.userType,
  });

  factory FriendSummary.fromJson(Map<String, dynamic> json) => FriendSummary(
        // Tolerate both `profile_id` (contract) and a bare `id` fallback.
        profileId:
            (json['profile_id'] ?? json['id'])?.toString() ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: _firstNonEmpty([
          json['avatar_url'] as String?,
          json['logo_url'] as String?,
          json['profile_photo'] as String?,
        ]),
        userType: json['user_type'] as String? ?? '',
      );

  final String profileId;
  final String name;
  final String? avatarUrl;
  final String userType;

  String get initial => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}

/// Result of `GET /me/friend-requests`: the incoming list plus its count badge.
@immutable
class FriendRequests {
  const FriendRequests({required this.requests, required this.count});

  const FriendRequests.empty()
      : requests = const [],
        count = 0;

  final List<FriendSummary> requests;
  final int count;
}

String? _firstNonEmpty(List<String?> candidates) {
  for (final value in candidates) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
