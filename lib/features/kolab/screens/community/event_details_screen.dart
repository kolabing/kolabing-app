import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../enums/deliverable_type.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 2: "COLLABORATION DETAILS"
///
/// Collects title, description, and what the community offers in return
/// (deliverable type toggles).
class EventDetailsScreen extends ConsumerStatefulWidget {
  const EventDetailsScreen({super.key});

  @override
  ConsumerState<EventDetailsScreen> createState() =>
      _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers();
    });
  }

  void _syncControllers() {
    final kolab = ref.read(kolabFormProvider).kolab;
    if (_titleController.text != kolab.title) {
      _titleController.text = kolab.title;
    }
    if (_descriptionController.text != kolab.description) {
      _descriptionController.text = kolab.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'COLLABORATION DETAILS',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Describe your collaboration and what you offer',
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Title
          _buildLabel('Title'),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _titleController,
            maxLength: 255,
            onChanged: (value) =>
                ref.read(kolabFormProvider.notifier).updateTitle(value),
            // C1: dismiss keyboard on tap-outside so the bottom action bar is reachable.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: KolabingColors.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g., Fitness Community x Local Cafe',
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
              filled: true,
              fillColor: KolabingColors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    const BorderSide(color: KolabingColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.error),
              ),
              errorText: state.fieldErrors['title'],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Description
          _buildLabel('Description'),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _descriptionController,
            maxLength: 2000,
            maxLines: 5,
            onChanged: (value) =>
                ref.read(kolabFormProvider.notifier).updateDescription(value),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: KolabingColors.onSurface),
            decoration: InputDecoration(
              hintText:
                  'Describe what you are looking for and how this collaboration would work...',
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
              filled: true,
              fillColor: KolabingColors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    const BorderSide(color: KolabingColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.error),
              ),
              errorText: state.fieldErrors['description'],
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // "What you offer in return" section header
          Text(
            'WHAT YOU OFFER IN RETURN',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          if (state.fieldErrors['offers_in_return'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(state.fieldErrors['offers_in_return']!),
          ],
          const SizedBox(height: KolabingSpacing.md),

          // Deliverable type toggle cards
          ...DeliverableType.values.map((deliverable) {
            final isSelected = kolab.offersInReturn.contains(deliverable);
            return Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: GestureDetector(
                onTap: () => ref
                    .read(kolabFormProvider.notifier)
                    .toggleOfferInReturn(deliverable),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KolabingColors.softYellow
                        : KolabingColors.surface,
                    borderRadius: KolabingRadius.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? KolabingColors.primary
                          : KolabingColors.darkBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? KolabingColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? KolabingColors.primary
                                : KolabingColors.darkBorder,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: KolabingColors.onPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deliverable.displayName,
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deliverable.subtitle,
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
      );

  Widget _buildFieldError(String error) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.errorBg,
          borderRadius: KolabingRadius.borderRadiusSm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 14,
              color: KolabingColors.error,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                error,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.error),
              ),
            ),
          ],
        ),
      );
}
