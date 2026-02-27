import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/challenge.dart';

/// Badge displaying challenge difficulty level
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showIcon = true,
  });

  final ChallengeDifficulty difficulty;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        bgColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        icon = LucideIcons.leaf;
      case ChallengeDifficulty.medium:
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        icon = LucideIcons.flame;
      case ChallengeDifficulty.hard:
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        icon = LucideIcons.zap;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            difficulty.label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
