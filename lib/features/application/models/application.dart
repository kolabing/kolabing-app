import 'package:flutter/foundation.dart';

import '../../opportunity/models/opportunity.dart';

/// Application status (matches API: pending, accepted, declined, withdrawn)
enum ApplicationStatus {
  pending,
  accepted,
  declined,
  withdrawn;

  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.declined:
        return 'Declined';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  bool get isPending => this == pending;
  bool get isAccepted => this == accepted;
  bool get isDeclined => this == declined;
  bool get isWithdrawn => this == withdrawn;

  /// Check if application is in a final state (can't be changed)
  bool get isFinal => this != pending;

  static ApplicationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'declined':
        return ApplicationStatus.declined;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.pending;
    }
  }
}

/// Sender profile in chat message
@immutable
class SenderProfile {
  const SenderProfile({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.userType,
  });

  final String id;
  final String name;
  final String? profilePhoto;
  final String? userType;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory SenderProfile.fromJson(Map<String, dynamic> json) {
    return SenderProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      profilePhoto: json['profile_photo'] as String?,
      userType: json['user_type'] as String?,
    );
  }
}

/// Chat message for application conversation
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.applicationId,
    required this.senderProfile,
    required this.content,
    required this.createdAt,
    this.isOwn = false,
    this.isRead = false,
    this.readAt,
  });

  final String id;
  final String applicationId;
  final SenderProfile senderProfile;
  final String content;
  final DateTime createdAt;
  final bool isOwn;
  final bool isRead;
  final DateTime? readAt;

  /// Legacy accessors for compatibility
  String get senderId => senderProfile.id;
  String get senderName => senderProfile.name;
  DateTime get timestamp => createdAt;

  String get timeDisplay {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse sender_profile
    SenderProfile senderProfile;
    final profile = json['sender_profile'];
    if (profile is Map<String, dynamic>) {
      senderProfile = SenderProfile.fromJson(profile);
    } else {
      // Fallback for old format
      senderProfile = SenderProfile(
        id: json['sender_id']?.toString() ?? '',
        name: json['sender_name'] as String? ?? 'Unknown',
      );
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      applicationId: json['application_id']?.toString() ?? '',
      senderProfile: senderProfile,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
                 DateTime.tryParse(json['timestamp'] as String? ?? '') ??
                 DateTime.now(),
      isOwn: json['is_own'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? applicationId,
    SenderProfile? senderProfile,
    String? content,
    DateTime? createdAt,
    bool? isOwn,
    bool? isRead,
    DateTime? readAt,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        applicationId: applicationId ?? this.applicationId,
        senderProfile: senderProfile ?? this.senderProfile,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        isOwn: isOwn ?? this.isOwn,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
      );
}

/// Applicant profile from API response
@immutable
class ApplicantProfile {
  const ApplicantProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.city,
    this.category,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? city;
  final String? category;

  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  factory ApplicantProfile.fromJson(Map<String, dynamic> json) {
    // city can be a String or a Map with 'name' key
    String? city;
    final rawCity = json['city'];
    if (rawCity is String) {
      city = rawCity;
    } else if (rawCity is Map<String, dynamic>) {
      city = rawCity['name'] as String?;
    }

    // category can be a String or a Map with 'name' key
    String? category;
    final rawCategory = json['category'];
    if (rawCategory is String) {
      category = rawCategory;
    } else if (rawCategory is Map<String, dynamic>) {
      category = rawCategory['name'] as String?;
    }

    return ApplicantProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      city: city,
      category: category,
    );
  }
}

/// Application model
@immutable
class Application {
  const Application({
    required this.id,
    required this.opportunityId,
    required this.message,
    required this.availability,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.declineReason,
    this.applicantProfile,
    this.opportunity,
    this.messages = const [],
    this.unreadCount = 0,
  });

  final String id;
  final String opportunityId;
  final String message;
  final String availability;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? declineReason;
  final ApplicantProfile? applicantProfile;
  final Opportunity? opportunity;
  final List<ChatMessage> messages;
  final int unreadCount;

