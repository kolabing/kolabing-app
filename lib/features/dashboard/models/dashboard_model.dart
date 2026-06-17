import 'package:flutter/foundation.dart';

/// Coerce a JSON value into an int.
///
/// The `/me/dashboard` stat counts are cast to `int` server-side, but DB
/// drivers / JSON encoders occasionally surface numeric aggregates as a
/// `String` ("3") or a `double` (3.0). A bare `as int` cast THROWS on those,
/// which previously bubbled up and put the whole dashboard into its error
/// state ("broken" on both roles). This parses defensively instead.
int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

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
      total: _asInt(json['total']),
      published: _asInt(json['published']),
      draft: _asInt(json['draft']),
      closed: _asInt(json['closed']),
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
      total: _asInt(json['total']),
      pending: _asInt(json['pending']),
      accepted: _asInt(json['accepted']),
      declined: _asInt(json['declined']),
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
      total: _asInt(json['total']),
      pending: _asInt(json['pending']),
      accepted: _asInt(json['accepted']),
      declined: _asInt(json['declined']),
      withdrawn: _asInt(json['withdrawn']),
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
      total: _asInt(json['total']),
      active: _asInt(json['active']),
      upcoming: _asInt(json['upcoming']),
      completed: _asInt(json['completed']),
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
///
/// All fields are nullable: the backend can return `partner.id`, `name` and
/// `user_type` as null (e.g. when the counterpart account was removed or the
/// collaboration has no resolved partner yet). Keeping them nullable means
/// `GET /me/dashboard` never throws while parsing this sub-object.
@immutable
class UpcomingPartnerInfo {
  const UpcomingPartnerInfo({
    this.id,
    this.name,
    this.userType,
    this.isVerified = false,
  });

  final String? id;
  final String? name;
  final String? userType;

  /// Whether the partner community is verified (drives [VerifiedTick]).
  final bool isVerified;

  /// Get the initial letter for avatar display
  String get initial =>
      (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';

  factory UpcomingPartnerInfo.fromJson(Map<String, dynamic> json) {
    return UpcomingPartnerInfo(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      userType: json['user_type'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
          : const UpcomingPartnerInfo(),
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
    this.applicationsReceived = const ApplicationsReceivedStats(),
    this.collaborations = const CollaborationStats(),
    this.upcomingCollaborations = const [],
  });

  final ApplicationsSentStats applicationsSent;
  final ApplicationsReceivedStats applicationsReceived;
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
