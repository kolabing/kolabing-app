// lib/widgets/glass_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme/colors.dart';

enum GlassButtonIntent { primary, neutral, destructive }

class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.intent = GlassButtonIntent.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonIntent intent;
  final IconData? icon;

  Color _fill(KolabingColorTokens c) => switch (intent) {
        GlassButtonIntent.primary => c.softYellow,
        GlassButtonIntent.neutral => c.surfaceContainerLow,
        GlassButtonIntent.destructive =>
          c.glassDestructiveInk.withValues(alpha: 0.10),
      };

  Color _border(KolabingColorTokens c) => switch (intent) {
        GlassButtonIntent.primary => c.softYellowBorder,
        GlassButtonIntent.neutral => c.outlineVariant,
        GlassButtonIntent.destructive =>
          c.glassDestructiveInk.withValues(alpha: 0.35),
      };

  Color _ink(KolabingColorTokens c) => switch (intent) {
        GlassButtonIntent.primary || GlassButtonIntent.neutral => c.glassInk,
        GlassButtonIntent.destructive => c.glassDestructiveInk,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = _ink(c);

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        child: Container(
          height: 44,
          constraints: const BoxConstraints(minWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: _fill(c),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border(c)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: ink),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
