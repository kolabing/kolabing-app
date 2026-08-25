import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/multi_kolab_role_application.dart';

/// Short application form: pitch (required) + availability (optional).
/// Deliberately minimal per the plan — no long-form fields.
class MultiKolabApplicationForm extends StatefulWidget {
  const MultiKolabApplicationForm({
    required this.onSubmit,
    super.key,
    this.isSubmitting = false,
  });

  final Future<void> Function(CreateMultiKolabApplicationInput input) onSubmit;
  final bool isSubmitting;

  @override
  State<MultiKolabApplicationForm> createState() =>
      _MultiKolabApplicationFormState();
}

class _MultiKolabApplicationFormState extends State<MultiKolabApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _pitchController = TextEditingController();
  final _availabilityController = TextEditingController();

  @override
  void dispose() {
    _pitchController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSubmit(
      CreateMultiKolabApplicationInput(
        pitch: _pitchController.text.trim(),
        availability: _availabilityController.text.trim().isEmpty
            ? null
            : _availabilityController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.multiKolabApplyFormPitchLabel,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          TextFormField(
            controller: _pitchController,
            maxLines: 4,
            maxLength: 2000,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              hintText: l10n.multiKolabApplyFormPitchHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.multiKolabApplyFormPitchRequired
                : null,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            l10n.multiKolabApplyFormAvailabilityLabel,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          TextFormField(
            controller: _availabilityController,
            maxLines: 2,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              hintText: l10n.multiKolabApplyFormAvailabilityHint,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          KolabingButton(
            label: l10n.multiKolabApplyFormSubmit,
            onPressed: widget.isSubmitting ? null : _submit,
            isLoading: widget.isSubmitting,
          ),
        ],
      ),
    );
  }
}
