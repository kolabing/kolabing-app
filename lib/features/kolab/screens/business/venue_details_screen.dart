import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
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

  bool _didInit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    if (_didInit) return;
    final kolab = ref.read(kolabFormProvider).kolab;
    _didInit = true;
    _titleController.text = kolab.title;
    _descriptionController.text = kolab.description;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllers();

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
        const _SectionHeader(label: 'PROMOTION DETAILS'),
        const SizedBox(height: KolabingSpacing.lg),
        if (!hasVenueProfile) ...[
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            decoration: BoxDecoration(
              color: KolabingColors.error.withValues(alpha: 0.08),
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: KolabingColors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your primary venue profile is missing',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.error,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  'Complete business onboarding once to save your venue, then come back here and we will reuse it automatically.',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: KolabingColors.textSecondary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                TextButton(
                  onPressed: () => context.go(KolabingRoutes.businessOnboardingStep2),
                  child: const Text('Complete onboarding'),
                ),
              ],
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ] else ...[
          _VenueSummaryCard(kolab: kolab),
          const SizedBox(height: KolabingSpacing.md),
        ],
        if (errors.containsKey('primary_venue'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: Text(
              errors['primary_venue']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),
        const _FieldLabel(label: 'Listing Title'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _titleController,
          maxLength: 255,
          decoration: _inputDecoration(
            hint: 'e.g. Sunset rooftop social for local creators',
            error: errors['title'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateTitle,
        ),
        const SizedBox(height: KolabingSpacing.md),
        const _FieldLabel(label: 'Campaign Description'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          decoration: _inputDecoration(
            hint: 'Tell communities what kind of experience you want to host and why your venue is a great fit.',
            error: errors['description'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateDescription,
        ),
      ],
    );
  }
}

class _VenueSummaryCard extends StatelessWidget {
  const _VenueSummaryCard({required this.kolab});

  final Kolab kolab;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: KolabingColors.softYellowBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRIMARY VENUE',
              style: GoogleFonts.rubik(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: KolabingColors.primaryDark,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            _SummaryRow(
              icon: LucideIcons.building2,
              title: kolab.venueName ?? '--',
              subtitle:
                  '${kolab.venueType?.displayName ?? 'Venue'} • Capacity ${kolab.capacity ?? '--'}',
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
          Icon(icon, size: 18, color: KolabingColors.primaryDark),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

InputDecoration _inputDecoration({
  required String hint,
  String? error,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        fontSize: 14,
        color: KolabingColors.textTertiary,
      ),
      errorText: error,
      errorStyle: GoogleFonts.openSans(fontSize: 12),
      filled: true,
      fillColor: KolabingColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.error, width: 1.5),
      ),
    );

final _inputTextStyle = GoogleFonts.openSans(
  fontSize: 15,
  color: KolabingColors.textPrimary,
);

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: KolabingColors.textSecondary,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textPrimary,
        ),
      );
}
