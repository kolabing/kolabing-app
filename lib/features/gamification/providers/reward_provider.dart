import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/event_reward.dart';
import '../models/reward_claim.dart';
import '../services/reward_service.dart';

/// Provider for RewardService
final rewardServiceProvider = Provider<RewardService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return RewardService(authService: authService);
});

// =============================================================================
// Event Rewards Provider (Organizer)
// =============================================================================

/// Provider for event rewards list
final eventRewardsProvider =
    FutureProvider.family<List<EventReward>, String>((ref, eventId) async {
  final service = ref.watch(rewardServiceProvider);
  return service.getEventRewards(eventId);
});

// =============================================================================
// Create Reward
// =============================================================================

/// Helper function to create a reward
Future<EventReward> createReward(
  WidgetRef ref,
  String eventId, {
  required String name,
  String? description,
  required int totalQuantity,
  required double probability,
  DateTime? expiresAt,
}) async {
  final service = ref.read(rewardServiceProvider);
  final reward = await service.createReward(
    eventId,
    name: name,
    description: description,
    totalQuantity: totalQuantity,
    probability: probability,
    expiresAt: expiresAt,
  );
  ref.invalidate(eventRewardsProvider(eventId));
  return reward;
}

/// Helper function to update a reward
Future<EventReward> updateReward(
  WidgetRef ref,
  String rewardId, {
  String? eventId,
  String? name,
  String? description,
  int? totalQuantity,
  double? probability,
  DateTime? expiresAt,
}) async {
  final service = ref.read(rewardServiceProvider);
  final reward = await service.updateReward(
    rewardId,
    name: name,
    description: description,
    totalQuantity: totalQuantity,
    probability: probability,
    expiresAt: expiresAt,
  );
  if (eventId != null) {
    ref.invalidate(eventRewardsProvider(eventId));
  }
  return reward;
}

/// Helper function to delete a reward
Future<void> deleteReward(
  WidgetRef ref,
  String rewardId,
  String eventId,
) async {
  final service = ref.read(rewardServiceProvider);
  await service.deleteReward(rewardId);
  ref.invalidate(eventRewardsProvider(eventId));
}

// =============================================================================
// Spin Provider
// =============================================================================

/// State for spin operation
class SpinState {
  const SpinState({
    this.result,
    this.isLoading = false,
    this.error,
    this.isComplete = false,
  });

  final SpinResult? result;
  final bool isLoading;
  final String? error;
  final bool isComplete;

  SpinState copyWith({
    SpinResult? result,
    bool? isLoading,
    String? error,
    bool? isComplete,
  }) =>
      SpinState(
        result: result ?? this.result,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isComplete: isComplete ?? this.isComplete,
      );
}

/// Notifier for spin operation
class SpinNotifier extends Notifier<SpinState> {
  @override
  SpinState build() => const SpinState();

  RewardService get _service => ref.read(rewardServiceProvider);

  Future<SpinResult?> spin(String challengeCompletionId) async {
    state = state.copyWith(isLoading: true, error: null, isComplete: false);

    try {
      final result = await _service.spin(challengeCompletionId);
      state = SpinState(result: result, isComplete: true);
      // Refresh wallet after spin
      ref.invalidate(myRewardsProvider);
      return result;
    } on RewardException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to spin');
      return null;
    }
  }

  void reset() {
    state = const SpinState();
  }
}

/// Provider for spin operation
final spinProvider = NotifierProvider<SpinNotifier, SpinState>(
  SpinNotifier.new,
);

// =============================================================================
// Reward Wallet Provider
// =============================================================================

/// Provider for user's reward wallet
final myRewardsProvider = FutureProvider<RewardWalletResponse>((ref) async {
  final service = ref.watch(rewardServiceProvider);
  return service.getMyRewards();
});

/// Provider for paginated rewards
final myRewardsPaginatedProvider =
    FutureProvider.family<RewardWalletResponse, ({int page, int limit})>(
        (ref, params) async {
  final service = ref.watch(rewardServiceProvider);
  return service.getMyRewards(page: params.page, limit: params.limit);
});

// =============================================================================
// Redeem QR Provider
// =============================================================================

/// State for redeem QR operation
class RedeemQRState {
  const RedeemQRState({
    this.rewardClaim,
    this.isLoading = false,
    this.error,
    this.isGenerated = false,
  });

  final RewardClaim? rewardClaim;
  final bool isLoading;
  final String? error;
  final bool isGenerated;

  RedeemQRState copyWith({
    RewardClaim? rewardClaim,
    bool? isLoading,
    String? error,
    bool? isGenerated,
  }) =>
      RedeemQRState(
        rewardClaim: rewardClaim ?? this.rewardClaim,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isGenerated: isGenerated ?? this.isGenerated,
      );
}

/// Notifier for generating redeem QR
class RedeemQRNotifier extends Notifier<RedeemQRState> {
  @override
  RedeemQRState build() => const RedeemQRState();

  RewardService get _service => ref.read(rewardServiceProvider);

  Future<RewardClaim?> generateQR(String rewardClaimId) async {
    state = state.copyWith(isLoading: true, error: null, isGenerated: false);

    try {
      final claim = await _service.generateRedeemQR(rewardClaimId);
      state = RedeemQRState(rewardClaim: claim, isGenerated: true);
      return claim;
    } on RewardException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate QR');
      return null;
    }
  }

  void reset() {
    state = const RedeemQRState();
  }
}

/// Provider for redeem QR generation
final redeemQRProvider = NotifierProvider<RedeemQRNotifier, RedeemQRState>(
  RedeemQRNotifier.new,
);

// =============================================================================
// Confirm Redeem Provider (Organizer)
// =============================================================================

/// State for confirm redeem operation
class ConfirmRedeemState {
  const ConfirmRedeemState({
    this.rewardClaim,
    this.isLoading = false,
    this.error,
    this.isConfirmed = false,
  });

  final RewardClaim? rewardClaim;
  final bool isLoading;
  final String? error;
  final bool isConfirmed;

  ConfirmRedeemState copyWith({
    RewardClaim? rewardClaim,
    bool? isLoading,
    String? error,
    bool? isConfirmed,
  }) =>
      ConfirmRedeemState(
        rewardClaim: rewardClaim ?? this.rewardClaim,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isConfirmed: isConfirmed ?? this.isConfirmed,
      );
}

/// Notifier for confirming redemption (organizer scans QR)
class ConfirmRedeemNotifier extends Notifier<ConfirmRedeemState> {
  @override
  ConfirmRedeemState build() => const ConfirmRedeemState();

  RewardService get _service => ref.read(rewardServiceProvider);

  Future<RewardClaim?> confirmRedeem(String redeemToken) async {
    state = state.copyWith(isLoading: true, error: null, isConfirmed: false);

    try {
      final claim = await _service.confirmRedeem(redeemToken);
      state = ConfirmRedeemState(rewardClaim: claim, isConfirmed: true);
      return claim;
    } on RewardException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to confirm redemption');
      return null;
    }
  }

  void reset() {
    state = const ConfirmRedeemState();
  }
}

/// Provider for confirm redeem operation
final confirmRedeemProvider =
    NotifierProvider<ConfirmRedeemNotifier, ConfirmRedeemState>(
  ConfirmRedeemNotifier.new,
);
