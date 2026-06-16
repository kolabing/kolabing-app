import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/category_icon.dart';
import '../../enums/deliverable_type.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

/// Community step 2: "COLLABORATION DETAILS"
///
/// Collects title, description, and what the community offers in return.
///
/// The "what you offer in return" option LIST is admin-managed: it comes from
/// [deliverablesProvider] (`GET /lookup/deliverables`, self-gating to the
/// hardcoded launch list on 404/empty), so admins can edit labels/order or add
/// options without an app release. STORAGE stays on the typed [DeliverableType]
/// enum (the `offers_in_return[]` wire contract): each option's `slug` maps back
/// via [DeliverableType.fromString], so the payload and backend validation are
/// unchanged.
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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;
    final deliverableOptionsAsync = ref.watch(deliverablesProvider);

    // Admin-managed list; the provider's service already falls back to the
    // bundled list on 404/empty, but guard here so the list is never empty
    // mid-flight.
    final deliverableOptions = deliverableOptionsAsync.when(
      data: (data) => data,
      loading: () => const <OfferOption>[],
      error: (_, _) => const <OfferOption>[],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            l10n.eventDetailsHeader,
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            l10n.eventDetailsSubtitle,
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Title
          _buildLabel(l10n.eventDetailsTitleLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _titleController,
            maxLength: 255,
            onChanged: (value) =>
                ref.read(kolabFormProvider.notifier).updateTitle(value),
            // C1: dismiss keyboard on tap-outside so the bottom action bar is reachable.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: l10n.eventDetailsTitleHint,
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: context.colors.textTertiary),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    BorderSide(color: context.colors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.error),
              ),
              errorText: state.fieldErrors['title'],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Description
          _buildLabel(l10n.eventDetailsDescriptionLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _descriptionController,
            maxLength: 2000,
            maxLines: 5,
            onChanged: (value) =>
                ref.read(kolabFormProvider.notifier).updateDescription(value),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: l10n.eventDetailsDescriptionHint,
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: context.colors.textTertiary),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    BorderSide(color: context.colors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.error),
              ),
              errorText: state.fieldErrors['description'],
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // "What you offer in return" section header
          Text(
            l10n.eventDetailsOffersHeader,
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          if (state.fieldErrors['offers_in_return'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(state.fieldErrors['offers_in_return']!),
          ],
          const SizedBox(height: KolabingSpacing.md),

          // Deliverable type toggle cards (admin-managed list via
          // deliverablesProvider; slug maps back onto DeliverableType for
          // storage/wire).
          ...deliverableOptions.map((option) {
            final deliverable = DeliverableType.fromString(option.slug);
            final isSelected = kolab.offersInReturn.contains(deliverable);
            // Prefer the admin-provided label/description; fall back to the
            // enum's static copy so a mid-flight empty value never renders blank.
            final label = option.name.isNotEmpty
                ? option.name
                : deliverable.displayName;
            final subtitle = (option.description?.isNotEmpty ?? false)
                ? option.description!
                : deliverable.subtitle;
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
                        ? context.colors.softYellow
                        : context.colors.surface,
                    borderRadius: KolabingRadius.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.darkBorder,
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
                              ? context.colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.darkBorder,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: context.colors.onPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      // Personalised category SVG (admin icon_url overrides).
                      CategoryIcon(
                        name: option.name,
                        iconUrl: option.iconUrl,
                        size: 24,
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
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

          if (deliverableOptionsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
      );

  Widget _buildFieldError(String error) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.errorBg,
          borderRadius: KolabingRadius.borderRadiusSm,
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
