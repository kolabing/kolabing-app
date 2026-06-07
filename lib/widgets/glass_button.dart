// lib/widgets/glass_button.dart
import 'dart:ui';

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
        GlassButtonIntent.primary => c.softYellow.withValues(alpha: 0.72),
        GlassButtonIntent.neutral =>
          c.surfaceContainerLow.withValues(alpha: 0.70),
        GlassButtonIntent.destructive =>
          c.glassDestructiveInk.withValues(alpha: 0.10),
      };

  Color _border(KolabingColorTokens c) => switch (intent) {
        GlassButtonIntent.primary => c.primaryDark.withValues(alpha: 0.55),
        GlassButtonIntent.neutral => c.outlineVariant.withValues(alpha: 0.80),
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
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label.toLowerCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: ink,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: _fill(c),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border(c)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A96781E),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.12],
                  colors: [
                    c.glassWhite14,
                    Colors.transparent,
                  ],
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
