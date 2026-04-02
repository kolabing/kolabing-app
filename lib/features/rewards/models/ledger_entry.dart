import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

// =============================================================================
// Point Event Type
// =============================================================================

/// Types of point events that can appear in the ledger.
enum PointEventType {
  collaborationComplete,
  reviewPosted,
  ugcPosted,
  referral1m,
  referral4m,
  withdrawal;

  /// Human-readable label for display.
  String get displayLabel {
    switch (this) {
      case PointEventType.collaborationComplete:
        return 'Collaboration Completed';
      case PointEventType.reviewPosted:
        return 'Review Posted';
      case PointEventType.ugcPosted:
        return 'UGC Posted';
      case PointEventType.referral1m:
        return 'Referral (1 month)';
      case PointEventType.referral4m:
        return 'Referral (4 months)';
      case PointEventType.withdrawal:
        return 'Withdrawal';
    }
  }

  /// Snake-case value used for API serialization.
  String toApiValue() {
    switch (this) {
      case PointEventType.collaborationComplete:
        return 'collaboration_complete';
      case PointEventType.reviewPosted:
        return 'review_posted';
      case PointEventType.ugcPosted:
        return 'ugc_posted';
      case PointEventType.referral1m:
        return 'referral_1m';
      case PointEventType.referral4m:
        return 'referral_4m';
      case PointEventType.withdrawal:
        return 'withdrawal';
    }
  }

  /// Parse an API string back to the enum value.
  static PointEventType fromString(String value) {
    switch (value) {
      case 'collaboration_complete':
        return PointEventType.collaborationComplete;
      case 'review_posted':
        return PointEventType.reviewPosted;
      case 'ugc_posted':
        return PointEventType.ugcPosted;
      case 'referral_1m':
        return PointEventType.referral1m;
      case 'referral_4m':
        return PointEventType.referral4m;
      case 'withdrawal':
        return PointEventType.withdrawal;
      default:
        return PointEventType.collaborationComplete;
    }
  }

  /// Icon representing this event type.
  IconData get icon {
    switch (this) {
      case PointEventType.collaborationComplete:
        return LucideIcons.heartHandshake;
      case PointEventType.reviewPosted:
        return LucideIcons.star;
      case PointEventType.ugcPosted:
        return LucideIcons.camera;
      case PointEventType.referral1m:
        return LucideIcons.userPlus;
      case PointEventType.referral4m:
        return LucideIcons.userPlus;
      case PointEventType.withdrawal:
        return LucideIcons.arrowDownToLine;
    }
  }
}

// =============================================================================
// Ledger Entry
// =============================================================================

/// A single entry in the user's points ledger (earned or spent).
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.points,
    required this.eventType,
    required this.description,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id']?.toString() ?? '',
        points: _parseInt(json['points']) ?? 0,
        eventType: PointEventType.fromString(
            json['event_type']?.toString() ?? 'collaboration_complete'),
        description: json['description']?.toString() ?? '',
        createdAt: _parseDateTime(json['created_at']),
      );

  /// Unique identifier.
  final String id;

  /// Points earned (positive) or spent (negative).
  final int points;

  /// Type of event that triggered this entry.
  final PointEventType eventType;

  /// Human-readable description.
  final String description;

  /// When this entry was created.
  final DateTime createdAt;

  /// Whether this entry represents earned points (positive value).
  bool get isEarned => points > 0;

  @override
  String toString() =>
      'LedgerEntry(id: $id, points: $points, type: ${eventType.toApiValue()})';

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
