import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
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
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'YOUR COMMUNITY TYPE',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Help businesses understand your audience. Select up to 3.',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
          ),

          // Community types error
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
              final isMaxReached =
                  kolab.communityTypes.length >= 3 && !isSelected;

              return GestureDetector(
                onTap: isMaxReached
                    ? null
                    : () => ref
                        .read(kolabFormProvider.notifier)
                        .toggleCommunityType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: KolabingSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KolabingColors.softYellow
                        : KolabingColors.surface,
                    borderRadius: KolabingRadius.borderRadiusSm,
                    border: Border.all(
                      color: isSelected
                          ? KolabingColors.primary
                          : KolabingColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isMaxReached
                          ? KolabingColors.textTertiary
                          : isSelected
                              ? KolabingColors.textPrimary
                              : KolabingColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Community Size
          _buildLabel('COMMUNITY SIZE'),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _communitySizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final parsed = int.tryParse(value);
              ref.read(kolabFormProvider.notifier).updateCommunitySize(parsed);
            },
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: KolabingColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., 500',
              hintStyle: GoogleFonts.openSans(
                color: KolabingColors.textTertiary,
              ),
              filled: true,
              fillColor: KolabingColors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    const BorderSide(color: KolabingColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.error),
              ),
              errorText: state.fieldErrors['community_size'],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Expected Attendees
          _buildLabel('EXPECTED ATTENDEES'),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _attendanceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final parsed = int.tryParse(value);
              ref
                  .read(kolabFormProvider.notifier)
                  .updateTypicalAttendance(parsed);
            },
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: KolabingColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., 50',
              hintStyle: GoogleFonts.openSans(
                color: KolabingColors.textTertiary,
              ),
              filled: true,
              fillColor: KolabingColors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide:
                    const BorderSide(color: KolabingColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: const BorderSide(color: KolabingColors.error),
              ),
              errorText: state.fieldErrors['typical_attendance'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textSecondary,
          letterSpacing: 1.0,
        ),
      );

  Widget _buildFieldError(String error) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.errorBg,
          borderRadius: KolabingRadius.borderRadiusSm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 14,
              color: KolabingColors.error,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.error,
                ),
              ),
            ),
          ],
        ),
      );
}
