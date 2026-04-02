import 'package:flutter/foundation.dart';

/// Represents the user's points wallet with balance and withdrawal state.
@immutable
class WalletModel {
  const WalletModel({
    required this.points,
    required this.redeemedPoints,
    required this.pendingWithdrawal,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        points: _parseInt(json['points']) ?? 0,
        redeemedPoints: _parseInt(json['redeemed_points']) ?? 0,
        pendingWithdrawal: json['pending_withdrawal'] == true,
      );

  /// Total points earned.
  final int points;

  /// Points already redeemed / withdrawn.
  final int redeemedPoints;

  /// Whether a withdrawal request is currently pending.
  final bool pendingWithdrawal;

  // ---------------------------------------------------------------------------
  // Derived values
  // ---------------------------------------------------------------------------

  /// Points available for withdrawal.
  int get availablePoints => points - redeemedPoints;

  /// Estimated EUR value (1 point = 0.20 EUR).
  double get eurValue => availablePoints * 0.20;

  /// Progress toward the withdrawal threshold (0.0 - 1.0).
  double get progress => (availablePoints / withdrawalThreshold).clamp(0.0, 1.0);

  /// Whether the user can request a withdrawal right now.
  bool get canWithdraw => availablePoints >= withdrawalThreshold && !pendingWithdrawal;

  /// Minimum points required for a withdrawal (375 pts = 75 EUR).
  static const int withdrawalThreshold = 375;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'points': points,
        'redeemed_points': redeemedPoints,
        'pending_withdrawal': pendingWithdrawal,
      };

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  WalletModel copyWith({
    int? points,
    int? redeemedPoints,
    bool? pendingWithdrawal,
  }) =>
      WalletModel(
        points: points ?? this.points,
        redeemedPoints: redeemedPoints ?? this.redeemedPoints,
        pendingWithdrawal: pendingWithdrawal ?? this.pendingWithdrawal,
      );

  @override
  String toString() =>
      'WalletModel(points: $points, redeemed: $redeemedPoints, pending: $pendingWithdrawal)';

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
}
