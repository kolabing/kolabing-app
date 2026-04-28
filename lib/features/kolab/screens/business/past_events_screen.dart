import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../services/upload_service.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 4 (venue / product flows): "PAST COLLABORATIONS (optional)"
///
/// Lists existing past events and lets the user add up to 5 entries.
/// Each entry has: name, date picker, partner name, and photo placeholders.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class PastEventsScreen extends ConsumerStatefulWidget {
  const PastEventsScreen({super.key});

  @override
  ConsumerState<PastEventsScreen> createState() => _PastEventsScreenState();
}

class _PastEventsScreenState extends ConsumerState<PastEventsScreen> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final notifier = ref.read(kolabFormProvider.notifier);
    final events = kolab.pastEvents;
    final canAdd = events.length < 5;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          'PAST COLLABORATIONS (OPTIONAL)',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          'Show communities what events have been hosted at your venue before.',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Existing events
        for (int i = 0; i < events.length; i++) ...[
          _PastEventEntry(
            index: i,
            event: events[i],
            onUpdate: (updated) => notifier.updatePastEvent(i, updated),
            onRemove: () => notifier.removePastEvent(i),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],

        // -- Add button
        if (canAdd)
          GestureDetector(
            onTap: () {
              notifier.addPastEvent(PastEvent(name: '', date: DateTime.now()));
            },
            child: Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: KolabingColors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: KolabingColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.plus,
                    size: 20,
                    color: KolabingColors.textSecondary,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Text(
                    'Add a past event',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

// =============================================================================
// Past Event Entry Card
// =============================================================================

class _PastEventEntry extends StatefulWidget {
  const _PastEventEntry({
    required this.index,
    required this.event,
    required this.onUpdate,
    required this.onRemove,
  });

  final int index;
  final PastEvent event;
  final void Function(PastEvent) onUpdate;
  final VoidCallback onRemove;

  @override
  State<_PastEventEntry> createState() => _PastEventEntryState();
}

class _PastEventEntryState extends State<_PastEventEntry> {
  late final TextEditingController _nameController;
  late final TextEditingController _partnerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _partnerController = TextEditingController(
      text: widget.event.partnerName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.event.date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: KolabingColors.primary,
            onPrimary: KolabingColors.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      widget.onUpdate(widget.event.copyWith(date: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMM d, yyyy').format(widget.event.date);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Header row
          Row(
            children: [
              Text(
                'Event ${widget.index + 1}',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: KolabingColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Event Name
          Text(
            'Event Name',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(hint: 'e.g. Summer Wellness Meetup'),
            style: _inputTextStyle,
            onChanged: (v) {
              widget.onUpdate(widget.event.copyWith(name: v));
            },
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Date
          Text(
            'Date',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: KolabingColors.surface,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: KolabingColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(dateFormatted, style: _inputTextStyle)),
                  const Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: KolabingColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Partner Name
          Text(
            'Partner Name',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextField(
            controller: _partnerController,
            decoration: _inputDecoration(hint: 'e.g. City Runners Club'),
            style: _inputTextStyle,
            onChanged: (v) {
              widget.onUpdate(
                widget.event.copyWith(
                  partnerName: v.isNotEmpty ? v : null,
                  clearPartnerName: v.isEmpty,
                ),
              );
            },
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Photos (max 3 per event)
          Text(
            'Photos (max 3)',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _EventPhotoRow(
            photos: widget.event.photos,
            onAdd: () async {
              if (widget.event.photos.length >= 3) return;
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                maxHeight: 1920,
                imageQuality: 85,
              );
              if (image == null) return;
              try {
                final uploadService = UploadService();
                final url = await uploadService.upload(
                  filePath: image.path,
                  folder: 'kolabs',
                );
                final updated = [...widget.event.photos, url];
                widget.onUpdate(widget.event.copyWith(photos: updated));
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                }
              }
            },
            onRemove: (photoIndex) {
              final updated = List<String>.from(widget.event.photos)
                ..removeAt(photoIndex);
              widget.onUpdate(widget.event.copyWith(photos: updated));
            },
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Videos (max 1 per event)
          Text(
            'Recap Video (max 1)',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          _EventVideoRow(
            videos: widget.event.videos,
            onAdd: () async {
              if (widget.event.videos.isNotEmpty) return;
              final picker = ImagePicker();
              final video = await picker.pickVideo(
                source: ImageSource.gallery,
                maxDuration: const Duration(seconds: 90),
              );
              if (video == null) return;
              try {
                final uploadService = UploadService();
                final url = await uploadService.upload(
                  filePath: video.path,
                  folder: 'kolabs',
                );
                final updated = [...widget.event.videos, url];
                widget.onUpdate(widget.event.copyWith(videos: updated));
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                }
              }
            },
            onRemove: (videoIndex) {
              final updated = List<String>.from(widget.event.videos)
                ..removeAt(videoIndex);
              widget.onUpdate(widget.event.copyWith(videos: updated));
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Event Photo Row
// =============================================================================

class _EventPhotoRow extends StatelessWidget {
  const _EventPhotoRow({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < 3;

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        for (int i = 0; i < photos.length; i++)
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: KolabingColors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(color: KolabingColors.softYellowBorder),
                ),
                child: ClipRRect(
                  borderRadius: KolabingRadius.borderRadiusSm,
                  child: photos[i].startsWith('/')
                      ? Image.file(
                          File(photos[i]),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : photos[i].startsWith('http')
                      ? Image.network(
                          photos[i],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(
                            LucideIcons.image,
                            size: 20,
                            color: KolabingColors.textSecondary,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: KolabingColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: KolabingColors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: KolabingColors.border),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.plus,
                  size: 20,
                  color: KolabingColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EventVideoRow extends StatelessWidget {
  const _EventVideoRow({
    required this.videos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> videos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = videos.isEmpty;

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        for (int i = 0; i < videos.length; i++)
          Container(
            width: 180,
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: KolabingColors.surfaceVariant,
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(color: KolabingColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.video,
                  size: 18,
                  color: KolabingColors.textSecondary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    'Recap video',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onRemove(i),
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: KolabingColors.error,
                  ),
                ),
              ],
            ),
          ),
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: KolabingColors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: KolabingColors.border),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.video,
                  size: 20,
                  color: KolabingColors.textSecondary,
                ),
              ),
            ),
          ),
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
}) => InputDecoration(
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
    borderSide: const BorderSide(color: KolabingColors.borderFocus, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: KolabingRadius.borderRadiusSm,
    borderSide: const BorderSide(color: KolabingColors.borderError),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: KolabingRadius.borderRadiusSm,
    borderSide: const BorderSide(color: KolabingColors.borderError, width: 1.5),
  ),
);

TextStyle get _inputTextStyle =>
    GoogleFonts.openSans(fontSize: 14, color: KolabingColors.textPrimary);
