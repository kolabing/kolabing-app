import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
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
///
/// "What you expect from the community" lives on the Offering step instead
/// (the same kolab.expects field, via the dynamic deliverablesProvider
/// multi-select) — not duplicated here.
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
        ],
      ),
    );
  }
}
