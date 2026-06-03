import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';
import '../../widgets/onboarding_header.dart';

/// Community Onboarding Step 3: City Selection
class CommunityStep3Screen extends ConsumerStatefulWidget {
  const CommunityStep3Screen({super.key});

  @override
  ConsumerState<CommunityStep3Screen> createState() =>
      _CommunityStep3ScreenState();
}

class _CommunityStep3ScreenState extends ConsumerState<CommunityStep3Screen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
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

  void _handleBack() {
    context.pop();
  }

  void _handleContinue() {
    final data = ref.read(onboardingProvider);
    if (data?.cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).communityStep3CityRequired,
          ),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/community/step4');
  }

  void _handleCitySelected(String id, String name) {
    ref.read(onboardingProvider.notifier).updateCity(id, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final filteredCities = ref.watch(filteredCitiesProvider(_searchQuery));
    final canContinue = data?.cityId != null;

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            OnboardingHeader(
              currentStep: 3,
              onBack: _handleBack,
              showSkip: false,
            ),

            // Content
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          l10n.communityStep3Title,
                          style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          l10n.communityStep3Subtitle,
                          style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Search field
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.onSurface),
                          decoration: InputDecoration(
                            hintText: l10n.communityStep3SearchHint,
                            hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 20,
                              color: KolabingColors.textTertiary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 20,
                                      color: KolabingColors.textTertiary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: KolabingColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section label
                        if (_searchQuery.isEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.communityStep3PopularCities,
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.textTertiary),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cities list
                  Expanded(
                    child: filteredCities.when(
                      data: (cities) {
                        if (cities.isEmpty) {
                          return Center(
                            child: Text(
                              l10n.communityStep3NoCitiesFound,
                              style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            final city = cities[index];
                            return CityListItem(
                              id: city.id,
                              name: city.name,
                              country: city.country,
                              isSelected: data?.cityId == city.id,
                              onTap: () =>
                                  _handleCitySelected(city.id, city.name),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: KolabingColors.primary,
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: KolabingColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.communityStep3LoadError,
                              style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => ref.invalidate(citiesProvider),
                              child: Text(l10n.commonRetry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        KolabingColors.onPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1.0),
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
