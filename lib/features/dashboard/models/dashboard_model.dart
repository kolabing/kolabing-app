import 'package:flutter/foundation.dart';

/// Stats count for opportunities (business dashboard)
@immutable
class OpportunityStats {
  const OpportunityStats({
    this.total = 0,
    this.published = 0,
    this.draft = 0,
    this.closed = 0,
  });

  final int total;
  final int published;
  final int draft;
  final int closed;

  factory OpportunityStats.fromJson(Map<String, dynamic> json) {
    return OpportunityStats(
      total: json['total'] as int? ?? 0,
      published: json['published'] as int? ?? 0,
      draft: json['draft'] as int? ?? 0,
      closed: json['closed'] as int? ?? 0,
    );
  }
}

/// Stats count for applications received (business dashboard)
@immutable
class ApplicationsReceivedStats {
  const ApplicationsReceivedStats({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.declined = 0,
  });

  final int total;
  final int pending;
  final int accepted;
  final int declined;

  factory ApplicationsReceivedStats.fromJson(Map<String, dynamic> json) {
    return ApplicationsReceivedStats(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      accepted: json['accepted'] as int? ?? 0,
      declined: json['declined'] as int? ?? 0,
    );
  }
}

/// Stats count for applications sent (community dashboard)
@immutable
class ApplicationsSentStats {
  const ApplicationsSentStats({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.declined = 0,
    this.withdrawn = 0,
  });

  final int total;
  final int pending;
  final int accepted;
  final int declined;
  final int withdrawn;

  factory ApplicationsSentStats.fromJson(Map<String, dynamic> json) {
    return ApplicationsSentStats(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      accepted: json['accepted'] as int? ?? 0,
      declined: json['declined'] as int? ?? 0,
      withdrawn: json['withdrawn'] as int? ?? 0,
    );
  }
}

/// Stats count for collaborations (shared between business and community)
@immutable
class CollaborationStats {
  const CollaborationStats({
    this.total = 0,
    this.active = 0,
    this.upcoming = 0,
    this.completed = 0,
  });

  final int total;
  final int active;
  final int upcoming;
  final int completed;

  factory CollaborationStats.fromJson(Map<String, dynamic> json) {
    return CollaborationStats(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
    );
  }
}

/// Opportunity info nested in upcoming collaboration
@immutable
class UpcomingOpportunityInfo {
  const UpcomingOpportunityInfo({
    required this.id,
    required this.title,
    this.categories = const [],
  });

  final String id;
  final String title;
  final List<String> categories;

  factory UpcomingOpportunityInfo.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    List<String> categories = [];
    if (rawCategories is List) {
      categories = rawCategories.map((e) => e.toString()).toList();
    }

    return UpcomingOpportunityInfo(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      categories: categories,
    );
  }
}

/// Partner info nested in upcoming collaboration
@immutable
class UpcomingPartnerInfo {
  const UpcomingPartnerInfo({
    required this.id,
    this.name,
    this.userType,
  });

  final String id;
  final String? name;
  final String? userType;

  /// Get the initial letter for avatar display
  String get initial =>
      (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';

  factory UpcomingPartnerInfo.fromJson(Map<String, dynamic> json) {
    return UpcomingPartnerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      userType: json['user_type'] as String?,
    );
  }
}

/// Collaboration status for upcoming items
enum UpcomingCollaborationStatus {
  scheduled,
  active;

  String get displayName {
    switch (this) {
      case UpcomingCollaborationStatus.scheduled:
        return 'SCHEDULED';
      case UpcomingCollaborationStatus.active:
        return 'ACTIVE';
    }
  }

  static UpcomingCollaborationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return UpcomingCollaborationStatus.active;
      case 'scheduled':
      default:
        return UpcomingCollaborationStatus.scheduled;
    }
  }
}

/// A single upcoming collaboration item
@immutable
class UpcomingCollaboration {
  const UpcomingCollaboration({
    required this.id,
    required this.status,
    this.scheduledDate,
    required this.opportunity,
    required this.partner,
  });

  final String id;
  final UpcomingCollaborationStatus status;
  final String? scheduledDate;
  final UpcomingOpportunityInfo opportunity;
  final UpcomingPartnerInfo partner;

