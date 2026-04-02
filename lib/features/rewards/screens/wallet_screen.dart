import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/ledger_entry.dart';
import '../models/reward_badge.dart';
import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';

/// Wallet screen showing points balance, badges, referral code, and history.
///
/// Route: /community/wallet
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _ledgerPage = 1;
  bool _hasMoreLedger = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).loadLedger();
    });
  }

  Future<void> _loadMoreLedger() async {
    _ledgerPage++;
    final previousCount = ref.read(walletProvider).ledger.length;
    await ref.read(walletProvider.notifier).loadLedger(page: _ledgerPage);
    final newCount = ref.read(walletProvider).ledger.length;
    if (newCount == previousCount) {
      setState(() => _hasMoreLedger = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'MY WALLET',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 - Wallet Summary
            _buildWalletSummary(state),

            const SizedBox(height: KolabingSpacing.lg),

            // Section 2 - Badges
            _buildSectionHeader('BADGES'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildBadgesGrid(state),

            const SizedBox(height: KolabingSpacing.lg),

            // Section 3 - Refer & Earn
            _buildSectionHeader('REFER & EARN'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildReferralCard(state),

            const SizedBox(height: KolabingSpacing.lg),

            // Section 4 - Points History
            _buildSectionHeader('POINTS HISTORY'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildPointsHistory(state),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 - Wallet Summary
  // ---------------------------------------------------------------------------

  Widget _buildWalletSummary(WalletState state) {
    if (state.isLoading && state.wallet == null) {
      return Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KolabingRadius.borderRadiusLg,
          ),
        ),
      );
    }

    final wallet = state.wallet;
    if (wallet == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        gradient: KolabingColors.primaryGradient,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Points display
          Text(
            '${wallet.availablePoints}',
            style: GoogleFonts.rubik(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: KolabingColors.onPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'AVAILABLE POINTS',
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: KolabingColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // EUR value and progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EUR ${wallet.eurValue.toStringAsFixed(2)}',
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onPrimary,
                ),
              ),
              Text(
                '${wallet.availablePoints} / ${WalletModel.withdrawalThreshold} pts',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Progress bar
          ClipRRect(
            borderRadius: KolabingRadius.borderRadiusRound,
            child: LinearProgressIndicator(
              value: wallet.progress,
              minHeight: 8,
              backgroundColor: KolabingColors.onPrimary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                KolabingColors.onPrimary,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.sm),

          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (wallet.pendingWithdrawal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: KolabingSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: KolabingRadius.borderRadiusRound,
                  ),
                  child: Text(
                    'WITHDRAWAL PENDING',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: KolabingColors.onPrimary,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                'Total earned: ${wallet.points} pts',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 - Badges
  // ---------------------------------------------------------------------------

  Widget _buildBadgesGrid(WalletState state) {
    if (state.isLoading && state.badges.isEmpty) {
      return Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: KolabingSpacing.sm,
          crossAxisSpacing: KolabingSpacing.sm,
          childAspectRatio: 1.2,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KolabingRadius.borderRadiusLg,
              ),
            ),
          ),
        ),
      );
    }

    final badges = state.badges;
    if (badges.isEmpty) {
      return _buildEmptyPlaceholder('No badges available');
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: KolabingSpacing.sm,
      crossAxisSpacing: KolabingSpacing.sm,
      childAspectRatio: 1.0,
      children: badges.map((badge) => _RewardBadgeCard(badge: badge)).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3 - Refer & Earn
  // ---------------------------------------------------------------------------

  Widget _buildReferralCard(WalletState state) {
    final code = state.referralCode ?? '---';

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Referral code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: KolabingSpacing.md,
              horizontal: KolabingSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(color: KolabingColors.softYellowBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 20),
                  color: KolabingColors.textSecondary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Referral code copied'),
                        duration: Duration(seconds: 2),
                        backgroundColor: KolabingColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Share button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: state.referralCode != null
                  ? () {
                      // Share functionality placeholder; share_plus can be
                      // wired up once the import is desired.
                      Clipboard.setData(
                          ClipboardData(text: state.referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied to clipboard'),
                          backgroundColor: KolabingColors.success,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                'SHARE CODE',
                style: KolabingTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Tier explanation
          _buildTierRow(
            '1-month referral',
            '50 pts (EUR 10)',
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _buildTierRow(
            '4-month referral',
            '100 pts (EUR 20)',
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: KolabingColors.activeBg,
            borderRadius: KolabingRadius.borderRadiusRound,
          ),
          child: Text(
            value,
            style: KolabingTextStyles.labelSmall.copyWith(
              color: KolabingColors.activeText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

  // ---------------------------------------------------------------------------
  // Section 4 - Points History
  // ---------------------------------------------------------------------------

  Widget _buildPointsHistory(WalletState state) {
    final ledger = state.ledger;

    if (state.isLoading && ledger.isEmpty) {
      return Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (ledger.isEmpty) {
      return _buildEmptyPlaceholder('No points activity yet');
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ledger.length,
          itemBuilder: (context, index) =>
              _LedgerEntryRow(entry: ledger[index]),
        ),
        if (_hasMoreLedger)
          Padding(
            padding: const EdgeInsets.only(top: KolabingSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loadMoreLedger,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.textSecondary,
                  side: const BorderSide(color: KolabingColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'LOAD MORE',
                  style: KolabingTextStyles.buttonSmall.copyWith(
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title) => Text(
      title,
      style: GoogleFonts.rubik(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: KolabingColors.textSecondary,
      ),
    );

  Widget _buildEmptyPlaceholder(String message) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodyMedium.copyWith(
          color: KolabingColors.textTertiary,
        ),
      ),
    );
}

// =============================================================================
// Reward Badge Card (full detail)
// =============================================================================

class _RewardBadgeCard extends StatelessWidget {
  const _RewardBadgeCard({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isUnlocked ? KolabingColors.surface : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color:
              isUnlocked ? KolabingColors.primary : KolabingColors.border,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: KolabingColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? KolabingColors.primary.withValues(alpha: 0.15)
                  : KolabingColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.slug.icon,
              size: 24,
              color: isUnlocked
                  ? KolabingColors.primary
                  : KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Name
          Text(
            badge.slug.displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? KolabingColors.textPrimary
                  : KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),

          // Status or requirement
          if (isUnlocked)
            Text(
              badge.earnedDateFormatted,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.activeText,
              ),
            )
          else
            Text(
              badge.slug.requirement,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Ledger Entry Row
// =============================================================================

class _LedgerEntryRow extends StatelessWidget {
  const _LedgerEntryRow({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isEarned = entry.isEarned;

    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
        ),
        child: Row(
          children: [
            // Event type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isEarned
                    ? KolabingColors.activeBg
                    : KolabingColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                entry.eventType.icon,
                size: 16,
                color: isEarned
                    ? KolabingColors.activeText
                    : KolabingColors.errorText,
              ),
            ),

            const SizedBox(width: KolabingSpacing.sm),

            // Description and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: KolabingColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.createdAt),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: KolabingSpacing.sm),

            // Points chip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isEarned
                    ? KolabingColors.activeBg
                    : KolabingColors.errorBg,
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
              child: Text(
                isEarned ? '+${entry.points}' : '${entry.points}',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isEarned
                      ? KolabingColors.activeText
                      : KolabingColors.errorText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
