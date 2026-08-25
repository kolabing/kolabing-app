import 'package:flutter/foundation.dart';

import 'multi_kolab_creator_summary.dart';
import 'multi_kolab_enums.dart';

/// `GET /multi-kolab-events/{event}/dashboard` — matches contract §9 exactly.
@immutable
class MultiKolabDashboard {
  const MultiKolabDashboard({
    required this.eventId,
    required this.status,
    required this.roleCounts,
    required this.roles,
  });

  factory MultiKolabDashboard.fromJson(Map<String, dynamic> json) =>
      MultiKolabDashboard(
        eventId: json['event_id']?.toString() ?? '',
        status: MultiKolabEventStatus.fromApiValue(
          json['status']?.toString() ?? 'draft',
        ),
        roleCounts: MultiKolabRoleCounts.fromJson(
          json['role_counts'] as Map<String, dynamic>?,
        ),
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map(
              (e) =>
                  MultiKolabDashboardRole.fromJson(e as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  final String eventId;
  final MultiKolabEventStatus status;
  final MultiKolabRoleCounts roleCounts;
  final List<MultiKolabDashboardRole> roles;
}

@immutable
class MultiKolabDashboardRole {
  const MultiKolabDashboardRole({
    required this.roleId,
    required this.title,
    required this.positionsNeeded,
    required this.positionsFilled,
    required this.status,
    required this.applicationCounts,
  });

  factory MultiKolabDashboardRole.fromJson(Map<String, dynamic> json) =>
      MultiKolabDashboardRole(
        roleId: json['role_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        positionsNeeded: _asInt(json['positions_needed']) ?? 0,
        positionsFilled: _asInt(json['positions_filled']) ?? 0,
        status: MultiKolabRoleStatus.fromApiValue(
          json['status']?.toString() ?? 'open',
        ),
        applicationCounts: MultiKolabApplicationCounts.fromJson(
          json['application_counts'] as Map<String, dynamic>?,
        ),
      );

  final String roleId;
  final String title;
  final int positionsNeeded;
  final int positionsFilled;
  final MultiKolabRoleStatus status;
  final MultiKolabApplicationCounts applicationCounts;
}

@immutable
class MultiKolabApplicationCounts {
  const MultiKolabApplicationCounts({
    this.pending = 0,
    this.shortlisted = 0,
    this.accepted = 0,
    this.declined = 0,
    this.withdrawn = 0,
  });

  factory MultiKolabApplicationCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MultiKolabApplicationCounts();
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return MultiKolabApplicationCounts(
      pending: asInt(json['pending']),
      shortlisted: asInt(json['shortlisted']),
      accepted: asInt(json['accepted']),
      declined: asInt(json['declined']),
      withdrawn: asInt(json['withdrawn']),
    );
  }

  final int pending;
  final int shortlisted;
  final int accepted;
  final int declined;
  final int withdrawn;
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
