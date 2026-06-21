// lib/features/dashboard/widgets/earn_xp_action_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Design tokens for mission cards
const _cardBg = Color(0xFFFFFFFF);
const _cardBorder = Color(0xFFEDE5D5);
const _inkDark = Color(0xFF19150F);
const _mutedText = Color(0xFF9A8F7C);
const _orangeAccent = Color(0xFFFF6114);
const _softOrangeTint = Color(0xFFFFE7D6); // XP pill fill
const _brandYellow = Color(0xFFFFE28C); // done pill text & icon
const _donePillBg = Color(0xFF19150F); // done pill background

/// A single XP mission row — compact, no icon block, orange/black pills.
///
/// Incomplete missions show a soft-orange "+N XP" reward pill.
/// Completed missions show a black "Done" pill with a yellow check.
/// All data wiring (title, description, xpReward, isDone, tap) is unchanged.
class EarnXpActionCard extends StatelessWidget {
  const EarnXpActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.xpReward,
    super.key,
    this.isDone = false,
  });

  // icon / iconBgColor kept for API compat — no longer rendered
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String description;
  final int xpReward;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _inkDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Reward / status pill
          _Pill(xpReward: xpReward, isDone: isDone),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.xpReward, required this.isDone});

  final int xpReward;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: const BoxDecoration(
          color: _donePillBg,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.check, size: 11, color: _brandYellow),
            const SizedBox(width: 4),
            Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _brandYellow,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: const BoxDecoration(
        color: _softOrangeTint,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        '+$xpReward XP',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _orangeAccent,
        ),
      ),
    );
  }
}
