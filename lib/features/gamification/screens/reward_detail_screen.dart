import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/reward_claim.dart';
import '../providers/reward_provider.dart';

/// Screen showing reward details with QR code for redemption
class RewardDetailScreen extends ConsumerWidget {
  const RewardDetailScreen({
    super.key,
    required this.rewardClaimId,
    this.initialReward,
  });

  final String rewardClaimId;
  final RewardClaim? initialReward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redeemState = ref.watch(redeemQRProvider);
    final reward = redeemState.rewardClaim ?? initialReward;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reward Details',
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: reward == null
          ? Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reward Info Card
                  _buildRewardInfoCard(reward),
                  const SizedBox(height: KolabingSpacing.lg),

                  // Status Badge
                  _buildStatusBadge(reward),
                  const SizedBox(height: KolabingSpacing.lg),

                  // QR Code Section
                  if (reward.status == RewardClaimStatus.available)
                    _buildQRSection(context, ref, reward, redeemState),

                  // Redeemed Info
                  if (reward.status == RewardClaimStatus.redeemed)
                    _buildRedeemedInfo(reward),

                  // Expired Info
                  if (reward.status == RewardClaimStatus.expired)
                    _buildExpiredInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildRewardInfoCard(RewardClaim reward) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reward Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.gift,
              size: 40,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Reward Name
          Text(
            reward.eventReward?.name ?? 'Mystery Reward',
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          // Description
          if (reward.eventReward?.description != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              reward.eventReward!.description!,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: KolabingSpacing.md),

          // Won Date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Won on ${_formatDate(reward.wonAt)}',
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),

          // Expiry
          if (reward.eventReward?.expiresAt != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: reward.status == RewardClaimStatus.expired
                      ? context.colors.error
                      : context.colors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  reward.status == RewardClaimStatus.expired
                      ? 'Expired on ${_formatDate(reward.eventReward!.expiresAt!)}'
                      : 'Expires on ${_formatDate(reward.eventReward!.expiresAt!)}',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: reward.status == RewardClaimStatus.expired
                        ? context.colors.error
                        : context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RewardClaim reward) {
    Color badgeColor;
    IconData icon;
    String text;

    switch (reward.status) {
      case RewardClaimStatus.available:
        badgeColor = context.colors.success;
        icon = LucideIcons.checkCircle;
        text = 'Available to Redeem';
        break;
      case RewardClaimStatus.redeemed:
        badgeColor = context.colors.info;
        icon = LucideIcons.checkCheck;
        text = 'Redeemed';
        break;
      case RewardClaimStatus.expired:
        badgeColor = context.colors.error;
        icon = LucideIcons.xCircle;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: badgeColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(
    BuildContext context,
    WidgetRef ref,
    RewardClaim reward,
    RedeemQRState state,
  ) {
    if (state.isGenerated && state.rewardClaim?.redeemToken != null) {
      return _buildQRCode(state.rewardClaim!.redeemToken!);
    }

    return Column(
      children: [
        Text(
          'Show this QR code to the organizer to redeem your reward',
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: KolabingSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () async {
                    await ref
                        .read(redeemQRProvider.notifier)
                        .generateQR(rewardClaimId);
                  },
            icon: state.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onPrimary,
                    ),
                  )
                : const Icon(LucideIcons.qrCode),
            label: Text(state.isLoading ? 'Generating...' : 'Generate QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            state.error!,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildQRCode(String token) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Show this QR code to the organizer',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: context.colors.onSurface,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'This QR code expires in 5 minutes',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemedInfo(RewardClaim reward) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.checkCircle2,
            size: 48,
            color: context.colors.info,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            'This reward has been redeemed',
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.info,
            ),
          ),
          if (reward.redeemedAt != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              'Redeemed on ${_formatDate(reward.redeemedAt!)}',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiredInfo() {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.xCircle,
            size: 48,
            color: context.colors.error,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            'This reward has expired',
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.error,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Rewards must be redeemed before their expiration date',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
