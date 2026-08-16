import 'package:flutter/foundation.dart';

/// Matches the frozen API contract §6 `creator_profile` shape exactly:
/// `{id, display_name, avatar_url}` — deliberately smaller than the app's
/// general profile summary models, mirroring the backend's
/// `MultiKolabCreatorSummaryResource`.
@immutable
class MultiKolabCreatorSummary {
  const MultiKolabCreatorSummary({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });

  factory MultiKolabCreatorSummary.fromJson(Map<String, dynamic> json) =>
      MultiKolabCreatorSummary(
        id: json['id']?.toString() ?? '',
        displayName: json['display_name']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
      );

  final String id;
  final String? displayName;
  final String? avatarUrl;
}

/// `{total, open, filled}` role_counts block, reused on the summary, detail,
/// and dashboard shapes.
@immutable
class MultiKolabRoleCounts {
  const MultiKolabRoleCounts({this.total = 0, this.open = 0, this.filled = 0});

  factory MultiKolabRoleCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MultiKolabRoleCounts();
    return MultiKolabRoleCounts(
      total: _asInt(json['total']) ?? 0,
      open: _asInt(json['open']) ?? 0,
      filled: _asInt(json['filled']) ?? 0,
    );
  }

  final int total;
  final int open;
  final int filled;
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
