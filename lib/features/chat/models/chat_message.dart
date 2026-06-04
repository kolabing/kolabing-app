/// The sender of a [ChatMessage] (lightweight profile summary).
class ChatSender {
  const ChatSender({
    required this.profileId,
    required this.name,
    this.avatarUrl,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) => ChatSender(
        profileId: json['profile_id'] as String? ?? '',
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
        threadId: json['thread_id'] as String,
        sender:
            ChatSender.fromJson(json['sender'] as Map<String, dynamic>? ?? const {}),
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        isMine: json['is_mine'] as bool? ?? false,
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
