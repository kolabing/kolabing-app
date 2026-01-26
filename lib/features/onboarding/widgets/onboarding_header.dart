import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import 'progress_indicator.dart';

/// Onboarding header with back, skip buttons and progress indicator
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    required this.currentStep,
    required this.onBack,
    super.key,
    this.totalSteps = 4,
    this.onSkip,
    this.showSkip = true,
  });

  /// Current step (1-based index)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  /// Callback when back button is pressed
  final VoidCallback onBack;

  /// Callback when skip button is pressed (null if skip not allowed)
  final VoidCallback? onSkip;

  /// Whether to show skip button
  final bool showSkip;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Top row with back and skip buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _BackButton(onPressed: onBack),

                // Skip button
                if (showSkip && onSkip != null)
                  _SkipButton(onPressed: onSkip!)
                else
                  const SizedBox(width: 60),
              ],
            ),
          ),

          // Step text
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Step $currentStep of $totalSteps',
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Progress indicator
          OnboardingProgressIndicator(
            currentStep: currentStep,
            totalSteps: totalSteps,
          ),
        ],
      );
}

/// Back button widget
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: KolabingColors.textPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Skip button widget
class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Skip',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),
        ),
      );
}
