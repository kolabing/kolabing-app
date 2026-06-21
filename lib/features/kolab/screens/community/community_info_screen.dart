import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../../widgets/kolabing_selectable_chip.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 1: "YOUR COMMUNITY TYPE"
///
/// Lets the user pick up to 3 community type categories,
/// enter community size and expected attendees.
class CommunityInfoScreen extends ConsumerStatefulWidget {
  const CommunityInfoScreen({super.key});

  @override
  ConsumerState<CommunityInfoScreen> createState() =>
      _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends ConsumerState<CommunityInfoScreen> {
  final _communitySizeController = TextEditingController();
  final _attendanceController = TextEditingController();

  static const _communityTypeOptions = [
    'Food & Drink',
    'Sports',
    'Wellness',
    'Culture',
    'Technology',
    'Education',
    'Entertainment',
    'Fashion',
    'Music',
    'Art',
    'Travel',
    'Networking',
    'Fitness',
    'Social',
    'Gaming',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers();
    });
  }

  void _syncControllers() {
    final kolab = ref.read(kolabFormProvider).kolab;
    final sizeText = kolab.communitySize?.toString() ?? '';
    if (_communitySizeController.text != sizeText) {
      _communitySizeController.text = sizeText;
    }
    final attendanceText = kolab.typicalAttendance?.toString() ?? '';
    if (_attendanceController.text != attendanceText) {
      _attendanceController.text = attendanceText;
    }
  }

  @override
  void dispose() {
    _communitySizeController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;
    final selectedCount = kolab.communityTypes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title — Anton uppercase
          Text(
            l10n.communityInfoTypeHeader,
            style: KolabingTextStyles.sectionHeadingLarge.copyWith(
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.communityInfoTypeSubtitle,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),

          // Community types validation error
          if (state.fieldErrors['community_types'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(state.fieldErrors['community_types']!),
          ],

          const SizedBox(height: KolabingSpacing.md),

          // Community type chips
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: _communityTypeOptions.map((type) {
              final isSelected = kolab.communityTypes.contains(type);
              // Disable unselected chips once the limit of 3 is reached.
              // Selected chips are never disabled so they can be deselected.
              final isDisabled = selectedCount >= 3 && !isSelected;

              return KolabingSelectableChip(
                label: type,
                selected: isSelected,
                disabled: isDisabled,
                onTap: () => ref
                    .read(kolabFormProvider.notifier)
                    .toggleCommunityType(type),
              );
            }).toList(),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Community Size
          _buildLabel(l10n.communityInfoCommunitySizeLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          KolabingInput(
            controller: _communitySizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            // C1: number-pad has no return key — tap-outside is the only way out.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              ref.read(kolabFormProvider.notifier).updateCommunitySize(parsed);
            },
            hint: l10n.communityInfoCommunitySizeHint,
            errorText: state.fieldErrors['community_size'],
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Expected Attendees
          _buildLabel(l10n.communityInfoExpectedAttendeesLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          KolabingInput(
            controller: _attendanceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            // C1: number-pad has no return key — tap-outside is the only way out.
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              ref
                  .read(kolabFormProvider.notifier)
                  .updateTypicalAttendance(parsed);
            },
            hint: l10n.communityInfoExpectedAttendeesHint,
            errorText: state.fieldErrors['typical_attendance'],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: KolabingTextStyles.metaLabel.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );

  Widget _buildFieldError(String error) => Container(
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
            Icon(
              Icons.error_outline,
              size: 14,
              color: context.colors.error,
            ),
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
