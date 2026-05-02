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

/// Business onboarding step 5: capture the primary venue address with
/// Google Places-style autocomplete. The selected suggestion populates
/// `OnboardingData.location` (formattedAddress, placeId, latitude, longitude)
/// which the registration call sends as `primary_venue.*`.
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

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
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
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick your venue address from the suggestions'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }
    ref.read(onboardingProvider.notifier).updateLocation(place);
    context.push('/onboarding/business/final');
  }

  void _handlePlaceSelected(PlaceSuggestion place) {
    setState(() {
      _selectedPlace = place;
      _searchController.text = place.formattedAddress;
      _query = place.formattedAddress;
    });
    ref.read(onboardingProvider.notifier).updateLocation(place);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(placeSuggestionsProvider(_query.trim()));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              OnboardingHeader(
                currentStep: 4,
                totalSteps: 4,
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
                        'WHERE IS YOUR VENUE?',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search the address of your primary venue. We reuse this for every Kolab.',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textSecondary,
                        ),
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
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          color: KolabingColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search venue address',
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 16,
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
                      const SizedBox(height: 16),
                      if (_selectedPlace != null) ...[
                        _SelectedAddressCard(place: _selectedPlace!),
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: suggestions.when(
                          data: (items) {
                            if (_query.trim().length < 2) {
                              return _buildHint(
                                'Start typing your venue address to see suggestions.',
                              );
                            }
                            if (items.isEmpty) {
                              return _buildHint(
                                'No matches yet. Try adding the city to the address.',
                              );
                            }
                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                height: 1,
                                color: KolabingColors.border,
                              ),
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
                          error: (e, s) => _buildHint(
                            'Could not load suggestions. Try again in a moment.',
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
                    onPressed:
                        _selectedPlace != null ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
                      disabledBackgroundColor:
                          KolabingColors.primary.withValues(alpha: 0.5),
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

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({required this.place});

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
                    'Primary venue address',
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
                  if (place.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.city,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: KolabingColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
