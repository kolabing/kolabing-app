import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/onboarding_search_step.dart';
import '../../../../widgets/kolabing_button.dart';

/// Maximum number of target cities a free business may select. Premium is
/// unlimited (enforced both here and backend-side via the Business paywall).
const int kFreeTargetCityLimit = 3;

/// Product path step 2: multi-select target cities (<=3 free / unlimited
/// Premium). The free limit is enforced in the UI with explanatory copy; the
/// real entitlement is enforced by the backend.
class BusinessProductCitiesScreen extends ConsumerStatefulWidget {
  const BusinessProductCitiesScreen({super.key});

  @override
  ConsumerState<BusinessProductCitiesScreen> createState() =>
      _BusinessProductCitiesScreenState();
}

class _BusinessProductCitiesScreenState
    extends ConsumerState<BusinessProductCitiesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
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

  void _handleBack() => context.pop();

  void _handleContinue() {
    final data = ref.read(onboardingProvider);
    if (data == null || data.targetCityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).businessProductCitiesRequired,
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    context.push(KolabingRoutes.businessOnboardingProductAbout);
  }

  void _toggleCity(String id, String name) {
    // TODO(premium): wire isPremium from the entitlement/paywall provider once
    // exposed. Until then the UI enforces the free limit; the backend enforces
    // the real entitlement.
    ref
        .read(onboardingProvider.notifier)
        .toggleTargetCity(
          id,
          name,
          maxFreeCities: kFreeTargetCityLimit,
          onLimitReached: _showLimitReached,
        );
  }

  void _showLimitReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          ).businessProductCitiesLimitReached(kFreeTargetCityLimit),
        ),
        backgroundColor: context.colors.onSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final selectedIds = data?.targetCityIds ?? const [];
    final filteredCities = ref.watch(filteredCitiesProvider(_searchQuery));
    final canContinue = selectedIds.isNotEmpty;

    return OnboardingSearchStep(
      chrome: OnboardingHeader(
        currentStep: 3,
        totalSteps: 4,
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
              l10n.businessProductCitiesTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.businessProductCitiesSubtitle(kFreeTargetCityLimit),
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
      // The counter stays put while searching: "2 of 3" is the one thing a
      // multi-select reader needs to keep seeing as they pick.
      aboveResults: _SelectionCounter(
        selected: selectedIds.length,
        limit: kFreeTargetCityLimit,
      ),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return CityListItem(
                id: city.id,
                name: city.name,
                country: city.country,
                isSelected: selectedIds.contains(city.id),
                onTap: () => _toggleCity(city.id, city.name),
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
        error: (_, _) => OnboardingSearchMessage(
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

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({required this.selected, required this.limit});

  final int selected;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.softYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.softYellowBorder),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin, size: 16, color: context.colors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.businessProductCitiesCounter(selected, limit),
              style: KolabingTextStyles.captionSecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
