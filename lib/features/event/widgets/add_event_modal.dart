import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// Modal for adding a new past event
class AddEventModal extends ConsumerStatefulWidget {
  const AddEventModal({super.key});

  @override
  ConsumerState<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends ConsumerState<AddEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();
  final _attendeeCountController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 30));
  final List<XFile> _selectedPhotos = [];
  final List<XFile> _selectedVideos = [];
  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    _attendeeCountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colors.primary,
            onPrimary: context.colors.onPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addEventMaxPhotos),
          backgroundColor: context.colors.warning,
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked.isNotEmpty) {
      setState(() {
        final remaining = 5 - _selectedPhotos.length;
        _selectedPhotos.addAll(picked.take(remaining));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  Future<void> _pickVideo() async {
    if (_selectedVideos.length >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addEventMaxVideos),
          backgroundColor: context.colors.warning,
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 90),
    );

    if (picked != null) {
      setState(() => _selectedVideos.add(picked));
    }
  }

  void _removeVideo(int index) {
    setState(() => _selectedVideos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addEventAtLeastOnePhoto),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = EventCreateRequest(
        name: _nameController.text.trim(),
        partnerName: _partnerController.text.trim(),
        partnerType: PartnerType.community,
        date: _selectedDate,
        attendeeCount: int.tryParse(_attendeeCountController.text) ?? 0,
        photoPaths: _selectedPhotos.map((p) => p.path).toList(),
        videoPaths: _selectedVideos.map((video) => video.path).toList(),
      );

      final success = await ref.read(eventsProvider.notifier).addEvent(request);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).addEventSuccess),
              backgroundColor: context.colors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).addEventFailure),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: KolabingSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Row(
              children: [
                Text(
                  l10n.addEventTitle,
                  style: KolabingTextStyles.headlineSmall.copyWith(
                    color: isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  color: isDark
                      ? context.colors.textOnDark.withValues(alpha: 0.6)
                      : context.colors.textTertiary,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? context.colors.darkBorder : context.colors.darkBorder,
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                KolabingSpacing.md,
                KolabingSpacing.md,
                KolabingSpacing.md,
                KolabingSpacing.md + bottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Event Name
                    _buildTextField(
                      controller: _nameController,
                      label: l10n.addEventNameLabel,
                      hint: l10n.addEventNameHint,
                      icon: LucideIcons.tag,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.addEventNameError;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: KolabingSpacing.md),

                    // Partner Name
                    _buildTextField(
                      controller: _partnerController,
                      label: l10n.addEventPartnerLabel,
                      hint: l10n.addEventPartnerHint,
                      icon: LucideIcons.users,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.addEventPartnerError;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: KolabingSpacing.md),

                    // Date Picker
                    _buildDatePicker(),

                    const SizedBox(height: KolabingSpacing.md),

                    // Attendee Count
                    _buildTextField(
                      controller: _attendeeCountController,
                      label: l10n.addEventAttendeeCountLabel,
                      hint: l10n.addEventAttendeeCountHint,
                      icon: LucideIcons.userCheck,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.addEventAttendeeCountError;
                        }
                        final count = int.tryParse(value);
                        if (count == null || count <= 0) {
                          return l10n.addEventAttendeeCountInvalid;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: KolabingSpacing.md),

                    // Photos
                    _buildPhotosPicker(),

                    const SizedBox(height: KolabingSpacing.md),

                    // Videos
                    _buildVideoPicker(),

                    const SizedBox(height: KolabingSpacing.lg),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: KolabingSpacing.md,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.onPrimary,
                              ),
                            )
                          : Text(l10n.addEventSubmitButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KolabingTextStyles.labelMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              color: context.colors.textTertiary,
              size: 20,
            ),
            filled: true,
            fillColor: context.colors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(color: context.colors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).addEventDateLabel,
          style: KolabingTextStyles.labelMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        InkWell(
          onTap: _selectDate,
          borderRadius: KolabingRadius.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: context.colors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Text(
                  formattedDate,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.chevronDown,
                  color: context.colors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).addEventPhotosLabel,
              style: KolabingTextStyles.labelMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).addEventPhotosCounter(_selectedPhotos.length),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.xs),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Photo Button
              if (_selectedPhotos.length < 5)
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: KolabingSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: KolabingRadius.borderRadiusMd,
                      border: Border.all(
                        color: context.colors.darkBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.imagePlus,
                          color: context.colors.textTertiary,
                          size: 28,
                        ),
                        const SizedBox(height: KolabingSpacing.xs),
                        Text(
                          AppLocalizations.of(context).addEventAddPhotoButton,
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Selected Photos
              ..._selectedPhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: KolabingSpacing.sm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: KolabingRadius.borderRadiusMd,
                        child: Image.file(
                          File(photo.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).addEventVideoLabel,
          style: KolabingTextStyles.labelMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          AppLocalizations.of(context).addEventVideoDescription,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        if (_selectedVideos.isEmpty)
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(LucideIcons.video, size: 18),
            label: Text(AppLocalizations.of(context).addEventAddVideoButton),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.onSurface,
              side: BorderSide(color: context.colors.darkBorder),
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          Column(
            children: List.generate(_selectedVideos.length, (index) {
              final video = _selectedVideos[index];
              final fileName = video.name.isNotEmpty
                  ? video.name
                  : video.path.split('/').last;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index == _selectedVideos.length - 1
                      ? 0
                      : KolabingSpacing.sm,
                ),
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: context.colors.darkBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.video,
                      size: 18,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        fileName,
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeVideo(index),
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: context.colors.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}
