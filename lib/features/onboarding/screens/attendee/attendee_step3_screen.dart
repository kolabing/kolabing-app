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
import 'attendee_onboarding_scaffold.dart';

/// Attendee onboarding step 3 — "Interests". Multi-select chips populated
/// dynamically from `GET /community-types` ([communityTypesProvider]). Stores
/// the selected community-type SLUGS. Optional / skippable.
class AttendeeStep3Screen extends ConsumerWidget {
  const AttendeeStep3Screen({super.key});

  void _next(BuildContext context, WidgetRef ref) {
    ref.read(attendeeOnboardingProvider.notifier).goToStep(4);
    context.push('/onboarding/attendee/step4');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(attendeeOnboardingProvider);
    final typesAsync = ref.watch(communityTypesProvider);

    return AttendeeOnboardingScaffold(
      step: 3,
      title: l10n.attendeeOnboardingStep3Title,
      subtitle: l10n.attendeeOnboardingStep3Subtitle,
      primaryLabel: l10n.commonContinue,
      onBack: () => context.pop(),
      onSkip: () => _next(context, ref),
      onPrimary: () => _next(context, ref),
      child: typesAsync.when(
        data: (types) => Wrap(
          spacing: KolabingSpacing.sm,
          runSpacing: KolabingSpacing.sm,
          children: [
            for (final type in types)
              _InterestChip(
                label: type.name,
                icon: type.icon,
                selected: data.interests.contains(type.slug),
                onTap: () => ref
                    .read(attendeeOnboardingProvider.notifier)
                    .toggleInterest(type.slug),
              ),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: KolabingColors.primary),
          ),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: KolabingColors.error,
                  size: 40,
                ),
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  l10n.communityStep2LoadError,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(communityTypesProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? KolabingColors.primary
              : KolabingColors.surfaceVariant,
          borderRadius: BorderRadius.circular(KolabingRadius.round),
          border: Border.all(
            color: selected
                ? KolabingColors.primary
                : KolabingColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NOTE: `icon` is an icon KEY (e.g. "running"), not an emoji — never
            // render it as text. (Proper SVG icon is a follow-up; show the name.)
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: selected
                    ? KolabingColors.onPrimary
                    : KolabingColors.onSurface,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.check,
                size: 14,
                color: KolabingColors.onPrimary,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
