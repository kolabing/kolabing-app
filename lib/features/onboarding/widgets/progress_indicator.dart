import 'package:flutter/material.dart';

import '../../../config/theme/colors.dart';

/// Onboarding progress indicator widget
///
/// Shows the current step progress with circles and lines.
/// Active steps are highlighted in yellow.
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.currentStep,
    super.key,
    this.totalSteps = 4,
  });

  /// Current step (1-based index)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalSteps * 2 - 1,
            (index) {
              // Even indices are circles, odd indices are lines
              if (index.isEven) {
                final stepNumber = (index ~/ 2) + 1;
                return _buildCircle(stepNumber);
              } else {
                final stepNumber = (index ~/ 2) + 1;
                return _buildLine(stepNumber);
              }
            },
          ),
        ),
      );

  Widget _buildCircle(int stepNumber) {
    final isActive = stepNumber <= currentStep;
    final isCompleted = stepNumber < currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? KolabingColors.primary : KolabingColors.border,
        border: Border.all(
          color: isActive ? KolabingColors.primary : KolabingColors.border,
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(
              Icons.check,
              size: 8,
              color: KolabingColors.onPrimary,
            )
          : null,
    );
  }

  Widget _buildLine(int stepBeforeNumber) {
    final isActive = stepBeforeNumber < currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? KolabingColors.primary : KolabingColors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
