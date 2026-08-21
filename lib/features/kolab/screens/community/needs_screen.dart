import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/category_icon.dart';
import '../../enums/need_type.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

/// Community step 0: "WHAT DO YOU NEED?"
///
/// The option LIST is admin-managed: it comes from [needsProvider]
/// (`GET /lookup/needs`, self-gating to the hardcoded launch list on 404/empty),
/// so admins can edit labels/icons/order or add options without an app release.
///
/// STORAGE stays on the strongly-typed [NeedType] enum (the wire contract):
/// each option's `slug` maps back to a [NeedType] via [NeedType.fromString], so
/// the payload (`needs[]`) and backend validation are unchanged. Any future
/// admin slug outside the enum collapses to [NeedType.other] until the enum +
/// model are migrated to slug storage.
class NeedsScreen extends ConsumerWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;
    final needOptionsAsync = ref.watch(needsProvider);

    // Admin-managed list; the provider's service already falls back to the
    // bundled list on 404/empty, but guard here so the grid is never empty
    // mid-flight.
    final options = needOptionsAsync.when(
      data: (data) => data,
      loading: () => const <OfferOption>[],
      error: (_, _) => const <OfferOption>[],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — bold uppercase Inter eyebrow label
          Text(
            l10n.needsScreenTitle,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.offeringSelectAllThatApply,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),

          // Validation error
          if (state.fieldErrors['needs'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(context, state.fieldErrors['needs']!),
          ],

          const SizedBox(height: KolabingSpacing.lg),

          // 2-column grid of admin-managed need options.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: KolabingSpacing.sm,
            crossAxisSpacing: KolabingSpacing.sm,
            childAspectRatio: 1.3,
            children: options.map((option) {
              // Map the admin slug onto the typed enum (the stored/wire value).
              final need = NeedType.fromString(option.slug);
              final isSelected = kolab.needs.contains(need);
              // Prefer the admin-provided label; fall back to the enum name so a
              // mid-flight empty name never renders blank.
              final label = option.name.isNotEmpty
                  ? option.name
                  : need.displayName;
              return GestureDetector(
                onTap: () =>
                    ref.read(kolabFormProvider.notifier).toggleNeed(need),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.softYellow
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.darkBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CategoryIcon(
                        name: option.name,
                        iconUrl: option.iconUrl,
                        size: 32,
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        label,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (needOptionsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldError(BuildContext context, String error) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colors.errorBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: context.colors.error),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.error,
            ),
          ),
        ),
      ],
    ),
  );
}
