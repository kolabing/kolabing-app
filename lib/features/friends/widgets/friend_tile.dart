import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/friend.dart';

/// A friend / candidate row: avatar, name, optional subtitle, and a trailing
/// action slot. Used by the friends list, the requests inbox, and the suggested
/// section so they share one visual language.
class FriendTile extends StatelessWidget {
  const FriendTile({
    required this.friend,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Friend friend;

  /// Optional secondary line (e.g. "3 shared events").
  final String? subtitle;

  /// Trailing action widget (the [FriendActionButton], accept/decline buttons,
  /// or a pending chip).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: KolabingColors.surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KolabingColors.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: KolabingColors.surfaceContainerHigh,
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? const Icon(LucideIcons.user, size: 20)
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: KolabingSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    ),
  );
}
