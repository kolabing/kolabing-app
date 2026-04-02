import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_entry.dart';
import '../models/reward_badge.dart';
import '../models/wallet_model.dart';
import '../services/rewards_service.dart';

// =============================================================================
// Wallet State
// =============================================================================

/// Aggregate state for the rewards wallet, ledger, badges, and referral.
@immutable
class WalletState {
  const WalletState({
    this.wallet,
    this.ledger = const [],
    this.badges = const [],
    this.referralCode,
    this.referralLink,
    this.isLoading = false,
    this.isWithdrawing = false,
    this.error,
    this.newlyEarnedBadges = const [],
  });

  /// Current wallet balance information.
  final WalletModel? wallet;

  /// Paginated list of ledger entries.
  final List<LedgerEntry> ledger;

  /// All reward badges with unlock status.
  final List<RewardBadge> badges;

  /// The user's referral code.
  final String? referralCode;

  /// The full referral link from backend.
  final String? referralLink;

  /// Whether the initial data load is in progress.
  final bool isLoading;

  /// Whether a withdrawal request is in progress.
  final bool isWithdrawing;

  /// Error message from the last failed operation, if any.
  final String? error;

  /// Badge slugs that were newly earned (triggers celebration overlay).
  final List<RewardBadgeSlug> newlyEarnedBadges;

  WalletState copyWith({
    WalletModel? wallet,
    List<LedgerEntry>? ledger,
    List<RewardBadge>? badges,
    String? referralCode,
    String? referralLink,
    bool? isLoading,
    bool? isWithdrawing,
    String? error,
    List<RewardBadgeSlug>? newlyEarnedBadges,
    bool clearError = false,
  }) =>
      WalletState(
        wallet: wallet ?? this.wallet,
        ledger: ledger ?? this.ledger,
        badges: badges ?? this.badges,
        referralCode: referralCode ?? this.referralCode,
        referralLink: referralLink ?? this.referralLink,
        isLoading: isLoading ?? this.isLoading,
        isWithdrawing: isWithdrawing ?? this.isWithdrawing,
        error: clearError ? null : (error ?? this.error),
        newlyEarnedBadges: newlyEarnedBadges ?? this.newlyEarnedBadges,
      );
}

// =============================================================================
// Wallet Notifier
// =============================================================================

/// Manages all rewards state: wallet, badges, referral code, and withdrawals.
class WalletNotifier extends Notifier<WalletState> {
  late final RewardsService _service;

  @override
  WalletState build() {
    _service = ref.read(rewardsServiceProvider);
    Future.microtask(load);
    return const WalletState();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Fetch wallet, badges, and referral code in parallel.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final walletFuture = _service.getWallet();
      final badgesFuture = _service.getBadges();
      final referralFuture = _service.getReferralCode();

      final wallet = await walletFuture;
      final badges = await badgesFuture;
      final referral = await referralFuture;

      state = state.copyWith(
        wallet: wallet,
        badges: badges,
        referralCode: referral.code,
        referralLink: referral.link,
        isLoading: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Ledger
  // ---------------------------------------------------------------------------

  /// Load the next page of ledger entries (appended to existing list).
  Future<void> loadLedger({int page = 1}) async {
    try {
      final entries = await _service.getLedger(page: page);
      state = state.copyWith(ledger: [...state.ledger, ...entries]);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Withdrawal
  // ---------------------------------------------------------------------------

  /// Request a withdrawal. Returns `true` on success.
  Future<bool> requestWithdrawal({
    required String iban,
    required String accountHolder,
  }) async {
    state = state.copyWith(isWithdrawing: true, clearError: true);
    try {
      await _service.requestWithdrawal(
        iban: iban,
        accountHolder: accountHolder,
      );
      await load(); // refresh wallet after successful withdrawal
      state = state.copyWith(isWithdrawing: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isWithdrawing: false, error: e.toString());
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Badges
  // ---------------------------------------------------------------------------

  /// Clear the newly-earned badges list (after celebration is shown).
  void clearNewBadges() {
    state = state.copyWith(newlyEarnedBadges: const []);
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  /// Convenience alias for [load].
  Future<void> refresh() => load();
}

// =============================================================================
// Providers
// =============================================================================

/// Main wallet provider containing all rewards state.
final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

/// Convenience provider that extracts just the wallet model for lightweight
/// consumers (dashboard cards, etc.).
final walletSummaryProvider = Provider<WalletModel?>(
  (ref) => ref.watch(walletProvider).wallet,
);