  /// Get opportunity title
  String get opportunityTitle => opportunity?.title ?? 'Unknown Opportunity';

  /// Get applicant name
  String get applicantName => applicantProfile?.displayName ?? 'Unknown';

  /// Get applicant avatar
  String? get applicantAvatar => applicantProfile?.avatarUrl;

  /// Get opportunity owner name
  String get recipientName => opportunity?.creatorProfile?.displayName ?? 'Unknown';

  /// Get opportunity owner avatar
  String? get recipientAvatar => opportunity?.creatorProfile?.avatarUrl;

  /// Get applicant ID
  String get applicantId => applicantProfile?.id ?? '';

  /// Get recipient ID
  String get recipientId => opportunity?.creatorProfile?.id ?? '';

  /// Get the other party's name (for display in list)
  String otherPartyName(String currentUserId) =>
      applicantId == currentUserId ? recipientName : applicantName;

  /// Get the other party's avatar
  String? otherPartyAvatar(String currentUserId) =>
      applicantId == currentUserId ? recipientAvatar : applicantAvatar;

  /// Check if current user is the applicant
  bool isApplicant(String currentUserId) => applicantId == currentUserId;

  /// Display date
  String get createdAtDisplay {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  factory Application.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Parse nested collab_opportunity if present
    Opportunity? opportunity;
    final collabOpp = json['collab_opportunity'];
    if (collabOpp is Map<String, dynamic>) {
      opportunity = Opportunity.fromJson(collabOpp);
    }

    // Parse applicant_profile if present
    ApplicantProfile? applicantProfile;
    final profile = json['applicant_profile'];
    if (profile is Map<String, dynamic>) {
      applicantProfile = ApplicantProfile.fromJson(profile);
    }

    // availability can be a String or a Map (structured time slot data)
    String availability;
    final rawAvailability = json['availability'];
    if (rawAvailability is String) {
      availability = rawAvailability;
    } else if (rawAvailability is Map<String, dynamic>) {
      // Extract readable text from structured availability
      availability = rawAvailability['text'] as String? ??
          rawAvailability.toString();
    } else {
      availability = '';
    }

    return Application(
      id: json['id']?.toString() ?? '',
      opportunityId: json['collab_opportunity_id']?.toString() ??
                     json['opportunity_id']?.toString() ?? '',
      message: json['message'] as String? ?? '',
      availability: availability,
      status: ApplicationStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      declineReason: json['decline_reason'] as String?,
      applicantProfile: applicantProfile,
      opportunity: opportunity,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  /// Create JSON for submitting application
  Map<String, dynamic> toSubmitJson() => {
        'message': message,
        'availability': availability,
      };

  Application copyWith({
    String? id,
    String? opportunityId,
    String? message,
    String? availability,
    ApplicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? declineReason,
    ApplicantProfile? applicantProfile,
    Opportunity? opportunity,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) =>
      Application(
        id: id ?? this.id,
        opportunityId: opportunityId ?? this.opportunityId,
        message: message ?? this.message,
        availability: availability ?? this.availability,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        declineReason: declineReason ?? this.declineReason,
        applicantProfile: applicantProfile ?? this.applicantProfile,
        opportunity: opportunity ?? this.opportunity,
        messages: messages ?? this.messages,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

/// Unread messages count model
@immutable
class UnreadMessagesCount {
  const UnreadMessagesCount({
    required this.total,
    required this.byApplication,
  });

  final int total;
  final Map<String, int> byApplication;

  factory UnreadMessagesCount.fromJson(Map<String, dynamic> json) {
    final byAppRaw = json['by_application'] as Map<String, dynamic>? ?? {};
    final byApp = byAppRaw.map((key, value) => MapEntry(key, value as int? ?? 0));

    return UnreadMessagesCount(
      total: json['total'] as int? ?? 0,
      byApplication: byApp,
    );
  }

  /// Get unread count for a specific application
  int getCountForApplication(String applicationId) =>
      byApplication[applicationId] ?? 0;
}
