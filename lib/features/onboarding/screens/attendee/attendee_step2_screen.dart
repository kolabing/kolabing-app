import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/attendee_onboarding_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/city_list_item.dart';

/// Attendee onboarding step 2 — "City". Optional; reuses [citiesProvider] and
/// [filteredCitiesProvider] from the shared onboarding infra.
class AttendeeStep2Screen extends ConsumerStatefulWidget {
  const AttendeeStep2Screen({super.key});

  @override
  ConsumerState<AttendeeStep2Screen> createState() =>
      _AttendeeStep2ScreenState();
}

class _AttendeeStep2ScreenState extends ConsumerState<AttendeeStep2Screen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _next() {
    ref.read(attendeeOnboardingProvider.notifier).goToStep(3);
    context.push('/onboarding/attendee/step3');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(attendeeOnboardingProvider);
    final filtered = ref.watch(filteredCitiesProvider(_query));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: KolabingColors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.attendeeOnboardingStepCounter(2, 4),
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  TextButton(onPressed: _next, child: Text(l10n.commonSkip)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 2 / 4,
                  minHeight: 4,
                  backgroundColor: KolabingColors.surfaceVariant,
                  color: KolabingColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attendeeOnboardingStep2Title,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    l10n.attendeeOnboardingStep2Subtitle,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: KolabingColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.editProfileCitySearchHint,
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      filled: true,
                      fillColor: KolabingColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(KolabingRadius.sm),
                        borderSide: BorderSide(
                          color: KolabingColors.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KolabingSpacing.md,
                        vertical: KolabingSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.editProfileNoCitiesFound,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                    ),
                    itemCount: cities.length,
                    itemBuilder: (_, i) {
                      final city = cities[i];
                      return CityListItem(
                        id: city.id,
                        name: city.name,
                        country: city.country,
                        isSelected: data.cityId == city.id,
                        onTap: () {
                          ref
                              .read(attendeeOnboardingProvider.notifier)
                              .updateCity(city.id, city.name);
                          _next();
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: KolabingColors.primary,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.editProfileCityLoadError,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
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
    );
  }
}
