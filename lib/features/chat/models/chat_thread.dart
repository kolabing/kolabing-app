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
  const ChatParticipant({required this.name, this.profileId, this.avatarUrl});

  factory ChatParticipant.fromJson(Map<String, dynamic> json) =>
      ChatParticipant(
        name: json['name'] as String? ?? '',
        // Tolerate `profile_id` or a flat `id` — the ban action keys off this.
        profileId: (json['profile_id'] ?? json['id']) as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String name;

  /// The participant's profile id, when the backend exposes it. Required to
  /// target the ban (remove member) action; may be null for summary-only rows.
  final String? profileId;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (profileId != null) 'profile_id': profileId,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

/// A minimal event summary attached to an [ChatThreadType.event] thread, so the
/// thread header can deep-link to the event without a separate fetch.
class ChatThreadEvent {
  const ChatThreadEvent({required this.id, this.name, this.date});

  factory ChatThreadEvent.fromJson(Map<String, dynamic> json) =>
      ChatThreadEvent(
        id: json['id'] as String,
        name: json['name'] as String?,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
      );

  final String id;
  final String? name;
  final DateTime? date;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (date != null) 'date': date!.toIso8601String(),
      };
}

/// A chat thread (conversation). One of [communityId] / [collaborationId] is
/// set; [eventId] only with a community.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.type,
    this.name,
    this.slug,
    this.applicationId,
    this.communityId,
    this.collaborationId,
    this.eventId,
    this.event,
    this.isOpen = false,
    this.canManage = false,
    this.isMember = false,
    this.isParticipant = false,
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
    final eventJson = json['event'];
    return ChatThread(
      id: json['id'] as String,
      type: ChatThreadType.fromString(json['type'] as String? ?? 'community_custom'),
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      applicationId: json['application_id'] as String?,
      communityId: json['community_id'] as String?,
      collaborationId: json['collaboration_id'] as String?,
      eventId: json['event_id'] as String?,
      event: eventJson is Map<String, dynamic>
          ? ChatThreadEvent.fromJson(eventJson)
          : null,
      isOpen: json['is_open'] as bool? ?? false,
      canManage: json['can_manage'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
      isParticipant: json['is_participant'] as bool? ?? false,
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

  /// Stable per-community slug (custom chats). This is the gating key: a tier
  /// grants access by listing this slug in its `permissions.chat_channels`.
  final String? slug;

  /// For collaboration threads, the application that backs the chat — messages
  /// are read/sent via the existing `/applications/{id}/messages` endpoints.
  final String? applicationId;
  final String? communityId;
  final String? collaborationId;
  final String? eventId;

  /// Event summary (`{id, name, date}`) for [ChatThreadType.event] threads. Lets
  /// the thread header deep-link to the event detail screen.
  final ChatThreadEvent? event;

  /// True when any active community member may self-join this chat.
  final bool isOpen;

  /// True when the viewer owns / can manage the thread's community (drives the
  /// inline create / rename / delete / ban actions).
  final bool canManage;

  /// True when the viewer is an active member of the thread's community.
  final bool isMember;

  /// True when the viewer has actually joined this thread (vs. merely eligible).
  final bool isParticipant;

  /// Null until the first message — the business "active" filter keys off this.
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<ChatParticipant> participants;
  final DateTime createdAt;

  bool get hasMessages => lastMessageAt != null;
  bool get hasUnread => unreadCount > 0;

  /// A custom or event chat can be deleted (collaboration / main never).
  bool get isDeletable =>
      type == ChatThreadType.communityCustom || type == ChatThreadType.event;

  /// Only custom community chats can be renamed.
  bool get isRenamable => type == ChatThreadType.communityCustom;

  /// An open thread the viewer can join but has not yet joined.
  bool get canJoin => isOpen && !isParticipant;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toApiValue(),
        if (name != null) 'name': name,
        if (slug != null) 'slug': slug,
        if (applicationId != null) 'application_id': applicationId,
        if (communityId != null) 'community_id': communityId,
        if (collaborationId != null) 'collaboration_id': collaborationId,
        if (eventId != null) 'event_id': eventId,
        if (event != null) 'event': event!.toJson(),
        'is_open': isOpen,
        'can_manage': canManage,
        'is_member': isMember,
        'is_participant': isParticipant,
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
    String? slug,
    String? applicationId,
    String? communityId,
    String? collaborationId,
    String? eventId,
    ChatThreadEvent? event,
    bool? isOpen,
    bool? canManage,
    bool? isMember,
    bool? isParticipant,
    DateTime? lastMessageAt,
    int? unreadCount,
    List<ChatParticipant>? participants,
    DateTime? createdAt,
  }) =>
      ChatThread(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        applicationId: applicationId ?? this.applicationId,
        communityId: communityId ?? this.communityId,
        collaborationId: collaborationId ?? this.collaborationId,
        eventId: eventId ?? this.eventId,
        event: event ?? this.event,
        isOpen: isOpen ?? this.isOpen,
        canManage: canManage ?? this.canManage,
        isMember: isMember ?? this.isMember,
        isParticipant: isParticipant ?? this.isParticipant,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        participants: participants ?? this.participants,
        createdAt: createdAt ?? this.createdAt,
      );
}
