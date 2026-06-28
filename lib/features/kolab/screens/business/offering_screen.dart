import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/category_icon.dart';
import '../../../../widgets/kolabing_button.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';
import '../../widgets/kolab_examples_box.dart';
import '../../widgets/multi_select_chips.dart';

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
        // -- Intro: this is the core of the Kolab
        Text(
          'This is the main reason a community will say yes.',
          style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.onSurface),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- 1. What are you offering? (toggle cards, admin-managed taxonomy
        // via offeringsProvider; falls back to the bundled list when the
        // endpoint isn't deployed)
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

        // -- Main offer, in the business's own words
        _SectionLabel(label: l10n.offeringBaseOfferLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.offeringBaseOfferHelper,
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        if (errors.containsKey('base_offer'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['base_offer']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),
        KolabingInput(
          controller: _baseOfferController,
          maxLength: 400,
          maxLines: 3,
          hint: l10n.offeringBaseOfferHint,
          onChanged: notifier.updateBaseOffer,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        const KolabExamplesBox(examples: [
          'Free coffee tasting for 20 runners in exchange for tagged stories.',
          '50 product samples for a fitness community in exchange for feedback.',
          '20% off brunch for community members every Sunday.',
        ]),
        const SizedBox(height: KolabingSpacing.md),
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
          child: Text(
            'Good Kolabs usually include a clear perk: free samples, a discount, '
            'a space, an experience, content, or something members will enjoy.',
            style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurface, height: 1.4),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- 2. What would you like from the community?
        const _SectionLabel(label: 'WHAT WOULD YOU LIKE FROM THE COMMUNITY?'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'You can choose more than one. This is not a strict contract yet — '
          'it helps communities understand your expectations.',
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Builder(builder: (context) {
          final deliverableOptions = ref.watch(deliverablesProvider).when(
                data: (options) => options,
                loading: () => const <OfferOption>[],
                error: (_, _) => const <OfferOption>[],
              );
          return MultiSelectChips<OfferOption>(
            items: deliverableOptions,
            selected: deliverableOptions
                .where((o) => kolab.expects.contains(o.slug))
                .toList(),
            labelBuilder: (o) => o.name,
            onToggle: (option) => notifier.toggleExpect(option.slug),
          );
        }),
        const SizedBox(height: KolabingSpacing.xs),
        const KolabExamplesBox(examples: [
          'Tagged stories + honest feedback from members.',
          'Minimum 15 attendees and community photos.',
          'Open to ideas — we mainly want to connect with the right community.',
        ]),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: KolabingButton(
                label: l10n.offeringAddExtraTerm,
                onPressed: () => _addTrigger(kolab, notifier),
                variant: KolabingButtonVariant.secondary,
                size: KolabingButtonSize.small,
                icon: const Icon(LucideIcons.plus, size: 16),
              ),
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
          KolabingInput(
            controller: _conditionController,
            maxLength: 100,
            label: l10n.offeringTriggerWhenLabel,
            hint: l10n.offeringTriggerWhenHint,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          KolabingInput(
            controller: _offerController,
            maxLength: 200,
            maxLines: 2,
            label: l10n.offeringTriggerThenLabel,
            hint: l10n.offeringTriggerThenHint,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: l10n.offeringAddTerm,
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
            variant: KolabingButtonVariant.primary,
            size: KolabingButtonSize.compact,
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
