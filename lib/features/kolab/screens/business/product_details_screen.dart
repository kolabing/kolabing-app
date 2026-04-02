import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../opportunity/providers/opportunity_provider.dart';
import '../../enums/product_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 0 for the product promotion flow: "YOUR PRODUCT OR SERVICE"
///
/// Collects product name, product type, description, and city.
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _didInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;

    _nameController.text = kolab.productName ?? '';
    _descriptionController.text = kolab.description;
  }

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
        const _SectionHeader(label: 'YOUR PRODUCT OR SERVICE'),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Product Name
        const _FieldLabel(label: 'Product Name'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _nameController,
          maxLength: 255,
          decoration: _inputDecoration(
            hint: 'e.g. Organic Cold Brew Coffee',
            error: errors['product_name'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateProductName,
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Product Type
        const _FieldLabel(label: 'Product Type'),
        const SizedBox(height: KolabingSpacing.xs),
        if (errors.containsKey('product_type'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
            child: Text(
              errors['product_type']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xs,
          children: ProductType.values.map((type) {
            final isSelected = kolab.productType == type;
            return GestureDetector(
              onTap: () {
                notifier.updateProductType(isSelected ? null : type);
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

        // -- Description
        const _FieldLabel(label: 'Description'),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          decoration: _inputDecoration(
            hint: 'Describe your product or service...',
            error: errors['description'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateDescription,
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
                      child: Text(c.name, style: _inputTextStyle),
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
