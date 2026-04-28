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
          colorScheme: const ColorScheme.light(
            primary: KolabingColors.primary,
            onPrimary: KolabingColors.onPrimary,
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
        const SnackBar(
          content: Text('Maximum 5 photos allowed'),
          backgroundColor: KolabingColors.warning,
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
        const SnackBar(
          content: Text('Maximum 1 video allowed'),
          backgroundColor: KolabingColors.warning,
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
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: KolabingColors.error,
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
            const SnackBar(
              content: Text('Event added successfully'),
              backgroundColor: KolabingColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add event'),
              backgroundColor: KolabingColors.error,
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
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
              color: KolabingColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Row(
              children: [
                Text(
                  'Add Past Event',
                  style: KolabingTextStyles.headlineSmall.copyWith(
                    color: isDark
                        ? KolabingColors.textOnDark
                        : KolabingColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  color: isDark
                      ? KolabingColors.textOnDark.withValues(alpha: 0.6)
                      : KolabingColors.textTertiary,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
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
                      label: 'Event Name',
                      hint: 'e.g., Summer Music Festival',
                      icon: LucideIcons.tag,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: KolabingSpacing.md),

                    // Partner Name
                    _buildTextField(
                      controller: _partnerController,
                      label: 'Collaborated With',
                      hint: 'e.g., Rock Community Istanbul',
                      icon: LucideIcons.users,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter partner name';
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
                      label: 'Attendee Count',
                      hint: 'e.g., 250',
                      icon: LucideIcons.userCheck,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter attendee count';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count <= 0) {
                          return 'Please enter a valid number';
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
                        backgroundColor: KolabingColors.primary,
                        foregroundColor: KolabingColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: KolabingSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: KolabingRadius.borderRadiusMd,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KolabingColors.onPrimary,
                              ),
                            )
                          : const Text('ADD EVENT'),
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
            color: KolabingColors.textPrimary,
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
              color: KolabingColors.textTertiary,
            ),
            prefixIcon: Icon(
              icon,
              color: KolabingColors.textTertiary,
              size: 20,
            ),
            filled: true,
            fillColor: KolabingColors.surfaceVariant,
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
              borderSide: const BorderSide(
                color: KolabingColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.error),
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
          'Event Date',
          style: KolabingTextStyles.labelMedium.copyWith(
            color: KolabingColors.textPrimary,
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
              color: KolabingColors.surfaceVariant,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  color: KolabingColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Text(
                  formattedDate,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronDown,
                  color: KolabingColors.textTertiary,
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
              'Event Photos',
              style: KolabingTextStyles.labelMedium.copyWith(
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              '(${_selectedPhotos.length}/5)',
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.textTertiary,
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
                      color: KolabingColors.surfaceVariant,
                      borderRadius: KolabingRadius.borderRadiusMd,
                      border: Border.all(
                        color: KolabingColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.imagePlus,
                          color: KolabingColors.textTertiary,
                          size: 28,
                        ),
                        const SizedBox(height: KolabingSpacing.xs),
                        Text(
                          'Add Photo',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: KolabingColors.textTertiary,
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
          'Recap Video (Optional)',
          style: KolabingTextStyles.labelMedium.copyWith(
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Add one short video to show how the event felt.',
          style: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        if (_selectedVideos.isEmpty)
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(LucideIcons.video, size: 18),
            label: const Text('ADD VIDEO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.textPrimary,
              side: const BorderSide(color: KolabingColors.border),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
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
                  color: KolabingColors.surfaceVariant,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: KolabingColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.video,
                      size: 18,
                      color: KolabingColors.textSecondary,
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        fileName,
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          color: KolabingColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeVideo(index),
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: KolabingColors.error,
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
