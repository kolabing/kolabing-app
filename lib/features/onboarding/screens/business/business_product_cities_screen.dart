import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';
import '../../widgets/onboarding_header.dart';

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
  final _searchController = TextEditingController();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          AppLocalizations.of(context).businessProductCitiesLimitReached(
            kFreeTargetCityLimit,
          ),
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

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 3,
              totalSteps: 4,
              onBack: _handleBack,
              showSkip: false,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    l10n.businessProductCitiesTitle,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.businessProductCitiesSubtitle(kFreeTargetCityLimit),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _SelectionCounter(
                    selected: selectedIds.length,
                    limit: kFreeTargetCityLimit,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.communityStep3SearchHint,
                      hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 20,
                        color: context.colors.textTertiary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: context.colors.textTertiary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: context.colors.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: filteredCities.when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.communityStep3NoCitiesFound,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
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
                        isSelected: selectedIds.contains(city.id),
                        onTap: () => _toggleCity(city.id, city.name),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: context.colors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.communityStep3LoadError,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
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
          Icon(
            LucideIcons.mapPin,
            size: 16,
            color: context.colors.primaryDark,
          ),
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
