import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/wallet_model.dart';
import 'points_progress_bar.dart';

/// A prominent yellow gradient card that displays the user's point balance,
/// EUR value, progress toward the withdrawal threshold, and an optional
/// withdraw button.
class PointsWalletCard extends StatelessWidget {
  const PointsWalletCard({
    required this.points,
    required this.onTap,
    this.onWithdraw,
    super.key,
  });

  /// Current available points.
  final int points;

  /// Called when the card body is tapped (navigate to wallet screen).
  final VoidCallback onTap;

  /// Called when the withdraw button is pressed.
  /// Pass `null` when the user has not yet reached the threshold — this hides
  /// the button and shows the "EUR XX to unlock" text instead.
  final VoidCallback? onWithdraw;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double get _eurValue => points * 0.20;

  bool get _canWithdraw => points >= WalletModel.withdrawalThreshold;

  double get _eurToUnlock =>
      ((WalletModel.withdrawalThreshold - points) * 0.20).clamp(0.0, double.infinity);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          decoration: BoxDecoration(
            gradient: KolabingColors.primaryGradient,
            borderRadius: KolabingRadius.borderRadiusLg,
            boxShadow: [
              BoxShadow(
                color: KolabingColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: KolabingSpacing.md),
              _buildPointsDisplay(),
              const SizedBox(height: KolabingSpacing.xs),
              _buildEurChip(),
              const SizedBox(height: KolabingSpacing.md),
              PointsProgressBar(
                currentPoints: points,
                darkMode: true,
              ),
              const SizedBox(height: KolabingSpacing.md),
              _buildBottomAction(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(
            LucideIcons.wallet,
            size: 18,
            color: Colors.black,
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            'YOUR WALLET',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.black.withValues(alpha: 0.60),
            ),
          ),
        ],
      );

  Widget _buildPointsDisplay() => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$points',
            style: GoogleFonts.rubik(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'POINTS',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: Colors.black.withValues(alpha: 0.50),
              ),
            ),
          ),
        ],
      );

  Widget _buildEurChip() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.10),
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Text(
          '\u20AC${_eurValue.toStringAsFixed(2)}',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      );

  Widget _buildBottomAction() {
    if (_canWithdraw && onWithdraw != null) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: onWithdraw,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: KolabingColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            elevation: 0,
          ),
          child: Text(
            'WITHDRAW',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    // Disabled state — show how much EUR is needed
    return Center(
      child: Text(
        '\u20AC${_eurToUnlock.toStringAsFixed(0)} to unlock withdrawal',
        style: GoogleFonts.openSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black.withValues(alpha: 0.50),
        ),
      ),
    );
  }
}
