import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/category_icon.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

/// Step 1 (venue / product flows): "WHAT DO YOU WANT THIS KOLAB TO ACHIEVE?"
///
/// Single-select goal chip list, admin-managed via /lookup/goals. Helps
/// communities understand the opportunity and is shown as a badge on Review.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(kolabFormProvider);
    final notifier = ref.read(kolabFormProvider.notifier);
    final goalOptionsAsync = ref.watch(goalsProvider);
    final selectedGoal = formState.kolab.goal;
    final errors = formState.fieldErrors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        Text(
          'GOAL',
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'What do you want this Kolab to achieve?',
          style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Pick the main goal. This helps communities understand the opportunity.',
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (errors.containsKey('goal'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['goal']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),

        ...goalOptionsAsync
            .when(
              data: (options) => options,
              loading: () => const <OfferOption>[],
              error: (_, _) => const <OfferOption>[],
            )
            .map((option) {
          final isSelected = selectedGoal == option.slug;
          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: GestureDetector(
              onTap: () => notifier.updateGoal(option.slug),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.softYellow : context.colors.surface,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? context.colors.primary : context.colors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? context.colors.primary : context.colors.darkBorder,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(LucideIcons.check, size: 14, color: context.colors.onPrimary)
                          : null,
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    CategoryIcon(name: option.name, iconUrl: option.iconUrl, size: 24),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        option.name,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (goalOptionsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
