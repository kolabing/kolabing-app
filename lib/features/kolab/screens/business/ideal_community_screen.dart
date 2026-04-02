import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../enums/deliverable_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';
import '../../widgets/multi_select_chips.dart';

/// Step 3 (venue / product flows): "IDEAL COMMUNITY"
///
/// Collects:
///   - Community type chips (max 5)
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

  static const List<String> _communityTypes = [
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

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          'IDEAL COMMUNITY',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          'What kind of communities would be a great fit?',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Community type chips
        MultiSelectChips<String>(
          items: _communityTypes,
          selected: kolab.seekingCommunities,
          labelBuilder: (t) => t,
          onToggle: notifier.toggleSeekingCommunity,
          maxSelect: 5,
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Minimum Community Size
        Text(
          'MINIMUM COMMUNITY SIZE (OPTIONAL)',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        TextField(
          controller: _minSizeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            hint: 'e.g. 500',
            error: errors['min_community_size'],
          ),
          style: _inputTextStyle,
          onChanged: (v) {
            final parsed = int.tryParse(v);
            notifier.updateMinCommunitySize(parsed);
          },
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- What you expect from the community
        Text(
          'WHAT DO YOU EXPECT FROM THE COMMUNITY?',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
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
    );
  }
}

// =============================================================================
// Shared helpers (file-private)
// =============================================================================

InputDecoration _inputDecoration({
  required String hint,
  String? error,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        fontSize: 14,
        color: KolabingColors.textTertiary,
      ),
      errorText: error,
      errorStyle: GoogleFonts.openSans(fontSize: 12),
      filled: true,
      fillColor: KolabingColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: 14,
      ),
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
        borderSide: const BorderSide(
          color: KolabingColors.borderFocus,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(
          color: KolabingColors.borderError,
          width: 1.5,
        ),
      ),
    );

TextStyle get _inputTextStyle => GoogleFonts.openSans(
      fontSize: 14,
      color: KolabingColors.textPrimary,
    );

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
          color:
              isSelected ? KolabingColors.softYellow : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color:
                isSelected ? KolabingColors.primary : KolabingColors.border,
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
                color: isSelected
                    ? KolabingColors.primary
                    : Colors.transparent,
                borderRadius: KolabingRadius.borderRadiusXs,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: KolabingColors.onPrimary,
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
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
