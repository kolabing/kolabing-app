import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/utils/auth_scope_guard.dart';
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
  }) => WalletState(
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

class WalletNotifier extends Notifier<WalletState>
    with AuthScopeGuard<WalletState> {
  // Resolved lazily via a getter (NOT a `late final` assigned in build()):
  // Riverpod re-runs build() on the same Notifier instance when the provider
  // is invalidated (e.g. session_reset.dart on auth changes), and reassigning
  // a `late final` throws LateInitializationError — which puts the provider in
  // an error state and breaks every widget watching it.
  RewardsService get _service => ref.read(rewardsServiceProvider);

  @override
  WalletState build() {
    ref.listen<AuthState>(authProvider, (previous, next) {
      handleAuthStateChange(
        previous,
        next,
        clearSignedOutState: _clearSignedOutState,
        reloadAuthenticatedData: load,
      );
    });
    Future.microtask(() {
      return loadIfAuthenticated(
        clearSignedOutState: _clearSignedOutState,
        loadAuthenticatedData: load,
      );
    });
    return const WalletState();
  }

  void _clearSignedOutState() {
    state = const WalletState();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }

    final sessionVersion = activeAuthSessionVersion;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final walletFuture = _service.getWallet();
      final badgesFuture = _service.getBadges();
      final referralFuture = _service.getReferralCode();

      final wallet = await walletFuture;
      final badges = await badgesFuture;
      final referral = await referralFuture;
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }

      // Detect newly unlocked badges; skip on first load.
      final prevUnlocked = state.badges
          .where((b) => b.isUnlocked)
          .map((b) => b.slug)
          .toSet();
      final nowUnlocked = badges
          .where((b) => b.isUnlocked)
          .map((b) => b.slug)
          .toSet();
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
        newlyEarnedBadges: [...state.newlyEarnedBadges, ...newBadges],
      );
    } on ApiException catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.error.message);
    } on AuthException catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception catch (e) {
      if (isStaleAuthSession(sessionVersion)) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Ledger
  // ---------------------------------------------------------------------------

  Future<void> loadLedger({int page = 1}) async {
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return;
    }
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
    if (!ensureAuthenticatedUser(clearSignedOutState: _clearSignedOutState)) {
      return false;
    }
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

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

/// Convenience provider for lightweight consumers that only need the XP model.
final walletSummaryProvider = Provider<XpModel?>(
  (ref) => ref.watch(walletProvider).wallet,
);
