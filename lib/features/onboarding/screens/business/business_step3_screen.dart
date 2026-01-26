import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';
import '../../widgets/onboarding_header.dart';

/// Business Onboarding Step 3: City Selection
class BusinessStep3Screen extends ConsumerStatefulWidget {
  const BusinessStep3Screen({super.key});

  @override
  ConsumerState<BusinessStep3Screen> createState() => _BusinessStep3ScreenState();
}

class _BusinessStep3ScreenState extends ConsumerState<BusinessStep3Screen> {
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
        const SnackBar(
          content: Text('Please select a city'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/business/step4');
  }

  void _handleCitySelected(String id, String name) {
    ref.read(onboardingProvider.notifier).updateCity(id, name);
  }

  @override
  Widget build(BuildContext context) {
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
                          'WHERE ARE YOU LOCATED?',
                          style: GoogleFonts.rubik(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Select your city to connect with local communities',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textSecondary,
                          ),
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
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search cities...',
                            hintStyle: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: KolabingColors.textTertiary,
                            ),
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
                              'Popular Cities:',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: KolabingColors.textTertiary,
                              ),
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
                              'No cities found',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: KolabingColors.textSecondary,
                              ),
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
                              'Failed to load cities',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: KolabingColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => ref.invalidate(citiesProvider),
                              child: const Text('Retry'),
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
                    disabledBackgroundColor: KolabingColors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor: KolabingColors.onPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
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
