import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Which visual direction to use for UI icons.
enum UiIconVariant {
  /// Version A — minimal: dark linework only, yellow used sparingly.
  minimal,

  /// Version B — expressive: yellow fills, purple accents, slightly richer.
  expressive,
}

/// Available UI icon slugs.
enum UiIconSlug {
  home,
  compass,
  briefcase,
  inbox,
  user,
  star,
  send,
  plus,
  gift,
  calendar,
  bell,
  checkCircle,
  clock,
  wallet,
  trophy,
  target,
  flame,
  emptyState,
  lock,
  award,
}

extension _UiIconSlugPath on UiIconSlug {
  String get filename {
    switch (this) {
      case UiIconSlug.home:
        return 'ui-home';
      case UiIconSlug.compass:
        return 'ui-compass';
      case UiIconSlug.briefcase:
        return 'ui-briefcase';
      case UiIconSlug.inbox:
        return 'ui-inbox';
      case UiIconSlug.user:
        return 'ui-user';
      case UiIconSlug.star:
        return 'ui-star';
      case UiIconSlug.send:
        return 'ui-send';
      case UiIconSlug.plus:
        return 'ui-plus';
      case UiIconSlug.gift:
        return 'ui-gift';
      case UiIconSlug.calendar:
        return 'ui-calendar';
      case UiIconSlug.bell:
        return 'ui-bell';
      case UiIconSlug.checkCircle:
        return 'ui-check-circle';
      case UiIconSlug.clock:
        return 'ui-clock';
      case UiIconSlug.wallet:
        return 'ui-wallet';
      case UiIconSlug.trophy:
        return 'ui-trophy';
      case UiIconSlug.target:
        return 'ui-target';
      case UiIconSlug.flame:
        return 'ui-flame';
      case UiIconSlug.emptyState:
        return 'ui-empty-state';
      case UiIconSlug.lock:
        return 'ui-lock';
      case UiIconSlug.award:
        return 'ui-award';
    }
  }

  String assetPath(UiIconVariant variant) {
    final dir = variant == UiIconVariant.minimal ? 'a' : 'b';
    return 'assets/icons/ui/$dir/$filename.svg';
  }
}

/// Renders a branded Kolabing UI icon as an SVG.
///
/// Use [variant] to switch between the minimal (A) and expressive (B) directions.
/// Defaults to [UiIconVariant.minimal].
///
/// Example:
/// ```dart
/// UiIcon(icon: UiIconSlug.gift, size: 24)
/// UiIcon(icon: UiIconSlug.trophy, size: 32, variant: UiIconVariant.expressive)
/// ```
class UiIcon extends StatelessWidget {
  const UiIcon({
    required this.icon,
    super.key,
    this.size = 24,
    this.variant = UiIconVariant.minimal,
    this.color,
  });

  final UiIconSlug icon;
  final double size;
  final UiIconVariant variant;

  /// Optional color override — applied as a ColorFilter.
  /// Useful for active/inactive nav states.
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        icon.assetPath(variant),
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      );
}
