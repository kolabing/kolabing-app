import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

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

  static const List<_OfferingOption> _options = [
    _OfferingOption(
      value: 'venue',
      title: 'Venue',
      subtitle: 'Provide your space for the collaboration',
      icon: LucideIcons.building2,
    ),
    _OfferingOption(
      value: 'food_drink',
      title: 'Food & Drink included',
      subtitle: 'Meals or beverages for community members',
      icon: LucideIcons.utensils,
    ),
    _OfferingOption(
      value: 'discount',
      title: 'Discount for community members',
      subtitle: 'Exclusive pricing for participants',
      icon: LucideIcons.percent,
    ),
    _OfferingOption(
      value: 'products',
      title: 'Products / Samples',
      subtitle: 'Free product samples or giveaways',
      icon: LucideIcons.gift,
    ),
    _OfferingOption(
      value: 'social_media',
      title: 'Social Media Exposure',
      subtitle: 'Feature on your channels',
      icon: LucideIcons.share2,
    ),
    _OfferingOption(
      value: 'content_creation',
      title: 'Content Creation',
      subtitle: 'Professional photos/video',
      icon: LucideIcons.camera,
    ),
    _OfferingOption(
      value: 'sponsorship',
      title: 'Sponsorship budget',
      subtitle: 'Financial support for the collaboration',
      icon: LucideIcons.banknote,
    ),
    _OfferingOption(
      value: 'other',
      title: 'Other',
      subtitle: 'Something else to offer',
      icon: LucideIcons.moreHorizontal,
    ),
  ];

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

    final isVenueFlow = formState.intentType == IntentType.venuePromotion;
    final offerings = kolab.offering;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          "WHAT YOU'RE OFFERING",
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          'Select all that apply',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Error
        if (errors.containsKey('offering'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['offering']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),

        // -- Toggle cards
        ...OfferingScreen._options.map((option) {
          final isSelected = offerings.contains(option.value);
          final isVenueLocked = isVenueFlow && option.value == 'venue';

          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: _ToggleCard(
              title: option.title,
              subtitle: option.subtitle,
              icon: option.icon,
              isSelected: isVenueLocked || isSelected,
              isLocked: isVenueLocked,
              onTap: isVenueLocked
                  ? null
                  : () => notifier.toggleOffering(option.value),
            ),
          );
        }),

        const SizedBox(height: KolabingSpacing.lg),

        // H3: Base offer (public to all viewers).
        _SectionLabel(label: 'BASE OFFER'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'What every community will see on your card. Be specific so leaders can evaluate at a glance.',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _baseOfferController,
          maxLength: 400,
          maxLines: 3,
          onChanged: notifier.updateBaseOffer,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: KolabingColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText:
                'e.g. 20% off Tuesdays, free meeting room for groups of 10+',
            filled: true,
            fillColor: KolabingColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
          ),
        ),

        const SizedBox(height: KolabingSpacing.lg),

        // H3: Negotiation triggers — surfaces only after a community applies.
        _SectionLabel(label: 'EXTRA TERMS (OPTIONAL)'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Better terms you only unlock once a community proposes a collab. '
          'They see these after sending you a Kolab.',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        ..._buildTriggerRows(kolab, notifier),

        Padding(
          padding: const EdgeInsets.only(top: KolabingSpacing.xs),
          child: OutlinedButton.icon(
            onPressed: () => _addTrigger(kolab, notifier),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              'ADD EXTRA TERM',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.primary,
              side: BorderSide(
                color: KolabingColors.primary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: KolabingColors.textSecondary,
        ),
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
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KolabingColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IF $condition',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    additionalOffer,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: KolabingColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
              icon: const Icon(
                LucideIcons.x,
                size: 18,
                color: KolabingColors.textTertiary,
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: KolabingColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            'Add an extra term',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Surfaces only after a community sends a Kolab proposal.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextField(
            controller: _conditionController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'When',
              hintText: 'e.g. recurring monthly events',
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          TextField(
            controller: _offerController,
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Then offer',
              hintText: 'e.g. free venue rental from the 3rd event onward',
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
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'ADD TERM',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Data class for offering options
// =============================================================================

class _OfferingOption {
  const _OfferingOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

// =============================================================================
// Toggle Card
// =============================================================================

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isLocked = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
              ? KolabingColors.softYellow
              : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? KolabingColors.primary
                : KolabingColors.border,
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
                    ? KolabingColors.primary
                    : Colors.transparent,
                borderRadius: KolabingRadius.borderRadiusXs,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      isLocked ? LucideIcons.lock : LucideIcons.check,
                      size: 14,
                      color: KolabingColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Icon
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? KolabingColors.textPrimary
                  : KolabingColors.textSecondary,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
