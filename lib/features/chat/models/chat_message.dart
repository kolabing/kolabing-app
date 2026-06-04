/// The sender of a [ChatMessage] (lightweight profile summary).
class ChatSender {
  const ChatSender({
    required this.profileId,
    required this.name,
    this.avatarUrl,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) => ChatSender(
        // Tolerate ProfileSummaryResource (`id`) and a flat `profile_id`.
        profileId: (json['profile_id'] ?? json['id']) as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
      );

  final String profileId;
  final String name;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

/// A single message in a chat thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        // thread_id (generic) or application_id (existing collaboration resource).
        threadId: (json['thread_id'] ?? json['application_id']) as String? ?? '',
        // sender_profile (ChatMessageResource) or a flat sender.
        sender: ChatSender.fromJson(
            (json['sender_profile'] ?? json['sender'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        // content (ChatMessageResource) or body.
        body: (json['content'] ?? json['body']) as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        // is_own (ChatMessageResource) or is_mine.
        isMine: (json['is_own'] ?? json['is_mine']) as bool? ?? false,
      );

  final String id;
  final String threadId;
  final ChatSender sender;
  final String body;
  final DateTime createdAt;

  /// True when the authenticated user sent it (right-aligned bubble).
  final bool isMine;

  Map<String, dynamic> toJson() => {
        'id': id,
        'thread_id': threadId,
        'sender': sender.toJson(),
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'is_mine': isMine,
      };

  ChatMessage copyWith({
    String? id,
    String? threadId,
    ChatSender? sender,
    String? body,
    DateTime? createdAt,
    bool? isMine,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        threadId: threadId ?? this.threadId,
        sender: sender ?? this.sender,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        isMine: isMine ?? this.isMine,
      );
}
