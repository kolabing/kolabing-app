import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../enums/deliverable_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';
import '../../widgets/multi_select_chips.dart';

/// Step 4 (venue / product flows): "BEST-FIT COMMUNITIES"
///
/// Collects:
///   - Community type chips (max 5), fetched from the existing
///     /lookup/community-types endpoint (shared with onboarding) — no longer
///     hardcoded client-side.
///   - Minimum community size (optional)
///   - What you expect from the community (deliverable toggle cards)
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class IdealCommunityScreen extends ConsumerStatefulWidget {
  const IdealCommunityScreen({super.key});

  @override
  ConsumerState<IdealCommunityScreen> createState() =>
      _IdealCommunityScreenState();
}

class _IdealCommunityScreenState extends ConsumerState<IdealCommunityScreen> {
  final _minSizeController = TextEditingController();

  bool _didInit = false;

  @override
  void dispose() {
    _minSizeController.dispose();
    super.dispose();
  }

  void _syncControllersFromState(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;

    _minSizeController.text = kolab.minCommunitySize != null
        ? kolab.minCommunitySize.toString()
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    _syncControllersFromState(kolab);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.lg,
        ),
        children: [
          // -- Section header
          Text(
            'BEST-FIT COMMUNITIES',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          Text(
            'Who would this Kolab be perfect for?',
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Choose a few. This helps the right communities understand the opportunity faster.',
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Community type chips (dynamic, via the existing shared
          // /lookup/community-types endpoint)
          Builder(builder: (context) {
            final communityTypesAsync = ref.watch(communityTypesProvider);
            final types = communityTypesAsync.when(
              data: (options) => options.map((o) => o.name).toList(),
              loading: () => const <String>[],
              error: (_, _) => const <String>[],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MultiSelectChips<String>(
                  items: types,
                  selected: kolab.seekingCommunities,
                  labelBuilder: (t) => t,
                  onToggle: notifier.toggleSeekingCommunity,
                  maxSelect: 5,
                ),
                if (communityTypesAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          }),
          const SizedBox(height: KolabingSpacing.lg),

          // -- Minimum Community Size
          Text(
            'MINIMUM COMMUNITY SIZE (OPTIONAL)',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          KolabingInput(
            controller: _minSizeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: 'e.g. 500',
            errorText: errors['min_community_size'],
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              notifier.updateMinCommunitySize(parsed);
            },
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // -- What you expect from the community
          Text(
            'WHAT DO YOU EXPECT FROM THE COMMUNITY?',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.md),

          ...DeliverableType.values.map((deliverable) {
            final isSelected = kolab.expects.contains(deliverable);
            return Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: _ToggleCard(
                title: deliverable.displayName,
                subtitle: deliverable.subtitle,
                isSelected: isSelected,
                onTap: () => notifier.toggleExpect(deliverable),
              ),
            );
          }),

          const SizedBox(height: KolabingSpacing.lg),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared helpers (file-private)
// =============================================================================

// =============================================================================
// Toggle Card
// =============================================================================

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.softYellow : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? context.colors.primary : Colors.transparent,
              borderRadius: KolabingRadius.borderRadiusXs,
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.darkBorder,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 14,
                    color: context.colors.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
