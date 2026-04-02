import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// Animated step indicator for the Kolab creation flow.
///
/// Displays a row of dots representing each step. The active step is shown as a
/// larger filled circle, completed steps are filled and tappable, and inactive
/// steps show only a border outline.
class KolabStepIndicator extends StatelessWidget {
  const KolabStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.onStepTap,
  });

  /// The zero-based index of the currently active step.
  final int currentStep;

  /// Total number of steps in the flow.
  final int totalSteps;

  /// Called when a completed step dot is tapped with the step index.
  final void Function(int)? onStepTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.xxs,
            ),
            child: GestureDetector(
              onTap: isCompleted && onStepTap != null
                  ? () => onStepTap!(index)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isActive ? 10 : 8,
                height: isActive ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isCompleted
                      ? KolabingColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? KolabingColors.primary
                        : KolabingColors.border,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          );
        }),
      );
}
