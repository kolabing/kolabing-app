import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kolabing_button.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/onboarding_search_step.dart';

/// Community Onboarding Step 3: City Selection.
///
/// Laid out by [OnboardingSearchStep], which owns the keyboard behaviour. This
/// screen used to build its own `Column` and, with the keyboard open, drew the
/// Continue button on top of the search field (#163).
class CommunityStep3Screen extends ConsumerStatefulWidget {
  const CommunityStep3Screen({super.key});

  @override
  ConsumerState<CommunityStep3Screen> createState() =>
      _CommunityStep3ScreenState();
}

class _CommunityStep3ScreenState extends ConsumerState<CommunityStep3Screen> {
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
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/community/step4');
  }

  /// Picking a city closes the keyboard, which brings the footer back with
  /// Continue already enabled — the next action lands under the thumb one tap
  /// after the choice.
  void _handleCitySelected(String id, String name) {
    FocusScope.of(context).unfocus();
    ref.read(onboardingProvider.notifier).updateCity(id, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final filteredCities = ref.watch(filteredCitiesProvider(_searchQuery));
    final canContinue = data?.isStep3Complete ?? false;

    return OnboardingSearchStep(
      chrome: OnboardingHeader(
        currentStep: 3,
        onBack: _handleBack,
        showSkip: false,
      ),
      headline: Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.lg,
          KolabingSpacing.xl,
          KolabingSpacing.lg,
          KolabingSpacing.md,
        ),
        child: Column(
          children: [
            Text(
              l10n.communityStep3Title,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.communityStep3Subtitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      searchHint: l10n.communityStep3SearchHint,
      onQueryChanged: (value) => setState(() => _searchQuery = value),
      aboveResults: _searchQuery.isEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.communityStep3PopularCities,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textTertiary,
                ),
              ),
            )
          : null,
      results: filteredCities.when(
        data: (cities) {
          if (cities.isEmpty) {
            return OnboardingSearchMessage(
              icon: LucideIcons.mapPin,
              text: l10n.communityStep3NoCitiesFound,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.zero,
            // A drag closes the keyboard, so the footer is always reachable
            // without having to pick something first.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return CityListItem(
                id: city.id,
                name: city.name,
                country: city.country,
                isSelected: data?.cityId == city.id,
                onTap: () => _handleCitySelected(city.id, city.name),
              );
            },
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
        ),
        error: (error, stack) => OnboardingSearchMessage(
          icon: LucideIcons.alertCircle,
          text: l10n.communityStep3LoadError,
          action: TextButton(
            onPressed: () => ref.invalidate(citiesProvider),
            child: Text(l10n.commonRetry),
          ),
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: KolabingButton(
          label: l10n.commonContinue,
          onPressed: canContinue ? _handleContinue : null,
          variant: KolabingButtonVariant.primary,
          isDisabled: !canContinue,
        ),
      ),
    );
  }
}
