import 'package:flutter/foundation.dart';

import 'multi_kolab_enums.dart';

/// Matches the frozen API contract §4 exactly.
@immutable
class MultiKolabRole {
  const MultiKolabRole({
    required this.id,
    required this.multiKolabEventId,
    required this.status,
    required this.title,
    required this.eligibleAccountType,
    required this.positionsNeeded,
    required this.positionsFilled,
    required this.required_,
    this.need,
    this.receive,
    this.compensationType,
    this.requirements,
    this.details,
    this.createdAt,
    this.updatedAt,
  });

  factory MultiKolabRole.fromJson(Map<String, dynamic> json) => MultiKolabRole(
    id: json['id']?.toString() ?? '',
    multiKolabEventId: json['multi_kolab_event_id']?.toString() ?? '',
    status: MultiKolabRoleStatus.fromApiValue(
      json['status']?.toString() ?? 'open',
    ),
    title: json['title']?.toString() ?? '',
    eligibleAccountType: MultiKolabEligibleAccountType.fromApiValue(
      json['eligible_account_type']?.toString() ?? 'either',
    ),
    positionsNeeded: _asInt(json['positions_needed']) ?? 1,
    positionsFilled: _asInt(json['positions_filled']) ?? 0,
    required_: json['required'] as bool? ?? true,
    need: json['need']?.toString(),
    receive: json['receive']?.toString(),
    compensationType: MultiKolabCompensationType.fromApiValue(
      json['compensation_type']?.toString(),
    ),
    requirements: json['requirements']?.toString(),
    details: json['details']?.toString(),
    createdAt: _asDateTime(json['created_at']),
    updatedAt: _asDateTime(json['updated_at']),
  );

  final String id;
  final String multiKolabEventId;
  final MultiKolabRoleStatus status;
  final String title;
  final MultiKolabEligibleAccountType eligibleAccountType;
  final int positionsNeeded;
  final int positionsFilled;

  /// Named with a trailing underscore — `required` is a Dart keyword.
  final bool required_;
  final String? need;
  final String? receive;
  final MultiKolabCompensationType? compensationType;
  final String? requirements;
  final String? details;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == MultiKolabRoleStatus.open;
  bool get isFilled => status == MultiKolabRoleStatus.filled;
  int get positionsRemaining =>
      (positionsNeeded - positionsFilled).clamp(0, positionsNeeded);
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _asDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
