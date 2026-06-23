import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import '../ui_icon.dart';

/// Navigation item data model
class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
    this.showDot = false,
    this.iconSlug,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  final bool showDot;

  /// Optional UiIconSlug. When provided, [UiIcon] is rendered instead of
  /// the Lucide [icon]/[activeIcon] IconData.
  final UiIconSlug? iconSlug;
}

/// Kolabing custom bottom navigation bar
///
/// White background with rounded top corners. Each tab shows icon + label.
/// Active tab uses charcoal icon/label + short underline indicator.
class KolabingBottomNavBar extends StatelessWidget {
  const KolabingBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.navBarBackground,
        border: Border(
          top: BorderSide(color: context.colors.hairline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(
              items.length,
              (index) => _NavBarItem(
                item: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
                isDark: isDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isDark = false,
  });

  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isSelected ? context.colors.ink : context.colors.navInactive;
    final labelColor =
        isSelected ? context.colors.ink : context.colors.navInactive;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (item.iconSlug != null)
                    UiIcon(
                      icon: item.iconSlug!,
                      size: 22,
                      color: iconColor,
                    )
                  else
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: iconColor,
                      size: 22,
                    ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: _NumericBadge(count: item.badgeCount!),
                    ),
                  if (item.showDot && item.badgeCount == null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: _DotBadge(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label.toUpperCase(),
                  style: KolabingTextStyles.labelSmall.copyWith(
                    fontSize: 9,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: labelColor,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericBadge extends StatelessWidget {
  const _NumericBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DotBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: context.colors.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.navBarBackground,
          width: 1.5,
        ),
      ),
    );
  }
}
