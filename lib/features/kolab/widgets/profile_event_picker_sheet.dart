import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../event/models/event.dart';

class ProfileEventPickerSheet extends StatefulWidget {
  const ProfileEventPickerSheet({
    required this.events,
    required this.maxSelection,
    super.key,
  });

  final List<Event> events;
  final int maxSelection;

  static Future<List<Event>?> show(
    BuildContext context, {
    required List<Event> events,
    required int maxSelection,
  }) => showModalBottomSheet<List<Event>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileEventPickerSheet(
      events: events,
      maxSelection: maxSelection,
    ),
  );

  @override
  State<ProfileEventPickerSheet> createState() => _ProfileEventPickerSheetState();
}

class _ProfileEventPickerSheetState extends State<ProfileEventPickerSheet> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final selectedEvents = widget.events
        .where((event) => _selectedIds.contains(event.id))
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(KolabingRadius.lg),
            ),
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: KolabingColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Text(
                    'Choose from your profile events',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    'Select up to ${widget.maxSelection} event${widget.maxSelection == 1 ? '' : 's'} to import.',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Expanded(
                    child: ListView.separated(
                      itemCount: widget.events.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: KolabingSpacing.sm),
                      itemBuilder: (context, index) {
                        final event = widget.events[index];
                        final isSelected = _selectedIds.contains(event.id);
                        return InkWell(
                          onTap: () => _toggleEvent(event.id),
                          borderRadius: KolabingRadius.borderRadiusMd,
                          child: Container(
                            padding: const EdgeInsets.all(KolabingSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KolabingColors.primary.withValues(alpha: 0.08)
                                  : KolabingColors.surfaceVariant,
                              borderRadius: KolabingRadius.borderRadiusMd,
                              border: Border.all(
                                color: isSelected
                                    ? KolabingColors.primary
                                    : KolabingColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                _EventCover(url: event.coverPhotoUrl),
                                const SizedBox(width: KolabingSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: KolabingColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(event.date),
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          color: KolabingColors.textSecondary,
                                        ),
                                      ),
                                      if (event.partner.name.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          event.partner.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.openSans(
                                            fontSize: 12,
                                            color: KolabingColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isSelected,
                                  activeColor: KolabingColors.primary,
                                  onChanged: (_) => _toggleEvent(event.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedEvents.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(selectedEvents),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KolabingColors.primary,
                            foregroundColor: KolabingColors.onPrimary,
                          ),
                          child: const Text('Import events'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleEvent(String eventId) {
    setState(() {
      if (_selectedIds.contains(eventId)) {
        _selectedIds.remove(eventId);
        return;
      }

      if (_selectedIds.length >= widget.maxSelection) {
        return;
      }

      _selectedIds.add(eventId);
    });
  }
}

class _EventCover extends StatelessWidget {
  const _EventCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final coverUrl = url?.trim() ?? '';
    if (coverUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusSm,
        ),
        child: const Icon(
          LucideIcons.image,
          color: KolabingColors.textTertiary,
          size: 20,
        ),
      );
    }

    return ClipRRect(
      borderRadius: KolabingRadius.borderRadiusSm,
      child: Image.network(
        coverUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 56,
          height: 56,
          color: KolabingColors.surface,
          child: const Icon(
            LucideIcons.imageOff,
            color: KolabingColors.textTertiary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