  /// Format the scheduled date for display
  String get dateDisplay {
    if (scheduledDate == null || scheduledDate!.isEmpty) return 'TBD';
    final date = DateTime.tryParse(scheduledDate!);
    if (date == null) return scheduledDate!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  factory UpcomingCollaboration.fromJson(Map<String, dynamic> json) {
    return UpcomingCollaboration(
      id: json['id']?.toString() ?? '',
      status: UpcomingCollaborationStatus.fromString(
        json['status'] as String? ?? 'scheduled',
      ),
      scheduledDate: json['scheduled_date'] as String?,
      opportunity: json['opportunity'] is Map<String, dynamic>
          ? UpcomingOpportunityInfo.fromJson(
              json['opportunity'] as Map<String, dynamic>,
            )
          : const UpcomingOpportunityInfo(id: '', title: ''),
      partner: json['partner'] is Map<String, dynamic>
          ? UpcomingPartnerInfo.fromJson(
              json['partner'] as Map<String, dynamic>,
            )
          : const UpcomingPartnerInfo(id: ''),
    );
  }
}

/// Business dashboard data
@immutable
class BusinessDashboard {
  const BusinessDashboard({
    this.opportunities = const OpportunityStats(),
    this.applicationsReceived = const ApplicationsReceivedStats(),
    this.collaborations = const CollaborationStats(),
    this.upcomingCollaborations = const [],
  });

  final OpportunityStats opportunities;
  final ApplicationsReceivedStats applicationsReceived;
  final CollaborationStats collaborations;
  final List<UpcomingCollaboration> upcomingCollaborations;

  factory BusinessDashboard.fromJson(Map<String, dynamic> json) {
    final upcomingRaw = json['upcoming_collaborations'];
    List<UpcomingCollaboration> upcoming = [];
    if (upcomingRaw is List) {
      upcoming = upcomingRaw
          .whereType<Map<String, dynamic>>()
          .map(UpcomingCollaboration.fromJson)
          .toList();
    }

    return BusinessDashboard(
      opportunities: json['opportunities'] is Map<String, dynamic>
          ? OpportunityStats.fromJson(
              json['opportunities'] as Map<String, dynamic>,
            )
          : const OpportunityStats(),
      applicationsReceived:
          json['applications_received'] is Map<String, dynamic>
              ? ApplicationsReceivedStats.fromJson(
                  json['applications_received'] as Map<String, dynamic>,
                )
              : const ApplicationsReceivedStats(),
      collaborations: json['collaborations'] is Map<String, dynamic>
          ? CollaborationStats.fromJson(
              json['collaborations'] as Map<String, dynamic>,
            )
          : const CollaborationStats(),
      upcomingCollaborations: upcoming,
    );
  }
}

/// Community dashboard data
@immutable
class CommunityDashboard {
  const CommunityDashboard({
    this.applicationsSent = const ApplicationsSentStats(),
    this.collaborations = const CollaborationStats(),
    this.upcomingCollaborations = const [],
  });

  final ApplicationsSentStats applicationsSent;
  final CollaborationStats collaborations;
  final List<UpcomingCollaboration> upcomingCollaborations;

  factory CommunityDashboard.fromJson(Map<String, dynamic> json) {
    final upcomingRaw = json['upcoming_collaborations'];
    List<UpcomingCollaboration> upcoming = [];
    if (upcomingRaw is List) {
      upcoming = upcomingRaw
          .whereType<Map<String, dynamic>>()
          .map(UpcomingCollaboration.fromJson)
          .toList();
    }

    return CommunityDashboard(
      applicationsSent: json['applications_sent'] is Map<String, dynamic>
          ? ApplicationsSentStats.fromJson(
              json['applications_sent'] as Map<String, dynamic>,
            )
          : const ApplicationsSentStats(),
      collaborations: json['collaborations'] is Map<String, dynamic>
          ? CollaborationStats.fromJson(
              json['collaborations'] as Map<String, dynamic>,
            )
          : const CollaborationStats(),
      upcomingCollaborations: upcoming,
    );
  }
}
