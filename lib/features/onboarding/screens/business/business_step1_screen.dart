import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../models/place_suggestion.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Business onboarding step 1: choose the primary venue location.
class BusinessStep1Screen extends ConsumerStatefulWidget {
  const BusinessStep1Screen({super.key});

  @override
  ConsumerState<BusinessStep1Screen> createState() => _BusinessStep1ScreenState();
}

class _BusinessStep1ScreenState extends ConsumerState<BusinessStep1Screen> {
  final _searchController = TextEditingController();
  PlaceSuggestion? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    final data = ref.read(onboardingProvider);
    final location = data?.location;
    if (location != null) {
      _selectedPlace = location;
      _searchController.text = location.formattedAddress;
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

  void _handleBack() {
    context.pop();
  }

  void _handleContinue() {
    final place = _selectedPlace;
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose your location from the suggestions'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    ref.read(onboardingProvider.notifier).updateLocation(place);
    context.push('/onboarding/business/step2');
  }

  void _handlePlaceSelected(PlaceSuggestion place) {
    setState(() {
      _selectedPlace = place;
      _searchController.text = place.formattedAddress;
    });
    ref.read(onboardingProvider.notifier).updateLocation(place);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final suggestions = ref.watch(placeSuggestionsProvider(query));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 1,
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
                      'WHERE ARE YOU LOCATED?',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your main venue with Google Maps-style autocomplete so we can reuse it in every future Kolab.',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        setState(() {
                          if (_selectedPlace != null &&
                              _searchController.text !=
                                  _selectedPlace!.formattedAddress) {
                            _selectedPlace = null;
                          }
                        });
                      },
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search your venue address',
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
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
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
                            color: KolabingColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: KolabingColors.border,
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
                    const SizedBox(height: 20),
                    if (_selectedPlace != null) ...[
                      _SelectedLocationCard(place: _selectedPlace!),
                      const SizedBox(height: 20),
                    ],
                    Expanded(
                      child: suggestions.when(
                        data: (items) {
                          if (query.length < 2) {
                            return _buildHint(
                              'Start typing your venue address to see matching places.',
                            );
                          }
                          if (items.isEmpty) {
                            return _buildHint(
                              'No locations found yet. Try a broader city or venue name.',
                            );
                          }
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: KolabingColors.border),
                            itemBuilder: (context, index) {
                              final place = items[index];
                              final isSelected =
                                  _selectedPlace?.placeId == place.placeId;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  isSelected
                                      ? LucideIcons.checkCircle2
                                      : LucideIcons.mapPin,
                                  size: 20,
                                  color: isSelected
                                      ? KolabingColors.primary
                                      : KolabingColors.textTertiary,
                                ),
                                title: Text(
                                  place.title,
                                  style: GoogleFonts.openSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: KolabingColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  place.displaySubtitle,
                                  style: GoogleFonts.openSans(
                                    fontSize: 13,
                                    color: KolabingColors.textSecondary,
                                  ),
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
                        error: (_, _) => _buildHint(
                          'We could not load place suggestions right now. Try again in a moment.',
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
                  onPressed: _selectedPlace != null ? _handleContinue : null,
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

  Widget _buildHint(String text) => Center(
        child: Text(
          text,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
}

class _SelectedLocationCard extends StatelessWidget {
  const _SelectedLocationCard({required this.place});

  final PlaceSuggestion place;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KolabingColors.softYellowBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 20,
              color: KolabingColors.primaryDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary venue location',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.formattedAddress,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.city,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
