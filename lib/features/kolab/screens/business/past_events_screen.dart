import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/upload_service.dart';
import '../../../../utils/image_picker_normalize.dart';
import '../../../../utils/remote_media_url.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../event/models/event.dart';
import '../../../event/providers/event_provider.dart';
import '../../models/kolab.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';
import '../../widgets/kolab_examples_box.dart';
import '../../widgets/multi_select_chips.dart';
import '../../widgets/profile_event_picker_sheet.dart';

/// Step 5 (venue / product flows): "WHY COMMUNITIES WILL LIKE THIS"
///
/// Collects highlight chips + optional free text, with past collaboration
/// entries kept below as optional supporting evidence (up to 5 entries: name,
/// date picker, partner name, photo placeholders).
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class PastEventsScreen extends ConsumerStatefulWidget {
  const PastEventsScreen({super.key});

  @override
  ConsumerState<PastEventsScreen> createState() => _PastEventsScreenState();
}

class _PastEventsScreenState extends ConsumerState<PastEventsScreen> {
  final _extraNotesController = TextEditingController();
  bool _didInitNotes = false;

  @override
  void dispose() {
    _extraNotesController.dispose();
    super.dispose();
  }

  void _syncNotesController(Kolab kolab) {
    if (_didInitNotes) return;
    _didInitNotes = true;
    final match = RegExp(r'\n\nNote: (.*)$', dotAll: true)
        .firstMatch(kolab.description);
    _extraNotesController.text = match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final profileEventsState = ref.watch(eventsProvider);
    final kolab = formState.kolab;
    final notifier = ref.read(kolabFormProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final events = kolab.pastEvents;
    final canAdd = events.length < 5;
    final importableEvents = profileEventsState.events
        .where((event) => !_containsImportedEvent(events, event))
        .toList(growable: false);
    final showImportButton =
        canAdd && (profileEventsState.isLoading || importableEvents.isNotEmpty);

    _syncNotesController(kolab);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          'WHY COMMUNITIES WILL LIKE THIS',
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        Text(
          'Add a few reasons that make your Kolab attractive.',
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Highlight chips
        Builder(builder: (context) {
          final highlightsAsync = ref.watch(kolabHighlightsProvider);
          final options = highlightsAsync.when(
            data: (options) => options,
            loading: () => const <OfferOption>[],
            error: (_, _) => const <OfferOption>[],
          );
          return MultiSelectChips<OfferOption>(
            items: options,
            selected: kolab.highlights
                .map((slug) => options.firstWhere(
                      (o) => o.slug == slug,
                      orElse: () => OfferOption(id: slug, slug: slug, name: slug),
                    ))
                .toList(),
            labelBuilder: (o) => o.name,
            onToggle: (option) => notifier.toggleHighlight(option.slug),
          );
        }),
        const SizedBox(height: KolabingSpacing.xs),
        const KolabExamplesBox(examples: [
          'Central location and space for groups.',
          'Free samples members can actually use.',
          'A unique experience that creates good content.',
        ]),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Anything else communities should know (optional free text)
        Text(
          'ANYTHING ELSE COMMUNITIES SHOULD KNOW? (OPTIONAL)',
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _extraNotesController,
          maxLength: 500,
          maxLines: 3,
          hint:
              'e.g. "We have space for groups of 20–30 and can prepare a special post-run menu."',
          onChanged: (value) {
            final base = kolab.description.split('\n\nNote:').first.trim();
            notifier.updateDescription(
              value.trim().isEmpty ? base : '$base\n\nNote: ${value.trim()}',
            );
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Past collaborations (optional supporting evidence)
        Text(
          'PAST COLLABORATIONS (OPTIONAL)',
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.pastEventsSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        if (showImportButton) ...[
          OutlinedButton.icon(
            onPressed: profileEventsState.isLoading
                ? null
                : () => _importFromProfile(importableEvents),
            icon: profileEventsState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.calendarPlus, size: 18),
            label: Text(
              profileEventsState.isLoading
                  ? l10n.pastEventsLoadingProfileEvents
                  : l10n.pastEventsSelectFromProfile,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],

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
                color: context.colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: context.colors.darkBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 20,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Text(
                    l10n.pastEventsAddPastEvent,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurfaceVariant,
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

  Future<void> _importFromProfile(List<Event> importableEvents) async {
    if (importableEvents.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pastEventsAllAlreadyAdded),
        ),
      );
      return;
    }

    final remainingSlots =
        5 - ref.read(kolabFormProvider).kolab.pastEvents.length;
    final selectedEvents = await ProfileEventPickerSheet.show(
      context,
      events: importableEvents,
      maxSelection: remainingSlots,
    );
    if (!mounted || selectedEvents == null || selectedEvents.isEmpty) {
      return;
    }

    final notifier = ref.read(kolabFormProvider.notifier);
    var trimmedAny = false;
    for (final event in selectedEvents) {
      final mapped = _mapProfileEvent(event);
      // A profile event can carry more media than a single past event allows
      // (max 3 photos / 1 video). Cap it here and tell the user, instead of
      // letting the backend reject the whole submit with a raw error.
      if (mapped.exceedsMediaLimit) {
        trimmedAny = true;
      }
      notifier.addPastEvent(mapped.capMedia());
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          trimmedAny
              ? l10n.pastEventsImportedMediaTrimmed(selectedEvents.length)
              : l10n.pastEventsImported(selectedEvents.length),
        ),
        backgroundColor: trimmedAny
            ? context.colors.warning
            : context.colors.success,
      ),
    );
  }

  bool _containsImportedEvent(List<PastEvent> currentEvents, Event event) {
    final incomingKey = _eventKey(
      name: event.name,
      date: event.date,
      partnerName: event.partner.name,
    );

    for (final currentEvent in currentEvents) {
      if (_eventKey(
            name: currentEvent.name,
            date: currentEvent.date,
            partnerName: currentEvent.partnerName,
          ) ==
          incomingKey) {
        return true;
      }
    }

    return false;
  }

  PastEvent _mapProfileEvent(Event event) => PastEvent(
    name: event.name,
    date: event.date,
    partnerName: event.partner.name.isEmpty ? null : event.partner.name,
    photos: event.photos
        .map((photo) => normalizeRemoteMediaUrl(photo.url))
        .where((url) => url.isNotEmpty)
        .toList(growable: false),
    videos: event.videos
        .map((video) => normalizeRemoteMediaUrl(video.url))
        .where((url) => url.isNotEmpty)
        .toList(growable: false),
  );
}

String _eventKey({
  required String name,
  required DateTime date,
  String? partnerName,
}) =>
    '${name.trim().toLowerCase()}|'
    '${DateUtils.dateOnly(date).toIso8601String()}|'
    '${(partnerName ?? '').trim().toLowerCase()}';

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
            primary: context.colors.primary,
            onPrimary: context.colors.onPrimary,
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
    final l10n = AppLocalizations.of(context);
    final dateFormatted = DateFormat('MMM d, yyyy').format(widget.event.date);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Header row
          Row(
            children: [
              Text(
                l10n.pastEventsEventNumber(widget.index + 1),
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: context.colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Event Name
          Text(
            l10n.pastEventsEventNameLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(
              context,
              hint: l10n.pastEventsEventNameHint,
            ),
            style: _inputTextStyle(context),
            onChanged: (v) {
              widget.onUpdate(widget.event.copyWith(name: v));
            },
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Date
          Text(
            l10n.pastEventsDateLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
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
                color: context.colors.surface,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: context.colors.darkBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(dateFormatted, style: _inputTextStyle(context)),
                  ),
                  Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // -- Partner Name
          Text(
            l10n.pastEventsPartnerNameLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextField(
            controller: _partnerController,
            decoration: _inputDecoration(
              context,
              hint: l10n.pastEventsPartnerNameHint,
            ),
            style: _inputTextStyle(context),
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
            l10n.pastEventsPhotosLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
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
                // C10: normalize before upload so the preview path is usable.
                final localPath = await normalizePickedImage(image);
                final uploadService = UploadService();
                final url = await uploadService.upload(
                  filePath: localPath,
                  folder: 'kolabs',
                );
                final updated = [...widget.event.photos, url];
                widget.onUpdate(widget.event.copyWith(photos: updated));
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).pastEventsUploadFailed(e.toString()),
                      ),
                    ),
                  );
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
            l10n.pastEventsRecapVideoLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).pastEventsUploadFailed(e.toString()),
                      ),
                    ),
                  );
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
                  color: context.colors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(color: context.colors.softYellowBorder),
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
                      : Center(
                          child: Icon(
                            LucideIcons.image,
                            size: 20,
                            color: context.colors.onSurfaceVariant,
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
                    decoration: BoxDecoration(
                      color: context.colors.error,
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
                color: context.colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: context.colors.darkBorder),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.plus,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
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
              color: context.colors.surfaceVariant,
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(color: context.colors.darkBorder),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.video,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).pastEventsRecapVideoChip,
                    style: KolabingTextStyles.captionSecondary.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onRemove(i),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: context.colors.error,
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
                color: context.colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(color: context.colors.darkBorder),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.video,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
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

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  String? error,
}) => InputDecoration(
  hintText: hint,
  hintStyle: KolabingTextStyles.bodySmall.copyWith(
    color: context.colors.textTertiary,
  ),
  errorText: error,
  errorStyle: KolabingTextStyles.bodySmall.copyWith(fontSize: 12),
  filled: true,
  fillColor: context.colors.surface,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: KolabingSpacing.md,
    vertical: 14,
  ),
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
    borderSide: BorderSide(color: context.colors.borderFocus, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: KolabingRadius.borderRadiusSm,
    borderSide: BorderSide(color: context.colors.borderError),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: KolabingRadius.borderRadiusSm,
    borderSide: BorderSide(color: context.colors.borderError, width: 1.5),
  ),
);

TextStyle _inputTextStyle(BuildContext context) =>
    KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurface);
