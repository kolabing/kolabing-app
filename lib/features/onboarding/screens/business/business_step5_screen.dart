import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/imported_photo_grid.dart';
import '../../../auth/models/user_model.dart';
import '../../models/business_type.dart';
import '../../models/onboarding_photo.dart';
import '../../models/place_suggestion.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/google_photos_preview_sheet.dart';
import '../../widgets/onboarding_header.dart';

/// Business onboarding step 1: capture the primary venue address and import
/// editable business details from Google Places.
class BusinessStep5Screen extends ConsumerStatefulWidget {
  const BusinessStep5Screen({super.key});

  @override
  ConsumerState<BusinessStep5Screen> createState() =>
      _BusinessStep5ScreenState();
}

class _BusinessStep5ScreenState extends ConsumerState<BusinessStep5Screen> {
  final _searchController = TextEditingController();
  PlaceSuggestion? _selectedPlace;
  String _query = '';
  bool _isImporting = false;

  /// After a successful Google import we show an inline, persistent preview of
  /// the imported photos (with per-photo delete) on this step rather than
  /// navigating away immediately, so the user actually sees what was imported.
  bool _showImportedPreview = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    if (ref.read(onboardingProvider) == null) {
      ref.read(onboardingProvider.notifier).initialize(UserType.business);
    }
    final existing = ref.read(onboardingProvider)?.location;
    if (existing != null) {
      _selectedPlace = existing;
      _searchController.text = existing.formattedAddress;
      _query = existing.formattedAddress;
    }
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() => context.pop();

