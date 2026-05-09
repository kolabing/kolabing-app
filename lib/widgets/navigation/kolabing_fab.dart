import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme/colors.dart';

/// Kolabing floating action button
///
/// A styled FAB following the design system.
/// Used for primary create actions.
class KolabingFAB extends StatelessWidget {
  const KolabingFAB({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.tooltip,
    this.heroTag,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: heroTag ?? 'kolabing_fab',
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onPrimary,
        shape: const CircleBorder(),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

/// Extended version of the FAB with a label
class KolabingExtendedFAB extends StatelessWidget {
  const KolabingExtendedFAB({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = LucideIcons.plus,
    this.heroTag,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        heroTag: heroTag ?? 'kolabing_extended_fab',
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onPrimary,
        icon: Icon(icon, size: 20),
        label: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
