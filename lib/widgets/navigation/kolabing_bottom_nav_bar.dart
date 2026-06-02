import 'package:flutter/material.dart';

import '../../config/constants/radius.dart';
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
  /// the Lucide [icon]/[activeIcon] IconData, allowing custom SVG branding
  /// in the bottom nav while keeping backward compatibility.
  final UiIconSlug? iconSlug;
}

/// Kolabing custom bottom navigation bar
///
/// A styled bottom navigation bar following the design system.
/// Supports numeric badges and dot indicators.
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
        color: KolabingColors.navBarBackground,
        border: Border(
          top: BorderSide(
            color: KolabingColors.charcoal.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
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
    final iconColor = isSelected
        ? KolabingColors.navBarBackground
        : KolabingColors.navInactive;
    final labelColor = isSelected
        ? KolabingColors.navBarBackground
        : KolabingColors.navInactive;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 10 : 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? KolabingColors.charcoal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (item.iconSlug != null)
                        UiIcon(
                          icon: item.iconSlug!,
                          size: 20,
                          color: iconColor,
                        )
                      else
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: iconColor,
                          size: 20,
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
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label.toUpperCase(),
                          style: KolabingTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: KolabingColors.charcoal,
        shape: BoxShape.circle,
        border: Border.all(
          color: KolabingColors.navBarBackground,
          width: 2,
        ),
      ),
    );
  }
}
