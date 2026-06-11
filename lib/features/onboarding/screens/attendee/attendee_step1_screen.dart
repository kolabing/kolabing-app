import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../identity/widgets/handle_field.dart';
import '../../providers/attendee_onboarding_provider.dart';
import 'attendee_onboarding_scaffold.dart';

/// Attendee onboarding step 1 — "You": display name, `@handle` (live
/// availability), and an optional photo. Name + handle are required.
class AttendeeStep1Screen extends ConsumerStatefulWidget {
  const AttendeeStep1Screen({super.key});

  @override
  ConsumerState<AttendeeStep1Screen> createState() => _AttendeeStep1ScreenState();
}

class _AttendeeStep1ScreenState extends ConsumerState<AttendeeStep1Screen> {
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _handleOk = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(attendeeOnboardingProvider);
    _nameController.text = data.name;
    _handleController.text = data.handle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(attendeeOnboardingProvider.notifier).updatePhoto(
      File(picked.path),
    );
  }

  void _continue() {
    ref.read(attendeeOnboardingProvider.notifier)
      ..updateName(_nameController.text.trim())
      ..updateHandle(_handleController.text)
      ..goToStep(2);
    context.push('/onboarding/attendee/step2');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(attendeeOnboardingProvider);
    final nameOk = _nameController.text.trim().isNotEmpty;

    return AttendeeOnboardingScaffold(
      step: 1,
      title: l10n.attendeeOnboardingStep1Title,
      subtitle: l10n.attendeeOnboardingStep1Subtitle,
      primaryLabel: l10n.commonContinue,
      canProceed: nameOk && _handleOk,
      onPrimary: _continue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  _AvatarPreview(
                    photoBase64: data.photoBase64,
                    initial: _initialOf(_nameController.text),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(KolabingSpacing.xs),
                      decoration: const BoxDecoration(
                        color: KolabingColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        size: 16,
                        color: KolabingColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Text(
                l10n.attendeeOnboardingAddPhoto,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Name
          Text(
            l10n.attendeeOnboardingNameLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.attendeeOnboardingNameHint,
              filled: true,
              fillColor: KolabingColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KolabingRadius.sm),
                borderSide: BorderSide(color: KolabingColors.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm + 2,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Handle
          Text(
            l10n.attendeeOnboardingHandleLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          HandleField(
            controller: _handleController,
            onChanged: (handle, ok) {
              if (ok != _handleOk && mounted) {
                setState(() => _handleOk = ok);
              }
            },
          ),
        ],
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.photoBase64, required this.initial});

  final String? photoBase64;
  final String initial;
  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          base64Decode(photoBase64!),
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: KolabingColors.primary, width: 3),
      ),
      child: Center(
        child: Text(
          initial,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: KolabingColors.primary,
          ),
        ),
      ),
    );
  }
}
