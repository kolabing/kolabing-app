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
import '../../widgets/onboarding_search_step.dart';

/// Attendee onboarding step 2 — "City". Optional; reuses [citiesProvider] and
/// [filteredCitiesProvider] from the shared onboarding infra.
///
/// Laid out by [OnboardingSearchStep] (#163): with the keyboard open, this
/// screen's own `Column` left the results list a couple of pixels and hid the
/// "no cities found" message behind the keyboard.
class AttendeeStep2Screen extends ConsumerStatefulWidget {
  const AttendeeStep2Screen({super.key});

  @override
  ConsumerState<AttendeeStep2Screen> createState() =>
      _AttendeeStep2ScreenState();
}

class _AttendeeStep2ScreenState extends ConsumerState<AttendeeStep2Screen> {
  String _query = '';

  void _next() {
    ref.read(attendeeOnboardingProvider.notifier).goToStep(3);
    context.push('/onboarding/attendee/step3');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(attendeeOnboardingProvider);
    final filtered = ref.watch(filteredCitiesProvider(_query));

    return OnboardingSearchStep(
      horizontalPadding: KolabingSpacing.md,
      chrome: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KolabingRadius.xs),
              child: const LinearProgressIndicator(
                value: 2 / 4,
                minHeight: 4,
                backgroundColor: KolabingColors.surfaceVariant,
                color: KolabingColors.primary,
              ),
            ),
          ),
        ],
      ),
      headline: Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.sm,
        ),
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
          ],
        ),
      ),
      searchHint: l10n.editProfileCitySearchHint,
      onQueryChanged: (value) => setState(() => _query = value),
      results: filtered.when(
        data: (cities) {
          if (cities.isEmpty) {
            return OnboardingSearchMessage(
              icon: LucideIcons.mapPin,
              text: l10n.editProfileNoCitiesFound,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: cities.length,
            itemBuilder: (_, i) {
              final city = cities[i];
              return CityListItem(
                id: city.id,
                name: city.name,
                country: city.country,
                isSelected: data.cityId == city.id,
                onTap: () {
                  // The city IS the answer on this step, so picking one both
                  // closes the keyboard and moves on.
                  FocusScope.of(context).unfocus();
                  ref
                      .read(attendeeOnboardingProvider.notifier)
                      .updateCity(city.id, city.name);
                  _next();
                },
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(KolabingSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: KolabingColors.primary),
          ),
        ),
        error: (_, _) => OnboardingSearchMessage(
          icon: LucideIcons.alertCircle,
          text: l10n.editProfileCityLoadError,
          action: TextButton(
            onPressed: () => ref.invalidate(citiesProvider),
            child: Text(l10n.commonRetry),
          ),
        ),
      ),
    );
  }
}
