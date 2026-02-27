import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/reward_claim.dart';

/// Card displaying a reward claim in the wallet
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.rewardClaim,
    this.onTap,
  });

  final RewardClaim rewardClaim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                size: 28,
                color: _getIconColor(),
              ),
            ),
            const SizedBox(width: KolabingSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardClaim.eventReward?.name ?? 'Mystery Reward',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Won ${_formatDate(rewardClaim.wonAt)}',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        color = KolabingColors.success;
        text = 'Available';
        break;
      case RewardClaimStatus.redeemed:
        color = KolabingColors.info;
        text = 'Redeemed';
        break;
      case RewardClaimStatus.expired:
        color = KolabingColors.error;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.rubik(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return KolabingColors.success.withValues(alpha: 0.3);
      case RewardClaimStatus.redeemed:
        return KolabingColors.border;
      case RewardClaimStatus.expired:
        return KolabingColors.error.withValues(alpha: 0.3);
    }
  }

  Color _getIconBackgroundColor() {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return KolabingColors.success.withValues(alpha: 0.1);
      case RewardClaimStatus.redeemed:
        return KolabingColors.info.withValues(alpha: 0.1);
      case RewardClaimStatus.expired:
        return KolabingColors.error.withValues(alpha: 0.1);
    }
  }

  Color _getIconColor() {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return KolabingColors.success;
      case RewardClaimStatus.redeemed:
        return KolabingColors.info;
      case RewardClaimStatus.expired:
        return KolabingColors.error;
    }
  }

  IconData _getIcon() {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return LucideIcons.gift;
      case RewardClaimStatus.redeemed:
        return LucideIcons.checkCircle;
      case RewardClaimStatus.expired:
        return LucideIcons.clock;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
