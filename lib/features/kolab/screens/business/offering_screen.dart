import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/category_icon.dart';
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

/// Step 2 (venue / product flows): "WHAT YOU'RE OFFERING"
///
/// Toggle cards for each offering type. "Venue" is auto-selected and locked
/// when the intent is venuePromotion.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class OfferingScreen extends ConsumerStatefulWidget {
  const OfferingScreen({super.key});

  @override
  ConsumerState<OfferingScreen> createState() => _OfferingScreenState();
}

class _OfferingScreenState extends ConsumerState<OfferingScreen> {
  final _baseOfferController = TextEditingController();
  bool _didInit = false;

  @override
  void dispose() {
    _baseOfferController.dispose();
    super.dispose();
  }

  void _syncControllers(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;
    _baseOfferController.text = kolab.baseOffer ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllers(kolab);

    final l10n = AppLocalizations.of(context);
    final isVenueFlow = formState.intentType == IntentType.venuePromotion;
    final offerings = kolab.offering;
    final offeringOptionsAsync = ref.watch(offeringsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          l10n.offeringTitle,
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          l10n.offeringSelectAllThatApply,
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Error
        if (errors.containsKey('offering'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['offering']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),

        // -- Toggle cards (admin-managed taxonomy via offeringsProvider; falls
        //    back to the bundled list when the endpoint isn't deployed)
        ...offeringOptionsAsync
            .when(
              data: (options) => options,
              // While loading or on error the provider's service already returns
              // the hardcoded fallback, but guard here too so the picker is never
              // empty mid-flight.
              loading: () => const <OfferOption>[],
              error: (_, _) => const <OfferOption>[],
            )
            .map((option) {
          final isSelected = offerings.contains(option.slug);
          final isVenueLocked = isVenueFlow && option.slug == 'venue';

          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: _ToggleCard(
              title: _offeringTitle(l10n, option.slug, option.name),
              subtitle: _offeringSubtitle(
                l10n,
                option.slug,
                option.description ?? '',
              ),
              iconName: option.name,
              iconUrl: option.iconUrl,
              isSelected: isVenueLocked || isSelected,
              isLocked: isVenueLocked,
              onTap: isVenueLocked
                  ? null
                  : () => notifier.toggleOffering(option.slug),
            ),
          );
        }),

        if (offeringOptionsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),

        const SizedBox(height: KolabingSpacing.lg),

        // H3: Base offer (public to all viewers).
        _SectionLabel(label: l10n.offeringBaseOfferLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.offeringBaseOfferHelper,
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _baseOfferController,
          maxLength: 400,
          maxLines: 3,
          onChanged: notifier.updateBaseOffer,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: context.colors.onSurface),
          decoration: InputDecoration(
            hintText: l10n.offeringBaseOfferHint,
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.colors.darkBorder),
            ),
          ),
        ),

        const SizedBox(height: KolabingSpacing.lg),

        // H3: Negotiation triggers — surfaces only after a community applies.
        _SectionLabel(label: l10n.offeringExtraTermsLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.offeringExtraTermsHelper,
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        ..._buildTriggerRows(kolab, notifier),

        Padding(
          padding: const EdgeInsets.only(top: KolabingSpacing.xs),
          child: OutlinedButton.icon(
            onPressed: () => _addTrigger(kolab, notifier),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              l10n.offeringAddExtraTerm,
              style: KolabingTextStyles.button.copyWith(fontSize: 13, letterSpacing: 0.5),
            ),
          ),
        ),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }

  Iterable<Widget> _buildTriggerRows(
    Kolab kolab,
    KolabFormNotifier notifier,
  ) sync* {
    for (var i = 0; i < kolab.negotiationTriggers.length; i++) {
      final trigger = kolab.negotiationTriggers[i];
      yield Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
        child: _TriggerCard(
          index: i + 1,
          condition: trigger.condition,
          additionalOffer: trigger.additionalOffer,
          onRemove: () {
            final next = [...kolab.negotiationTriggers]..removeAt(i);
            notifier.updateNegotiationTriggers(next);
          },
        ),
      );
    }
  }

  Future<void> _addTrigger(Kolab kolab, KolabFormNotifier notifier) async {
    final result = await showModalBottomSheet<NegotiationTrigger>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TriggerEditorSheet(),
    );
    if (result == null) return;
    notifier.updateNegotiationTriggers([
      ...kolab.negotiationTriggers,
      result,
    ]);
  }
}

