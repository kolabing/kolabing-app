import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../opportunity/providers/opportunity_provider.dart';
import '../../enums/venue_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 0 for the venue promotion flow: "YOUR VENUE"
///
/// Collects venue name, venue type, capacity, address, and city.
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class VenueDetailsScreen extends ConsumerStatefulWidget {
  const VenueDetailsScreen({super.key});

  @override
  ConsumerState<VenueDetailsScreen> createState() =>
      _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _addressController = TextEditingController();

  bool _didInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;

    _nameController.text = kolab.venueName ?? '';
    _capacityController.text =
        kolab.capacity != null ? kolab.capacity.toString() : '';
    _addressController.text = kolab.venueAddress ?? '';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllersFromState(kolab);

    final citiesAsync = ref.watch(citiesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        const _SectionHeader(label: 'YOUR VENUE'),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Venue Name
        const _FieldLabel(label: 'Venue Name'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _nameController,
          maxLength: 255,
          decoration: _inputDecoration(
            hint: 'e.g. The Rooftop Bar',
            error: errors['venue_name'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateVenueName,
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Venue Type
        const _FieldLabel(label: 'Venue Type'),
        const SizedBox(height: KolabingSpacing.xs),
        if (errors.containsKey('venue_type'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
            child: Text(
              errors['venue_type']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xs,
          children: VenueType.values.map((type) {
            final isSelected = kolab.venueType == type;
            return GestureDetector(
              onTap: () {
                notifier.updateVenueType(isSelected ? null : type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.surface,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textPrimary,
                    ),
                    const SizedBox(width: KolabingSpacing.xxs),
                    Text(
                      type.displayName,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? KolabingColors.onPrimary
                            : KolabingColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Capacity
        const _FieldLabel(label: 'Capacity'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _capacityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            hint: 'e.g. 100',
            error: errors['capacity'],
          ),
          style: _inputTextStyle,
          onChanged: (v) {
            final parsed = int.tryParse(v);
            notifier.updateCapacity(parsed);
          },
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Address
        const _FieldLabel(label: 'Address'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _addressController,
          decoration: _inputDecoration(
            hint: 'Street address',
            error: errors['venue_address'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateVenueAddress,
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- City dropdown
        const _FieldLabel(label: 'City'),
        const SizedBox(height: KolabingSpacing.xs),
        citiesAsync.when(
          data: (cities) => DropdownButtonFormField<String>(
              initialValue: kolab.preferredCity.isNotEmpty
                  ? kolab.preferredCity
                  : null,
              decoration: _inputDecoration(
                hint: 'Select city',
                error: errors['preferred_city'],
              ),
              style: _inputTextStyle,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: KolabingColors.textSecondary,
              ),
              items: cities
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(
                        c.name,
                        style: _inputTextStyle,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.updatePreferredCity(v);
              },
            ),
          loading: () => const LinearProgressIndicator(
            color: KolabingColors.primary,
            backgroundColor: KolabingColors.border,
          ),
          error: (_, _) => Text(
            'Failed to load cities',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.error,
            ),
          ),
        ),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

// =============================================================================
// Shared helpers (file-private)
// =============================================================================

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
        borderSide: const BorderSide(color: KolabingColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.borderError, width: 1.5),
      ),
    );

TextStyle get _inputTextStyle => GoogleFonts.openSans(
      fontSize: 14,
      color: KolabingColors.textPrimary,
    );

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
      label,
      style: GoogleFonts.rubik(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
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
        fontWeight: FontWeight.w500,
        color: KolabingColors.textPrimary,
      ),
    );
}
