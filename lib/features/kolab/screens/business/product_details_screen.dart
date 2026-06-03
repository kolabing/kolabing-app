import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
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
  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  // H2: offer headline pinned to the discovery card.
  final _headlineController = TextEditingController();

  bool _didInit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;

    _titleController.text = kolab.title;
    _nameController.text = kolab.productName ?? '';
    _descriptionController.text = kolab.description;
    _headlineController.text = kolab.offerHeadline ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllersFromState(kolab);

    final l10n = AppLocalizations.of(context);
    final citiesAsync = ref.watch(citiesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        _SectionHeader(label: l10n.productDetailsSectionHeader),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Listing Title
        _FieldLabel(label: l10n.productDetailsListingTitleLabel),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _titleController,
          maxLength: 255,
          decoration: _inputDecoration(
            hint: l10n.productDetailsListingTitleHint,
            error: errors['title'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateTitle,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Product Name
        _FieldLabel(label: l10n.productDetailsProductNameLabel),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _nameController,
          maxLength: 255,
          decoration: _inputDecoration(
            hint: l10n.productDetailsProductNameHint,
            error: errors['product_name'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateProductName,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Product Type
        _FieldLabel(label: l10n.productDetailsProductTypeLabel),
        const SizedBox(height: KolabingSpacing.xs),
        if (errors.containsKey('product_type'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
            child: Text(
              errors['product_type']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.error),
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
                        : KolabingColors.darkBorder,
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
                          : KolabingColors.onSurface,
                    ),
                    const SizedBox(width: KolabingSpacing.xxs),
                    Text(
                      type.displayName,
                      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected
                            ? KolabingColors.onPrimary
                            : KolabingColors.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Description
        _FieldLabel(label: l10n.productDetailsDescriptionLabel),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          decoration: _inputDecoration(
            hint: l10n.productDetailsDescriptionHint,
            error: errors['description'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateDescription,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),
        // H2: short, one-line offer headline shown on the discovery card.
        _FieldLabel(label: l10n.productDetailsOfferHeadlineLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.productDetailsOfferHeadlineHelper,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextField(
          controller: _headlineController,
          maxLength: 50,
          decoration: _inputDecoration(
            hint: l10n.productDetailsOfferHeadlineHint,
            error: errors['offer_headline'],
          ),
          style: _inputTextStyle,
          onChanged: notifier.updateOfferHeadline,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- City dropdown
        _FieldLabel(label: l10n.productDetailsCityLabel),
        const SizedBox(height: KolabingSpacing.xs),
        citiesAsync.when(
          data: (cities) => DropdownButtonFormField<String>(
              initialValue: kolab.preferredCity.isNotEmpty
                  ? kolab.preferredCity
                  : null,
              decoration: _inputDecoration(
                hint: l10n.productDetailsSelectCityHint,
                error: errors['preferred_city'],
              ),
              style: _inputTextStyle,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: KolabingColors.onSurfaceVariant,
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
            backgroundColor: KolabingColors.darkBorder,
          ),
          error: (_, _) => Text(
            l10n.productDetailsFailedToLoadCities,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.error),
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
      hintStyle: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textTertiary),
      errorText: error,
      errorStyle: KolabingTextStyles.bodySmall.copyWith(fontSize: 12),
      filled: true,
      fillColor: KolabingColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: 14,
      ),
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

TextStyle get _inputTextStyle => KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurface);

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.0),
    );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: KolabingColors.onSurface),
    );
}