  void _handleContinue() {
    final place = _selectedPlace;
    if (place == null || _isImporting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).businessStep5PickAddressError,
          ),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }
    ref.read(onboardingProvider.notifier).updateLocation(place);
    context.push('/onboarding/business/step2');
  }

  Future<void> _handlePlaceSelected(PlaceSuggestion place) async {
    if (_isImporting) return;

    setState(() {
      _selectedPlace = place;
      _searchController.text = place.formattedAddress;
      _query = place.formattedAddress;
      _isImporting = true;
    });

    ref.read(onboardingProvider.notifier).updateLocation(place);
    FocusScope.of(context).unfocus();

    try {
      final placeImport = await ref
          .read(onboardingServiceProvider)
          .getPlaceDetails(place.placeId);

      List<BusinessType> businessTypes = const [];
      try {
        businessTypes = await ref.read(businessTypesProvider.future);
      } on Exception {
        businessTypes = const [];
      }

      if (!mounted) return;

      Set<String>? allowedPhotoResourceNames;
      final importablePhotos = placeImport.primaryVenue.photos
          .where(
            (photo) =>
                photo.resourceName.trim().isNotEmpty &&
                photo.previewUrl.trim().isNotEmpty,
          )
          .toList(growable: false);
      if (importablePhotos.isNotEmpty) {
        // Pause the loading overlay while the user reviews — the overlay sits
        // above the modal otherwise.
        setState(() => _isImporting = false);
        allowedPhotoResourceNames = await GooglePhotosPreviewSheet.show(
          context,
          photos: importablePhotos,
        );
        if (!mounted) return;
      }

      ref
          .read(onboardingProvider.notifier)
          .applyPlaceImport(
            placeImport,
            businessTypes: businessTypes,
            allowedPhotoResourceNames: allowedPhotoResourceNames,
          );

      if (!mounted) return;

      // If the import brought in any photos, stay on this step and show them
      // in a persistent preview grid so the user can review/delete them before
      // continuing. Otherwise proceed straight to the details step.
      final importedPhotos = ref
          .read(onboardingProvider)
          ?.venuePhotos
          .where((photo) => photo.isGoogleImported)
          .toList(growable: false);
      if (importedPhotos != null && importedPhotos.isNotEmpty) {
        setState(() => _showImportedPreview = true);
      } else {
        context.push('/onboarding/business/step2');
      }
    } on PlaceImportUnavailableException {
      if (!mounted) return;
      _showImportFallbackToast();
      context.push('/onboarding/business/step2');
    } on Exception {
      if (!mounted) return;
      _showImportFallbackToast();
      context.push('/onboarding/business/step2');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showImportFallbackToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).businessStep5ImportFallback,
        ),
        backgroundColor: KolabingColors.error,
      ),
    );
  }

  void _handleContinueFromPreview() {
    if (_isImporting) return;
    context.push('/onboarding/business/step2');
  }

  void _removeImportedPhoto(String id) {
    final photos = ref.read(onboardingProvider)?.venuePhotos ?? const [];
    final index = photos.indexWhere((photo) => photo.id == id);
    if (index < 0) return;
    ref.read(onboardingProvider.notifier).removeVenuePhoto(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_showImportedPreview) {
      return _buildImportedPreviewScaffold();
    }

    final suggestions = ref.watch(placeSuggestionsProvider(_query.trim()));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  OnboardingHeader(
                    currentStep: 1,
                    totalSteps: 3,
                    onBack: _handleBack,
                    showSkip: false,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            AppLocalizations.of(context).businessStep5Title,
                            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).businessStep5Subtitle,
                            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _query = value;
                                if (_selectedPlace != null &&
                                    value != _selectedPlace!.formattedAddress) {
                                  _selectedPlace = null;
                                }
                              });
                            },
                            style: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.onSurface),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              ).businessStep5SearchHint,
                              hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
                              prefixIcon: const Icon(
                                LucideIcons.search,
                                size: 20,
                                color: KolabingColors.textTertiary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _query = '';
                                          _selectedPlace = null;
                                        });
                                      },
                                      icon: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: KolabingColors.textTertiary,
                                      ),
                                    )
                                  : null,
                              filled: true,
                              fillColor: KolabingColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: KolabingColors.darkBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: KolabingColors.darkBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: KolabingColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedPlace != null) ...[
                            _SelectedAddressCard(place: _selectedPlace!),
                            const SizedBox(height: 12),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Powered by Google',
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.textTertiary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: suggestions.when(
                              data: (items) {
                                if (_query.trim().length < 2) {
                                  return _buildHint(
                                    AppLocalizations.of(
                                      context,
                                    ).businessStep5HintStartTyping,
                                  );
                                }
                                if (items.isEmpty) {
                                  return _buildHint(
                                    AppLocalizations.of(
                                      context,
                                    ).businessStep5HintNoMatches,
                                  );
                                }
                                return ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        color: KolabingColors.darkBorder,
                                      ),
                                  itemBuilder: (context, index) {
                                    final place = items[index];
                                    final isSelected =
                                        _selectedPlace?.placeId ==
                                        place.placeId;
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      leading: Icon(
                                        isSelected
                                            ? LucideIcons.checkCircle2
                                            : LucideIcons.mapPin,
                                        color: isSelected
                                            ? KolabingColors.success
                                            : KolabingColors.textTertiary,
                                        size: 20,
                                      ),
                                      title: Text(
                                        place.title,
                                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                                      ),
                                      subtitle: Text(
                                        place.formattedAddress,
                                        style: KolabingTextStyles.captionSecondary.copyWith(color: KolabingColors.onSurfaceVariant),
                                      ),
                                      onTap: () => _handlePlaceSelected(place),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  color: KolabingColors.primary,
                                ),
                              ),
                              error: (error, _) => _buildHint(
                                AppLocalizations.of(
                                  context,
                                ).businessStep5SuggestionsError,
                              ),
                            ),
                          ),
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
                        onPressed: _selectedPlace != null && !_isImporting
                            ? _handleContinue
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KolabingColors.primary,
                          foregroundColor: KolabingColors.onPrimary,
                          disabledBackgroundColor: KolabingColors.primary
                              .withValues(alpha: 0.5),
                          disabledForegroundColor: KolabingColors.onPrimary
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context).commonContinue,
                          style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isImporting)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xB3FFFFFF),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: KolabingColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: KolabingColors.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            AppLocalizations.of(context).businessStep5Importing,
                            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  Widget _buildHint(String message) => Center(
    child: Text(
      message,
      style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
      textAlign: TextAlign.center,
    ),
  );

  /// Persistent in-step preview of the photos imported from Google, with a
  /// per-photo delete control. Shown after a successful import so the user can
  /// see and curate the imported photos before continuing.
  Widget _buildImportedPreviewScaffold() {
    final data = ref.watch(onboardingProvider);
    final importedPhotos = (data?.venuePhotos ?? const <OnboardingPhoto>[])
        .where((photo) => photo.isGoogleImported)
        .toList(growable: false);

    // If the user deletes every imported photo, fall back to the search view
    // so they can pick a different venue or proceed manually.
    final gridItems = importedPhotos
        .map(
          (photo) => ImportedPhotoItem(
            id: photo.id,
            url: photo.previewUrl ?? photo.remoteUrl ?? '',
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 1,
              totalSteps: 3,
              onBack: () => setState(() => _showImportedPreview = false),
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        AppLocalizations.of(context).businessStep5PreviewTitle,
                        style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).businessStep5PreviewSubtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (gridItems.isEmpty)
                      _buildHint(
                        AppLocalizations.of(
                          context,
                        ).businessStep5NoPhotosLeft,
                      )
                    else ...[
                      ImportedPhotoGrid(
                        photos: gridItems,
                        onRemove: _removeImportedPhoto,
                      ),
                      const SizedBox(height: 12),
                      const GoogleAttributionLabel(),
                    ],
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
                  onPressed: _isImporting ? null : _handleContinueFromPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor: KolabingColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: KolabingColors.onPrimary
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).commonContinue,
                    style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1),
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

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({required this.place});

  final PlaceSuggestion place;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: KolabingColors.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.checkCircle2,
              size: 18,
              color: KolabingColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).businessStep5SelectedAddress,
              style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          place.title,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          place.formattedAddress,
          style: KolabingTextStyles.captionSecondary.copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      ],
    ),
  );
}
