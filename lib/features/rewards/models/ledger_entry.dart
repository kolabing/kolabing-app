import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

// =============================================================================
// Point Event Type
// =============================================================================

/// Types of XP events that can appear in the ledger.
enum PointEventType {
  collaborationComplete,
  firstKolabBonus,
  reviewPosted,
  ugcPosted,
  referralConversion,
  withdrawal;

  String get displayLabel {
    switch (this) {
      case PointEventType.collaborationComplete:
        return 'Collaboration Completed';
      case PointEventType.firstKolabBonus:
        return 'First Kolab Bonus! 🎉';
      case PointEventType.reviewPosted:
        return 'Review Posted';
      case PointEventType.ugcPosted:
        return 'Content Posted';
      case PointEventType.referralConversion:
        return 'Referral Bonus';
      case PointEventType.withdrawal:
        return 'Withdrawal';
    }
  }

  String toApiValue() {
    switch (this) {
      case PointEventType.collaborationComplete:
        return 'collaboration_complete';
      case PointEventType.firstKolabBonus:
        return 'first_kolab_bonus';
      case PointEventType.reviewPosted:
        return 'review_posted';
      case PointEventType.ugcPosted:
        return 'ugc_posted';
      case PointEventType.referralConversion:
        return 'referral_conversion';
      case PointEventType.withdrawal:
        return 'withdrawal';
    }
  }

  static PointEventType fromString(String value) {
    switch (value) {
      case 'collaboration_complete':
        return PointEventType.collaborationComplete;
      case 'first_kolab_bonus':
        return PointEventType.firstKolabBonus;
      case 'review_posted':
        return PointEventType.reviewPosted;
      case 'ugc_posted':
        return PointEventType.ugcPosted;
      // backend may send either; both map to referralConversion
      case 'referral_conversion':
      case 'referral_1m':
      case 'referral_4m':
        return PointEventType.referralConversion;
      case 'withdrawal':
        return PointEventType.withdrawal;
      default:
        return PointEventType.collaborationComplete;
    }
  }

  IconData get icon {
    switch (this) {
      case PointEventType.collaborationComplete:
        return LucideIcons.heartHandshake;
      case PointEventType.firstKolabBonus:
        return LucideIcons.trophy;
      case PointEventType.reviewPosted:
        return LucideIcons.star;
      case PointEventType.ugcPosted:
        return LucideIcons.camera;
      case PointEventType.referralConversion:
        return LucideIcons.userPlus;
      case PointEventType.withdrawal:
        return LucideIcons.arrowDownToLine;
    }
  }
}

// =============================================================================
// Ledger Entry
// =============================================================================

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

  final String id;
  final int points;
  final PointEventType eventType;
  final String description;
  final DateTime createdAt;

  bool get isEarned => points > 0;

  @override
  String toString() =>
      'LedgerEntry(id: $id, points: $points, type: ${eventType.toApiValue()})';

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
