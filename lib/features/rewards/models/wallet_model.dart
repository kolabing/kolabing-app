import 'package:flutter/foundation.dart';

import 'xp_level.dart';

/// XP-based reputation model for community users.
///
/// Maps the backend `points` field to [totalXp]. EUR/withdrawal fields
/// are kept only for the separate cash-referral withdrawal flow.
@immutable
class XpModel {
  const XpModel({
    required this.totalXp,
    this.redeemedPoints = 0,
    this.pendingWithdrawal = false,
  });

  factory XpModel.fromJson(Map<String, dynamic> json) => XpModel(
    totalXp: _parseInt(json['points']) ?? 0,
    redeemedPoints: _parseInt(json['redeemed_points']) ?? 0,
    pendingWithdrawal: json['pending_withdrawal'] == true,
  );

  /// Total XP earned (lifetime).
  final int totalXp;

  /// Points already redeemed via cash withdrawal.
  final int redeemedPoints;

  /// Whether a cash withdrawal request is currently pending.
  final bool pendingWithdrawal;

  // ---------------------------------------------------------------------------
  // XP / level derived values
  // ---------------------------------------------------------------------------

  XpLevel get level => XpLevel.fromXp(totalXp);

  int get xpToNextLevel => level.xpToNext(totalXp);

  double get levelProgress => level.progress(totalXp);

  // ---------------------------------------------------------------------------
  // Cash-withdrawal path only (separate from XP progression)
  // ---------------------------------------------------------------------------

  int get availablePoints => totalXp - redeemedPoints;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'XpModel(totalXp: $totalXp, level: ${level.title}, pending: $pendingWithdrawal)';
}

// Backwards-compatible alias so any lingering references compile.
typedef WalletModel = XpModel;
