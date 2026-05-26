import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/ledger_entry.dart';
import '../models/reward_badge.dart';
import '../providers/wallet_provider.dart';
import '../utils/xp_tier.dart';

/// XP & Badges hub screen for community users.
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
          'XP & REPUTATION',
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
            // 1 — XP Progress
            _buildXpCard(state),

            const SizedBox(height: KolabingSpacing.lg),

            // 2 — Ways to earn
            _buildSectionHeader('WAYS TO EARN XP'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildMissionsCard(),

            const SizedBox(height: KolabingSpacing.lg),

            // 3 — Badges
            _buildSectionHeader('BADGES'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildBadgesGrid(state),

            const SizedBox(height: KolabingSpacing.lg),

            // 4 — Cash referral milestone (separate from XP)
            _buildSectionHeader('CASH REFERRAL'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildReferralMilestoneCard(state),

            const SizedBox(height: KolabingSpacing.lg),

            // 5 — XP History
            _buildSectionHeader('XP HISTORY'),
            const SizedBox(height: KolabingSpacing.sm),
            _buildXpHistory(state),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1 — XP Progress Card
  // ---------------------------------------------------------------------------

  Widget _buildXpCard(WalletState state) {
    if (state.isLoading && state.wallet == null) {
      return Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: Container(
          height: 180,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points display
          Text(
            '${wallet.totalXp}',
            style: GoogleFonts.rubik(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: KolabingColors.onPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'XP POINTS',
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: KolabingColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Tier badge
          _buildTierBadge(wallet.totalXp),

          const SizedBox(height: KolabingSpacing.xs),

          // Tier progress bar
          _buildTierProgress(wallet.totalXp),

          const SizedBox(height: KolabingSpacing.xs),

          // Total XP label
          Text(
            'Total XP: ${wallet.totalXp}',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(int points) {
    final tier = XpTier.fromPoints(points);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.onPrimary.withValues(alpha: 0.2),
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        tier.displayName.toUpperCase(),
        style: GoogleFonts.rubik(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: KolabingColors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildTierProgress(int points) {
    final tier = XpTier.fromPoints(points);
    final progress = tier.progressFor(points);
    final nextThreshold = tier.nextThreshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: KolabingRadius.borderRadiusRound,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: KolabingColors.onPrimary.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(
              KolabingColors.onPrimary,
            ),
          ),
        ),
        if (nextThreshold != null) ...[
          const SizedBox(height: 4),
          Text(
            '$points / $nextThreshold XP to next tier',
            style: GoogleFonts.openSans(
              fontSize: 11,
              color: KolabingColors.onPrimary.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2 — Ways to Earn
  // ---------------------------------------------------------------------------

  Widget _buildMissionsCard() => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        _MissionRow(
          icon: LucideIcons.heartHandshake,
          label: 'Complete a collaboration',
          xp: '+10 XP',
        ),
        const Divider(height: KolabingSpacing.md),
        _MissionRow(
          icon: LucideIcons.star,
          label: 'Post a review',
          xp: '+10 XP',
        ),
        const Divider(height: KolabingSpacing.md),
        _MissionRow(
          icon: LucideIcons.camera,
          label: 'Share content (UGC)',
          xp: '+10 XP',
        ),
        const Divider(height: KolabingSpacing.md),
        _MissionRow(
          icon: LucideIcons.userPlus,
          label: 'Refer a business',
          xp: '+50 XP',
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // 3 — Badges
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
          childAspectRatio: 1.0,
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
      children: badges.map((b) => _BadgeCard(badge: b)).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 4 — Cash Referral Milestone
  // ---------------------------------------------------------------------------

  Widget _buildReferralMilestoneCard(WalletState state) {
    final conversions = state.referralConversions;
    final referralLink = state.referralLink;
    final referralCode = state.referralCode ?? '---';
    const goal = 3;
    final remaining = (goal - conversions).clamp(0, goal);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KolabingColors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
                child: Icon(LucideIcons.gift, size: 18),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earn €75 Cash',
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Refer 3 businesses on a 4-month plan',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Progress dots
          Row(
            children: List.generate(goal, (i) {
              final done = i < conversions;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < goal - 1 ? KolabingSpacing.xs : 0,
                  ),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: done
                          ? KolabingColors.primary
                          : KolabingColors.surfaceVariant,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: KolabingSpacing.xs),

          Text(
            conversions >= goal
                ? 'Milestone reached! Request your cash reward.'
                : '$conversions / $goal businesses referred · $remaining more to go',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textSecondary,
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Referral code
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: KolabingSpacing.sm,
              horizontal: KolabingSpacing.md,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(color: KolabingColors.softYellowBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralCode,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 18),
                  color: KolabingColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
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

          const SizedBox(height: KolabingSpacing.sm),

          // Share button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        referralLink != null || state.referralCode != null
                        ? () => Share.share(
                            referralLink ??
                                'Join Kolabing with my code: $referralCode',
                          )
                        : null,
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text('SHARE LINK', style: KolabingTextStyles.button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: KolabingRadius.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ),
              if (conversions >= goal) ...[
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push(KolabingRoutes.communityWalletWithdraw),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KolabingColors.textPrimary,
                        side: const BorderSide(
                          color: KolabingColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: KolabingRadius.borderRadiusMd,
                        ),
                      ),
                      child: Text(
                        'REQUEST €75',
                        style: KolabingTextStyles.button,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5 — XP History
  // ---------------------------------------------------------------------------

  Widget _buildXpHistory(WalletState state) {
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
      return _buildEmptyPlaceholder('No XP activity yet — complete a collab!');
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ledger.length,
          itemBuilder: (context, index) => _LedgerRow(entry: ledger[index]),
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
// Mission Row
// =============================================================================

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.icon,
    required this.label,
    required this.xp,
  });

  final IconData icon;
  final String label;
  final String xp;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: KolabingColors.activeBg,
          borderRadius: KolabingRadius.borderRadiusMd,
        ),
        child: Icon(icon, size: 18, color: KolabingColors.activeText),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(child: Text(label, style: KolabingTextStyles.bodyMedium)),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Text(
          xp,
          style: GoogleFonts.rubik(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

// =============================================================================
// Badge Card
// =============================================================================

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: isUnlocked ? KolabingColors.primary : KolabingColors.border,
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
          Text(
            isUnlocked ? badge.earnedDateFormatted : badge.slug.requirement,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: isUnlocked
                  ? KolabingColors.activeText
                  : KolabingColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Ledger Row
// =============================================================================

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description.isNotEmpty
                        ? entry.description
                        : entry.eventType.displayLabel,
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
                isEarned ? '+${entry.points} XP' : '${entry.points} XP',
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
