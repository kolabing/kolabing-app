import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/kolabing_icon_option_card.dart';
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
          // Section header — Anton uppercase
          Text(
            'WHAT DO YOU NEED?',
            style: KolabingTextStyles.sectionHeadingLarge.copyWith(
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Select all that apply',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),

          // Validation error
          if (state.fieldErrors['needs'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(context, state.fieldErrors['needs']!),
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
              return KolabingIconOptionCard(
                icon: Icon(need.icon, size: 28),
                label: need.displayName,
                selected: isSelected,
                onTap: () =>
                    ref.read(kolabFormProvider.notifier).toggleNeed(need),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldError(BuildContext context, String error) => Container(
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
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.error,
                ),
              ),
            ),
          ],
        ),
      );
}
