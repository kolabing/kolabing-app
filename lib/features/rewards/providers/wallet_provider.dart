import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger_entry.dart';
import '../models/reward_badge.dart';
import '../models/wallet_model.dart';
import '../services/rewards_service.dart';

// =============================================================================
// Wallet State
// =============================================================================

@immutable
class WalletState {
  const WalletState({
    this.wallet,
    this.ledger = const [],
    this.badges = const [],
    this.referralCode,
    this.referralLink,
    this.referralConversions = 0,
    this.isLoading = false,
    this.isWithdrawing = false,
    this.error,
    this.newlyEarnedBadges = const [],
  });

  final XpModel? wallet;
  final List<LedgerEntry> ledger;
  final List<RewardBadge> badges;
  final String? referralCode;
  final String? referralLink;

  /// Number of qualified business referral conversions (0/3 milestone display).
  final int referralConversions;

  final bool isLoading;
  final bool isWithdrawing;
  final String? error;

  /// Badge slugs newly earned since last clear (triggers celebration overlay).
  final List<RewardBadgeSlug> newlyEarnedBadges;

  WalletState copyWith({
    XpModel? wallet,
    List<LedgerEntry>? ledger,
    List<RewardBadge>? badges,
    String? referralCode,
    String? referralLink,
    int? referralConversions,
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
        referralConversions: referralConversions ?? this.referralConversions,
        isLoading: isLoading ?? this.isLoading,
        isWithdrawing: isWithdrawing ?? this.isWithdrawing,
        error: clearError ? null : (error ?? this.error),
        newlyEarnedBadges: newlyEarnedBadges ?? this.newlyEarnedBadges,
      );
}

// =============================================================================
// Wallet Notifier
// =============================================================================

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

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final walletFuture = _service.getWallet();
      final badgesFuture = _service.getBadges();
      final referralFuture = _service.getReferralCode();

      final wallet = await walletFuture;
      final badges = await badgesFuture;
      final referral = await referralFuture;

      // Detect newly unlocked badges; skip on first load.
      final prevUnlocked = state.badges
          .where((b) => b.isUnlocked)
          .map((b) => b.slug)
          .toSet();
      final nowUnlocked =
          badges.where((b) => b.isUnlocked).map((b) => b.slug).toSet();
      final newBadges = state.badges.isEmpty
          ? <RewardBadgeSlug>[]
          : nowUnlocked.difference(prevUnlocked).toList();

      state = state.copyWith(
        wallet: wallet,
        badges: badges,
        referralCode: referral.code,
        referralLink: referral.link,
        referralConversions: referral.totalConversions,
        isLoading: false,
        newlyEarnedBadges: [
          ...state.newlyEarnedBadges,
          ...newBadges,
        ],
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Ledger
  // ---------------------------------------------------------------------------

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
      await load();
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

  void clearNewBadges() {
    state = state.copyWith(newlyEarnedBadges: const []);
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  Future<void> refresh() => load();
}

// =============================================================================
// Providers
// =============================================================================

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

/// Convenience provider for lightweight consumers that only need the XP model.
final walletSummaryProvider = Provider<XpModel?>(
  (ref) => ref.watch(walletProvider).wallet,
);
