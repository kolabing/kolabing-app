/// The kind of chat thread. Drives how a thread is grouped/labelled per role.
///
/// IMPORTANT: [toApiValue] strings are the backend `chat_threads.type` wire
/// values. Never rename without a backend change. See
/// docs/tickets/2026-06-04-chat-feature-spec.md.
enum ChatThreadType {
  /// Business <-> community, bound to an accepted collaboration (existing).
  collaboration,

  /// A community's default "main" chat (auto-created with the community).
  communityMain,

  /// A leader-created custom community chat (up to 5 per community).
  communityCustom,

  /// A chat tied to an event; only members who signed up (RSVP) may join.
  event;

  static ChatThreadType fromString(String value) {
    switch (value) {
      case 'collaboration':
        return ChatThreadType.collaboration;
      case 'community_main':
        return ChatThreadType.communityMain;
      case 'community_custom':
        return ChatThreadType.communityCustom;
      case 'event':
        return ChatThreadType.event;
      default:
        return ChatThreadType.communityCustom;
    }
  }

  String toApiValue() {
    switch (this) {
      case ChatThreadType.collaboration:
        return 'collaboration';
      case ChatThreadType.communityMain:
        return 'community_main';
      case ChatThreadType.communityCustom:
        return 'community_custom';
      case ChatThreadType.event:
        return 'event';
    }
  }

  bool get isCommunity =>
      this == ChatThreadType.communityMain ||
      this == ChatThreadType.communityCustom;
}

/// A lightweight participant summary for a thread (avatar stack / title).
class ChatParticipant {
  const ChatParticipant({required this.name, this.avatarUrl});

  factory ChatParticipant.fromJson(Map<String, dynamic> json) =>
      ChatParticipant(
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
      );

  final String name;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

/// A chat thread (conversation). One of [communityId] / [collaborationId] is
/// set; [eventId] only with a community.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.type,
    this.name,
    this.applicationId,
    this.communityId,
    this.collaborationId,
    this.eventId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participants = const [],
    required this.createdAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final parts = (json['participant_summary'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ChatParticipant.fromJson)
        .toList();
    return ChatThread(
      id: json['id'] as String,
      type: ChatThreadType.fromString(json['type'] as String? ?? 'community_custom'),
      name: json['name'] as String?,
      applicationId: json['application_id'] as String?,
      communityId: json['community_id'] as String?,
      collaborationId: json['collaboration_id'] as String?,
      eventId: json['event_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      participants: parts,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final ChatThreadType type;

  /// Display name. For [ChatThreadType.communityMain] the backend may send the
  /// community name; falls back to a sensible default in the UI when null.
  final String? name;

  /// For collaboration threads, the application that backs the chat — messages
  /// are read/sent via the existing `/applications/{id}/messages` endpoints.
  final String? applicationId;
  final String? communityId;
  final String? collaborationId;
  final String? eventId;

  /// Null until the first message — the business "active" filter keys off this.
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<ChatParticipant> participants;
  final DateTime createdAt;

  bool get hasMessages => lastMessageAt != null;
  bool get hasUnread => unreadCount > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toApiValue(),
        if (name != null) 'name': name,
        if (applicationId != null) 'application_id': applicationId,
        if (communityId != null) 'community_id': communityId,
        if (collaborationId != null) 'collaboration_id': collaborationId,
        if (eventId != null) 'event_id': eventId,
        if (lastMessageAt != null)
          'last_message_at': lastMessageAt!.toIso8601String(),
        'unread_count': unreadCount,
        'participant_summary': participants.map((p) => p.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  ChatThread copyWith({
    String? id,
    ChatThreadType? type,
    String? name,
    String? applicationId,
    String? communityId,
    String? collaborationId,
    String? eventId,
    DateTime? lastMessageAt,
    int? unreadCount,
    List<ChatParticipant>? participants,
    DateTime? createdAt,
  }) =>
      ChatThread(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        applicationId: applicationId ?? this.applicationId,
        communityId: communityId ?? this.communityId,
        collaborationId: collaborationId ?? this.collaborationId,
        eventId: eventId ?? this.eventId,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        participants: participants ?? this.participants,
        createdAt: createdAt ?? this.createdAt,
      );
}
