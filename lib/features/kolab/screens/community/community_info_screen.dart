import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 1: expected attendees for THIS kolab.
///
/// Community type and community size are NOT asked here — they are
/// self-describing fields that already live on the community profile (set at
/// onboarding, editable from the profile) and are inherited by the backend
/// (KolabService::enrichCommunitySeekingData). Only `typical_attendance` is a
/// genuine per-kolab input (it varies per event), so it pre-fills from the last
/// kolab but stays editable here.
class CommunityInfoScreen extends ConsumerStatefulWidget {
  const CommunityInfoScreen({super.key});

  @override
  ConsumerState<CommunityInfoScreen> createState() =>
      _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends ConsumerState<CommunityInfoScreen> {
  final _attendanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers();
    });
  }

  void _syncControllers() {
    final kolab = ref.read(kolabFormProvider).kolab;
    final attendanceText = kolab.typicalAttendance?.toString() ?? '';
    if (_attendanceController.text != attendanceText) {
      _attendanceController.text = attendanceText;
    }
  }

  @override
  void dispose() {
    _attendanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kolabFormProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expected Attendees (per-kolab; type + size come from the profile)
          _buildLabel(l10n.communityInfoExpectedAttendeesLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
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
            style: KolabingTextStyles.bodySmall
                .copyWith(fontSize: 15, color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: l10n.communityInfoExpectedAttendeesHint,
              hintStyle: KolabingTextStyles.bodyMedium
                  .copyWith(color: context.colors.textTertiary),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusSm,
                borderSide: BorderSide(color: context.colors.error),
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
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      );
}
