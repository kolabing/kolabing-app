import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';

/// Navigation item data model
class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
    this.showDot = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  final bool showDot;
}

/// Kolabing custom bottom navigation bar
///
/// A styled bottom navigation bar following the design system.
/// Supports numeric badges and dot indicators.
class KolabingBottomNavBar extends StatelessWidget {
  const KolabingBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    final color = isSelected
        ? KolabingColors.primary
        : isDark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF); // Gray-400
    final labelColor = isSelected
        ? (isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary)
        : isDark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: KolabingColors.primary.withValues(alpha: 0.1),
          highlightColor: KolabingColors.primary.withValues(alpha: 0.05),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
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
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
        color: KolabingColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: KolabingColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
          width: 2,
        ),
      ),
    );
  }
}
