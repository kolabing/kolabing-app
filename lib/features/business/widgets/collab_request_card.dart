import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/collab_request.dart';

/// Card widget for displaying a collaboration request in the explore list
///
/// Shows community info, collaboration details, tags, reward indicator,
/// and action buttons.
class CollabRequestCard extends StatelessWidget {
  const CollabRequestCard({
    required this.request,
    super.key,
    this.onView,
    this.onApply,
  });

  /// The collaboration request to display
  final CollabRequest request;

  /// Callback when the View button is tapped
  final VoidCallback? onView;

  /// Callback when the Apply button is tapped
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Username, Status
              _buildHeader(),
              const SizedBox(height: KolabingSpacing.sm),

              // Title
              Text(
                request.title,
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                request.description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: KolabingColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Tags row
              _buildTagsRow(),
              const SizedBox(height: KolabingSpacing.sm),

              // Reward indicator (if applicable)
              if (request.hasReward) ...[
                _buildRewardIndicator(),
                const SizedBox(height: KolabingSpacing.sm),
              ],

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          // Avatar
          _CommunityAvatar(
            avatarUrl: request.communityAvatarUrl,
            initial: request.communityInitial,
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Name and username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.communityName,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${request.communityUsername}',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status badge
          _StatusBadge(status: request.status),
        ],
      );

  Widget _buildTagsRow() {
    final dateFormat = DateFormat('MMM d');
    final dateText = request.endDate != null
        ? '${dateFormat.format(request.startDate)} - ${dateFormat.format(request.endDate!)}'
        : 'From ${dateFormat.format(request.startDate)}';

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        _TagPill(
          icon: LucideIcons.tag,
          label: request.collabType.displayName,
        ),
        _TagPill(
          icon: LucideIcons.mapPin,
          label: request.location,
        ),
        _TagPill(
          icon: LucideIcons.calendar,
          label: dateText,
        ),
      ],
    );
  }

  Widget _buildRewardIndicator() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.success.withValues(alpha: 0.1),
          borderRadius: KolabingRadius.borderRadiusSm,
          border: Border.all(
            color: KolabingColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.gift,
              size: 14,
              color: KolabingColors.activeText,
            ),
            const SizedBox(width: KolabingSpacing.xxs),
            Flexible(
              child: Text(
                request.rewardDescription ?? 'Reward included',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.activeText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons() => Row(
        children: [
          // View button (outlined)
          Expanded(
            child: OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(
                  color: KolabingColors.border,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'VIEW',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Apply button (primary)
          Expanded(
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'APPLY',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
}

/// Circular avatar for community with fallback initial
class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({
    required this.avatarUrl,
    required this.initial,
  });

  final String? avatarUrl;
  final String initial;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildInitial(),
                ),
              )
            : _buildInitial(),
      );

  Widget _buildInitial() => Center(
        child: Text(
          initial,
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
      );
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CollabStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status) {
      CollabStatus.active => (KolabingColors.activeBg, KolabingColors.activeText),
      CollabStatus.published =>
        (KolabingColors.pendingBg, KolabingColors.pendingText),
      CollabStatus.closed =>
        (KolabingColors.completedBg, KolabingColors.completedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Tag pill widget for type, location, date
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(width: KolabingSpacing.xxs),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}