String _offeringTitle(AppLocalizations l10n, String value, String fallback) {
  switch (value) {
    case 'venue':
      return l10n.offeringVenueTitle;
    case 'food_drink':
      return l10n.offeringFoodDrinkTitle;
    case 'discount':
      return l10n.offeringDiscountTitle;
    case 'products':
      return l10n.offeringProductsTitle;
    case 'social_media':
      return l10n.offeringSocialMediaTitle;
    case 'content_creation':
      return l10n.offeringContentCreationTitle;
    case 'sponsorship':
      return l10n.offeringSponsorshipTitle;
    case 'other':
      return l10n.offeringOtherTitle;
    default:
      return fallback;
  }
}

String _offeringSubtitle(AppLocalizations l10n, String value, String fallback) {
  switch (value) {
    case 'venue':
      return l10n.offeringVenueSubtitle;
    case 'food_drink':
      return l10n.offeringFoodDrinkSubtitle;
    case 'discount':
      return l10n.offeringDiscountSubtitle;
    case 'products':
      return l10n.offeringProductsSubtitle;
    case 'social_media':
      return l10n.offeringSocialMediaSubtitle;
    case 'content_creation':
      return l10n.offeringContentCreationSubtitle;
    case 'sponsorship':
      return l10n.offeringSponsorshipSubtitle;
    case 'other':
      return l10n.offeringOtherSubtitle;
    default:
      return fallback;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
      );
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({
    required this.index,
    required this.condition,
    required this.additionalOffer,
    required this.onRemove,
  });

  final int index;
  final String condition;
  final String additionalOffer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colors.darkBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).offeringTriggerIfPrefix(condition),
                    style: KolabingTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.textTertiary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    additionalOffer,
                    style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurface, height: 1.4),
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
      );
}

class _TriggerEditorSheet extends StatefulWidget {
  const _TriggerEditorSheet();

  @override
  State<_TriggerEditorSheet> createState() => _TriggerEditorSheetState();
}

class _TriggerEditorSheetState extends State<_TriggerEditorSheet> {
  final _conditionController = TextEditingController();
  final _offerController = TextEditingController();

  @override
  void dispose() {
    _conditionController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.lg,
        KolabingSpacing.md,
        KolabingSpacing.lg,
        bottomPadding + KolabingSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            l10n.offeringTriggerSheetTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.offeringTriggerSheetSubtitle,
            style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextField(
            controller: _conditionController,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l10n.offeringTriggerWhenLabel,
              hintText: l10n.offeringTriggerWhenHint,
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          TextField(
            controller: _offerController,
            maxLength: 200,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.offeringTriggerThenLabel,
              hintText: l10n.offeringTriggerThenHint,
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final condition = _conditionController.text.trim();
                final offer = _offerController.text.trim();
                if (condition.isEmpty || offer.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  NegotiationTrigger(
                    condition: condition,
                    additionalOffer: offer,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
              ),
              child: Text(
                l10n.offeringAddTerm,
                style: KolabingTextStyles.button.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =============================================================================
// Toggle Card
// =============================================================================

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.isSelected,
    this.iconUrl,
    this.isLocked = false,
    this.onTap,
  });

  final String title;
  final String subtitle;

  /// Name used to resolve the personalised bundled category SVG.
  final String iconName;

  /// Admin-uploaded SVG URL; overrides the bundled asset when present.
  final String? iconUrl;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.softYellow
              : context.colors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.darkBorder,
          ),
        ),
        child: Row(
          children: [
            // Checkbox / Locked indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary
                    : Colors.transparent,
                borderRadius: KolabingRadius.borderRadiusXs,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.darkBorder,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      isLocked ? LucideIcons.lock : LucideIcons.check,
                      size: 14,
                      color: context.colors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Icon (personalised category SVG; admin icon_url overrides)
            CategoryIcon(name: iconName, iconUrl: iconUrl, size: 24),
            const SizedBox(width: KolabingSpacing.sm),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
