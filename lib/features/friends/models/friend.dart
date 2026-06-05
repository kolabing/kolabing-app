/// Friendship status as stored on the backend `friendships.status` column.
///
/// IMPORTANT: [toApiValue] strings are the backend enum wire values. Never
/// rename without a coordinated backend change.
enum FriendshipStatus {
  pending,
  accepted,
  declined,
  blocked;

  static FriendshipStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'declined':
        return FriendshipStatus.declined;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }

  String toApiValue() => name;
}

/// Direction of a friendship row relative to the current user.
///
/// `incoming` — the other profile sent the request to me (I can accept/decline).
/// `outgoing` — I sent the request to the other profile (shown as pending/sent).
/// `mutual`   — accepted friendship; direction no longer matters.
enum FriendshipDirection {
  incoming,
  outgoing,
  mutual;

  static FriendshipDirection fromString(String? value) {
    switch (value) {
      case 'incoming':
        return FriendshipDirection.incoming;
      case 'outgoing':
      case 'sent':
        return FriendshipDirection.outgoing;
      case 'mutual':
        return FriendshipDirection.mutual;
      default:
        return FriendshipDirection.mutual;
    }
  }

  bool get isIncoming => this == FriendshipDirection.incoming;
  bool get isOutgoing => this == FriendshipDirection.outgoing;
}

/// A friend (or pending/suggested candidate) as returned by the friends
/// endpoints. The friendship `id` belongs to the `friendships` row; the nested
/// [profile] summary identifies the other person.
///
/// Item shape (per Batch 5 contract):
/// `{ id, status, direction, profile: { id, name, avatar_url, user_type } }`.
/// Suggested candidates may omit `id`/`status`/`direction` (no friendship row
/// exists yet) and instead carry [sharedEventCount].
class Friend {
  const Friend({
    required this.profileId,
    required this.name,
    this.friendshipId,
    this.avatarUrl,
    this.userType,
    this.status = FriendshipStatus.accepted,
    this.direction = FriendshipDirection.mutual,
    this.sharedEventCount,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    // Tolerate both a nested `profile` object and a flat shape.
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return Friend(
      friendshipId: json['id'] as String?,
      profileId: profile['id'] as String,
      name:
          profile['name'] as String? ??
          profile['display_name'] as String? ??
          '',
      avatarUrl: profile['avatar_url'] as String?,
      userType: profile['user_type'] as String?,
      status: FriendshipStatus.fromString(json['status'] as String?),
      direction: FriendshipDirection.fromString(json['direction'] as String?),
      sharedEventCount:
          json['shared_event_count'] as int? ?? json['shared_events'] as int?,
    );
  }

  /// Friendship row id. Null for suggested candidates (no row yet) and required
  /// for accept/decline (which act on the row).
  final String? friendshipId;
  final String profileId;
  final String name;
  final String? avatarUrl;
  final String? userType;
  final FriendshipStatus status;
  final FriendshipDirection direction;

  /// Co-attendance count, present only on suggested candidates.
  final int? sharedEventCount;

  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isPending => status == FriendshipStatus.pending;
  bool get isIncoming => direction.isIncoming;
  bool get isOutgoing => direction.isOutgoing;

  Friend copyWith({
    String? friendshipId,
    String? profileId,
    String? name,
    String? avatarUrl,
    String? userType,
    FriendshipStatus? status,
    FriendshipDirection? direction,
    int? sharedEventCount,
  }) => Friend(
    friendshipId: friendshipId ?? this.friendshipId,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    userType: userType ?? this.userType,
    status: status ?? this.status,
    direction: direction ?? this.direction,
    sharedEventCount: sharedEventCount ?? this.sharedEventCount,
  );
}

/// Split incoming + sent requests, as returned by `GET /me/friends/requests`.
class FriendRequests {
  const FriendRequests({required this.incoming, required this.sent});

  factory FriendRequests.fromJson(Map<String, dynamic> json) {
    List<Friend> parse(Object? raw, FriendshipDirection fallback) {
      final list = (raw as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(Friend.fromJson)
          .toList();
      // Stamp the bucket's direction when the backend omits it per-item.
      return list
          .map(
            (f) => f.direction == FriendshipDirection.mutual
                ? f.copyWith(direction: fallback)
                : f,
          )
          .toList();
    }

    return FriendRequests(
      incoming: parse(json['incoming'], FriendshipDirection.incoming),
      sent: parse(
        json['sent'] ?? json['outgoing'],
        FriendshipDirection.outgoing,
      ),
    );
  }

  final List<Friend> incoming;
  final List<Friend> sent;

  bool get isEmpty => incoming.isEmpty && sent.isEmpty;
}
