import 'event_reward.dart';

/// Status of a reward claim
enum RewardClaimStatus {
  available,
  redeemed,
  expired;

  /// Parse status from string
  static RewardClaimStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return RewardClaimStatus.available;
      case 'redeemed':
        return RewardClaimStatus.redeemed;
      case 'expired':
        return RewardClaimStatus.expired;
      default:
        return RewardClaimStatus.available;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;

  /// Display label for UI
  String get label {
    switch (this) {
      case RewardClaimStatus.available:
        return 'Available';
      case RewardClaimStatus.redeemed:
        return 'Redeemed';
      case RewardClaimStatus.expired:
        return 'Expired';
    }
  }
}

/// Reward claim model - represents a won reward
class RewardClaim {
  const RewardClaim({
    required this.id,
    this.eventReward,
    required this.profileId,
    required this.status,
    required this.wonAt,
    this.redeemedAt,
    this.redeemToken,
    required this.createdAt,
  });

  factory RewardClaim.fromJson(Map<String, dynamic> json) {
    return RewardClaim(
      id: json['id'] as String,
      eventReward: json['event_reward'] != null
          ? EventReward.fromJson(json['event_reward'] as Map<String, dynamic>)
          : null,
      profileId: json['profile_id'] as String,
      status: RewardClaimStatus.fromString(json['status'] as String),
      wonAt: DateTime.parse(json['won_at'] as String),
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      redeemToken: json['redeem_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final EventReward? eventReward;
  final String profileId;
  final RewardClaimStatus status;
  final DateTime wonAt;
  final DateTime? redeemedAt;
  final String? redeemToken;
  final DateTime createdAt;

  /// Check if claim is available for redemption
  bool get isAvailable => status == RewardClaimStatus.available;

  /// Check if claim has been redeemed
  bool get isRedeemed => status == RewardClaimStatus.redeemed;

  /// Check if claim has expired
  bool get isExpired => status == RewardClaimStatus.expired;

  /// Check if claim has a redeem token generated
  bool get hasRedeemToken => redeemToken != null;

  /// Get the reward name (convenience getter)
  String get rewardName => eventReward?.name ?? 'Unknown Reward';

  Map<String, dynamic> toJson() => {
        'id': id,
        if (eventReward != null) 'event_reward': eventReward!.toJson(),
        'profile_id': profileId,
        'status': status.toApiValue(),
        'won_at': wonAt.toIso8601String(),
        if (redeemedAt != null) 'redeemed_at': redeemedAt!.toIso8601String(),
        if (redeemToken != null) 'redeem_token': redeemToken,
        'created_at': createdAt.toIso8601String(),
      };

  RewardClaim copyWith({
    String? id,
    EventReward? eventReward,
    String? profileId,
    RewardClaimStatus? status,
    DateTime? wonAt,
    DateTime? redeemedAt,
    String? redeemToken,
    DateTime? createdAt,
  }) =>
      RewardClaim(
        id: id ?? this.id,
        eventReward: eventReward ?? this.eventReward,
        profileId: profileId ?? this.profileId,
        status: status ?? this.status,
        wonAt: wonAt ?? this.wonAt,
        redeemedAt: redeemedAt ?? this.redeemedAt,
        redeemToken: redeemToken ?? this.redeemToken,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Result of a spin-the-wheel action
class SpinResult {
  const SpinResult({
    required this.won,
    this.rewardClaim,
  });

  factory SpinResult.fromJson(Map<String, dynamic> json) {
    return SpinResult(
      won: json['won'] as bool,
      rewardClaim: json['reward_claim'] != null
          ? RewardClaim.fromJson(json['reward_claim'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool won;
  final RewardClaim? rewardClaim;

  /// Check if the spin was a loss
  bool get lost => !won;
}
