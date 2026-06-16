import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/models/user_model.dart';
import '../../../kolab/enums/product_type.dart';
import '../../../kolab/models/offer_option.dart';
import '../../../kolab/providers/offer_option_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/photo_upload_widget.dart';
import '../../widgets/type_selection_card.dart';

/// Product path step 1: business identity (name + category pills + logo).
///
/// Reached when the business chose "Promote a product/service" on the goal
/// step ([OnboardingData.hasVenue] == false). No physical venue is collected.
class BusinessProductIdentityScreen extends ConsumerStatefulWidget {
  const BusinessProductIdentityScreen({super.key});

  @override
  ConsumerState<BusinessProductIdentityScreen> createState() =>
      _BusinessProductIdentityScreenState();
}

class _BusinessProductIdentityScreenState
    extends ConsumerState<BusinessProductIdentityScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    final data = ref.read(onboardingProvider);
    if (data == null) {
      ref.read(onboardingProvider.notifier).initialize(UserType.business);
      ref.read(onboardingProvider.notifier).selectBusinessGoal(hasVenue: false);
    }
    _nameController.text = ref.read(onboardingProvider)?.name ?? '';
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleBack() => context.pop();

  void _handleContinue() {
    final data = ref.read(onboardingProvider);
    if (data == null || !data.isStep1Complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).businessProductIdentityIncomplete,
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    context.push(KolabingRoutes.businessOnboardingProductCities);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final businessTypes = ref.watch(businessTypesProvider);

    // Admin-managed product-type list (GET /lookup/product-types); the service
    // self-gates to the bundled list on 404/empty. Stored as the slug
    // (data.productType, the wire value) and sent as `product_type`.
    final productTypeOptionsAsync = ref.watch(productTypesProvider);
    final productTypeOptions = productTypeOptionsAsync.when(
      data: (options) => options,
      loading: () => const <OfferOption>[],
      error: (_, _) => const <OfferOption>[],
    );
    final selectedProductType = data?.productType;

    final selectedTypeIds = businessTypes.maybeWhen(
      data: (types) => types
          .where(
            (type) =>
                data?.selectedBusinessTypeSlugs.contains(type.slug) ?? false,
          )
          .map((type) => type.id)
          .toList(growable: false),
      orElse: () => data?.selectedBusinessTypeIds ?? const [],
    );

    final canContinue = data?.isStep1Complete ?? false;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 2,
              totalSteps: 4,
              onBack: _handleBack,
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        l10n.businessProductIdentityTitle,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.businessProductIdentitySubtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PhotoUploadWidget(
                      photoBase64: data?.photoBase64,
                      onPhotoSelected: notifier.updatePhoto,
                      onPhotoRemoved: notifier.clearPhoto,
                      addLabel: l10n.businessStep2AddLogo,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: l10n.businessProductNameLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 255,
                      onChanged: notifier.updateName,
                      decoration: _inputDecoration(
                        context,
                        hint: l10n.businessProductNameHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel(label: l10n.businessProductCategoryLabel),
                    const SizedBox(height: 4),
                    Text(
                      l10n.businessProductCategoryHint,
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    businessTypes.when(
                      // Product/service path: hide venue-only categories so a
                      // non-venue business sees only product/both categories
                      // (admin-controlled via business_types.applies_to).
                      data: (allTypes) {
                        final types =
                            allTypes.where((t) => t.isForProduct).toList();
                        return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          return TypeSelectionCard(
                            id: type.id,
                            name: type.name,
                            icon: type.icon,
                            iconUrl: type.iconUrl,
                            isSelected: selectedTypeIds.contains(type.id),
                            onTap: () => notifier.toggleBusinessType(type),
                          );
                        },
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                        ),
                      ),
                      error: (_, __) => Text(
                        l10n.businessStep2BusinessTypesLoadError,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // -- Product type (admin-managed; drives the auto-offer).
                    _FieldLabel(label: l10n.businessProductTypeLabel),
                    const SizedBox(height: 4),
                    Text(
                      l10n.businessProductTypeHint,
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: productTypeOptions.map((option) {
                        // Map the admin slug onto the typed enum for the icon;
                        // storage stays on the slug (the wire value).
                        final type = ProductType.fromString(option.slug);
                        final isSelected = selectedProductType == option.slug;
                        // Prefer the admin label; fall back to the enum name.
                        final label = option.name.isNotEmpty
                            ? option.name
                            : type.displayName;
                        return GestureDetector(
                          onTap: () => notifier.updateProductType(
                            isSelected ? null : option.slug,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.darkBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 16,
                                  color: isSelected
                                      ? context.colors.onPrimary
                                      : context.colors.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: KolabingTextStyles.bodySmall.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? context.colors.onPrimary
                                        : context.colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (productTypeOptionsAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor: context.colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: context.colors.onPrimary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: KolabingTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: context.colors.onSurface,
    ),
  );
}

InputDecoration _inputDecoration(BuildContext context, {required String hint}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.textTertiary,
      ),
      filled: true,
      fillColor: context.colors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.primary, width: 1.5),
      ),
    );
