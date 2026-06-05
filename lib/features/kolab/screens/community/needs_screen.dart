import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../enums/need_type.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 0: "WHAT DO YOU NEED?"
///
/// Displays the 6 [NeedType] options in a 2-column grid.
/// The user can select as many as they like.
class NeedsScreen extends ConsumerWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'WHAT DO YOU NEED?',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Select all that apply',
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
          ),

          // Error
          if (state.fieldErrors['needs'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(state.fieldErrors['needs']!),
          ],

          const SizedBox(height: KolabingSpacing.lg),

          // 2-column grid of NeedType options
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: KolabingSpacing.sm,
            crossAxisSpacing: KolabingSpacing.sm,
            childAspectRatio: 1.3,
            children: NeedType.values.map((need) {
              final isSelected = kolab.needs.contains(need);
              return GestureDetector(
                onTap: () =>
                    ref.read(kolabFormProvider.notifier).toggleNeed(need),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.softYellow
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.darkBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        need.icon,
                        size: 28,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.textTertiary,
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        need.displayName,
                        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldError(String error) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.errorBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: context.colors.error,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                error,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
              ),
            ),
          ],
        ),
      );
}
