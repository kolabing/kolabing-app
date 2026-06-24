import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/category_icon.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../opportunity/providers/opportunity_provider.dart';
import '../../enums/product_type.dart';
import '../../models/kolab.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

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

    // Admin-managed product-type list (GET /lookup/product-types); the service
    // self-gates to the bundled list on 404/empty. Storage stays on the typed
    // ProductType enum (the wire value), so the payload is unchanged.
    final productTypeOptionsAsync = ref.watch(productTypesProvider);
    final productTypeOptions = productTypeOptionsAsync.when(
      data: (data) => data,
      loading: () => const <OfferOption>[],
      error: (_, _) => const <OfferOption>[],
    );

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
        KolabingInput(
          controller: _titleController,
          maxLength: 255,
          hint: l10n.productDetailsListingTitleHint,
          errorText: errors['title'],
          onChanged: notifier.updateTitle,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Product Name
        _FieldLabel(label: l10n.productDetailsProductNameLabel),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _nameController,
          maxLength: 255,
          hint: l10n.productDetailsProductNameHint,
          errorText: errors['product_name'],
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
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xs,
          children: productTypeOptions.map((option) {
            // Map the admin slug onto the typed enum (the stored/wire value).
            final type = ProductType.fromString(option.slug);
            final isSelected = kolab.productType == type;
            // Prefer the admin-provided label; fall back to the enum name so a
            // mid-flight empty name never renders blank.
            final label = option.name.isNotEmpty
                ? option.name
                : type.displayName;
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
                      ? context.colors.primary
                      : context.colors.surface,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.darkBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcon(
                      name: option.name,
                      iconUrl: option.iconUrl,
                      size: 18,
                    ),
                    const SizedBox(width: KolabingSpacing.xxs),
                    Text(
                      label,
                      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected
                            ? context.colors.onPrimary
                            : context.colors.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (productTypeOptionsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: KolabingSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Description
        _FieldLabel(label: l10n.productDetailsDescriptionLabel),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          hint: l10n.productDetailsDescriptionHint,
          errorText: errors['description'],
          onChanged: notifier.updateDescription,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.md),
        // H2: short, one-line offer headline shown on the discovery card.
        _FieldLabel(label: l10n.productDetailsOfferHeadlineLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.productDetailsOfferHeadlineHelper,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _headlineController,
          maxLength: 50,
          hint: l10n.productDetailsOfferHeadlineHint,
          errorText: errors['offer_headline'],
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
                context,
                hint: l10n.productDetailsSelectCityHint,
                error: errors['preferred_city'],
              ),
              style: _inputTextStyle(context),
              icon: Icon(
                LucideIcons.chevronDown,
                size: 20,
                color: context.colors.onSurfaceVariant,
              ),
              items: cities
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name, style: _inputTextStyle(context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.updatePreferredCity(v);
              },
            ),
          loading: () => LinearProgressIndicator(
            color: context.colors.primary,
            backgroundColor: context.colors.darkBorder,
          ),
          error: (_, _) => Text(
            l10n.productDetailsFailedToLoadCities,
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.error),
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

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  String? error,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: KolabingTextStyles.bodySmall.copyWith(color: context.colors.textTertiary),
      errorText: error,
      errorStyle: KolabingTextStyles.bodySmall.copyWith(fontSize: 12),
      filled: true,
      fillColor: context.colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: 14,
      ),
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
        borderSide: BorderSide(color: context.colors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: BorderSide(color: context.colors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: BorderSide(color: context.colors.borderError, width: 1.5),
      ),
    );

TextStyle _inputTextStyle(BuildContext context) =>
    KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurface);

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
    );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: context.colors.onSurface),
    );
}
