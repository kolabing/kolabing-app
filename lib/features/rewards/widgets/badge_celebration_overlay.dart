import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/reward_badge.dart';

/// A full-screen overlay that celebrates a newly-unlocked badge with confetti,
/// an animated icon, and a dismiss CTA.
///
/// This is shown as an [OverlayEntry], **not** as a route. Use the static
/// [BadgeCelebrationOverlay.show] method to display it.
class BadgeCelebrationOverlay extends StatefulWidget {
  const BadgeCelebrationOverlay({
    required this.badge,
    required this.onDismiss,
    super.key,
  });

  /// The badge that was just unlocked.
  final RewardBadge badge;

  /// Called when the user dismisses the overlay (tap scrim or CTA button).
  final VoidCallback onDismiss;

  // ---------------------------------------------------------------------------
  // Static show helper
  // ---------------------------------------------------------------------------

  /// Inserts the celebration overlay into the nearest [Overlay].
  ///
  /// Returns the [OverlayEntry] so callers can remove it manually if needed,
  /// although it removes itself when [onDismiss] fires.
  static OverlayEntry show(
    BuildContext context,
    RewardBadge badge,
    VoidCallback onDismiss,
  ) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BadgeCelebrationOverlay(
        badge: badge,
        onDismiss: () {
          entry.remove();
          onDismiss();
        },
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<BadgeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Scale animation for the badge icon (spring curve, 400ms)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Kick off animations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Black scrim — tap to dismiss
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black.withValues(alpha: 0.70),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated badge icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: KolabingColors.softYellow,
                      ),
                      child: Icon(
                        widget.badge.slug.icon,
                        size: 44,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // "New Badge Unlocked!"
                  Text(
                    'New Badge Unlocked!',
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.xs),

                  // Badge display name
                  Text(
                    widget.badge.slug.displayName,
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.primary,
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.xs),

                  // Badge description
                  Text(
                    widget.badge.slug.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KolabingColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: KolabingRadius.borderRadiusMd,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'SEE MY BADGES',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti burst from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 15,
              minBlastForce: 5,
              numberOfParticles: 25,
              gravity: 0.15,
              emissionFrequency: 0.06,
              colors: const [
                KolabingColors.primary,
                KolabingColors.success,
                Color(0xFFFF6B6B),
                Color(0xFF6BC5FF),
                Color(0xFFFFE082),
              ],
            ),
          ),
        ],
      ),
    );
}
