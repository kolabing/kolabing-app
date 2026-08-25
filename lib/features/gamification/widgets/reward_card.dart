import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/ui_icon.dart';
import '../models/reward_claim.dart';

/// Card displaying a reward claim in the wallet
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.rewardClaim, this.onTap});

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
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor(context), width: 1.5),
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
                color: _getIconBackgroundColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: _buildStatusIcon(context)),
            ),
            const SizedBox(width: KolabingSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardClaim.eventReward?.name ?? 'Mystery Reward',
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Won ${_formatDate(rewardClaim.wonAt)}',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            _buildStatusBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String text;

    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        color = context.colors.success;
        text = 'Available';
        break;
      case RewardClaimStatus.redeemed:
        color = context.colors.info;
        text = 'Redeemed';
        break;
      case RewardClaimStatus.expired:
        color = context.colors.error;
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
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getBorderColor(BuildContext context) {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return context.colors.success.withValues(alpha: 0.3);
      case RewardClaimStatus.redeemed:
        return context.colors.darkBorder;
      case RewardClaimStatus.expired:
        return context.colors.error.withValues(alpha: 0.3);
    }
  }

  Color _getIconBackgroundColor(BuildContext context) {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return context.colors.success.withValues(alpha: 0.1);
      case RewardClaimStatus.redeemed:
        return context.colors.info.withValues(alpha: 0.1);
      case RewardClaimStatus.expired:
        return context.colors.error.withValues(alpha: 0.1);
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return context.colors.success;
      case RewardClaimStatus.redeemed:
        return context.colors.info;
      case RewardClaimStatus.expired:
        return context.colors.error;
    }
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (rewardClaim.status) {
      case RewardClaimStatus.available:
        return const UiIcon(
          icon: UiIconSlug.gift,
          size: 28,
          variant: UiIconVariant.expressive,
        );
      case RewardClaimStatus.redeemed:
        return const UiIcon(
          icon: UiIconSlug.checkCircle,
          size: 28,
          variant: UiIconVariant.expressive,
        );
      case RewardClaimStatus.expired:
        return UiIcon(
          icon: UiIconSlug.clock,
          size: 28,
          color: _getIconColor(context),
        );
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
