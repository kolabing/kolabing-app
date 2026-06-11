import 'package:flutter/material.dart';

import '../../config/constants/layout.dart';
import '../../config/constants/radius.dart';
import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';

/// White content card — the default surface for opportunity, collaboration,
/// and review-style cards. Mirrors the Explore / My Kolabs card shell: white
/// fill, hairline border, radius 16, soft ambient shadow.
class PrimaryContentCard extends StatelessWidget {
  const PrimaryContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KolabingSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline),
        boxShadow: [KolabingShadows.card],
      ),
      child: child,
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

/// White compact row card — for member/roster rows, chat threads, upcoming
/// collaboration rows, and XP action rows. Radius 12, hairline border, less
/// vertical padding than [PrimaryContentCard].
class CompactListCard extends StatelessWidget {
  const CompactListCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.sm,
    ),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: context.colors.hairline);
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: border,
        ),
        child: child,
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: KolabingRadius.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusMd,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: KolabingRadius.borderRadiusMd,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// White empty-state container — replaces bare floating text / icon columns
/// on a cream background. Soft beige (hairline) border, radius 16, optional
/// icon tile, title, helper text, and an optional CTA.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline),
        boxShadow: [KolabingShadows.card],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.softYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.md),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyLarge
                .copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: KolabingSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
