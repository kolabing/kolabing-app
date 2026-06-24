import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 0 for the venue promotion flow.
///
/// The venue itself is now inherited from the business onboarding profile,
/// so this screen only captures campaign-specific copy and shows the linked
/// venue summary.
class VenueDetailsScreen extends ConsumerStatefulWidget {
  const VenueDetailsScreen({super.key});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  // H2: offer headline pinned to the discovery card.
  final _headlineController = TextEditingController();

  bool _didInit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    if (_didInit) return;
    final kolab = ref.read(kolabFormProvider).kolab;
    _didInit = true;
    _titleController.text = kolab.title;
    _descriptionController.text = kolab.description;
    _headlineController.text = kolab.offerHeadline ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllers();

    final l10n = AppLocalizations.of(context);
    final hasVenueProfile = kolab.venueName != null &&
        kolab.venueName!.isNotEmpty &&
        kolab.venueType != null &&
        kolab.capacity != null &&
        kolab.capacity! > 0 &&
        kolab.venueAddress != null &&
        kolab.venueAddress!.isNotEmpty &&
        kolab.preferredCity.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        _SectionHeader(label: l10n.venueDetailsSectionHeader),
        const SizedBox(height: KolabingSpacing.lg),
        if (hasVenueProfile) ...[
          _VenueSummaryCard(kolab: kolab),
          const SizedBox(height: KolabingSpacing.md),
        ],
        _FieldLabel(label: l10n.venueDetailsListingTitleLabel),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _titleController,
          maxLength: 255,
          hint: l10n.venueDetailsListingTitleHint,
          errorText: errors['title'],
          onChanged: notifier.updateTitle,
          // C1: dismiss keyboard on tap-outside so the action bar is reachable.
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),
        _FieldLabel(label: l10n.venueDetailsCampaignDescriptionLabel),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          hint: l10n.venueDetailsCampaignDescriptionHint,
          errorText: errors['description'],
          onChanged: notifier.updateDescription,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),
        // H2: short, one-line offer headline shown on the discovery card.
        _FieldLabel(label: l10n.venueDetailsOfferHeadlineLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.venueDetailsOfferHeadlineHelper,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _headlineController,
          maxLength: 50,
          hint: l10n.venueDetailsOfferHeadlineHint,
          errorText: errors['offer_headline'],
          onChanged: notifier.updateOfferHeadline,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }
}

class _VenueSummaryCard extends StatelessWidget {
  const _VenueSummaryCard({required this.kolab});

  final Kolab kolab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.softYellow,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: context.colors.softYellowBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.venueDetailsPrimaryVenue,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.primaryDark, letterSpacing: 0.8),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            _SummaryRow(
              icon: LucideIcons.building2,
              title: kolab.venueName ?? '--',
              subtitle: l10n.venueDetailsTypeCapacity(
                kolab.venueType?.displayName ?? l10n.venueDetailsVenueFallback,
                (kolab.capacity ?? '--').toString(),
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            _SummaryRow(
              icon: LucideIcons.mapPin,
              title: kolab.venueAddress ?? '--',
              subtitle: kolab.preferredCity,
            ),
          ],
        ),
      );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.primaryDark),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
      );
}
