import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../providers/event_provider.dart';

/// Leader create-event form (Phase-3 upcoming mode, PR #20).
/// `POST /events` with community_id + name + future starts_at; ends/location/
/// capacity optional. Tier-gating defaults to "all members" for now (a quick
/// follow-up adds the tier picker). Pops `true` on success so the caller can
/// refresh + show the new event.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _limited = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          initial ?? now.add(const Duration(hours: 1))),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _publish() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      _snack('Event name needs at least 3 characters.');
      return;
    }
    if (_startsAt == null) {
      _snack('Pick a start date & time.');
      return;
    }
    if (_startsAt!.isBefore(DateTime.now())) {
      _snack('Start must be in the future.');
      return;
    }
    if (_endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      _snack('End must be after the start.');
      return;
    }
    int? cap;
    if (_limited) {
      cap = int.tryParse(_capacity.text.trim());
      if (cap == null || cap < 1) {
        _snack('Enter a valid capacity, or turn off the limit.');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(eventServiceProvider).createUpcomingEvent(
            communityId: widget.communityId,
            name: name,
            startsAt: _startsAt!,
            endsAt: _endsAt,
            location: _location.text.trim(),
            capacity: cap,
          );
      ref.invalidate(communityUpcomingEventsProvider(widget.communityId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(title: const Text('New event')),
      body: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          Text(widget.communityName,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.md),
          _label('Name'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Saturday 10K'),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _label('Starts'),
          _DateField(
            value: _startsAt,
            hint: 'Pick start date & time',
            onTap: () async {
              final picked = await _pickDateTime(_startsAt);
              if (picked != null) setState(() => _startsAt = picked);
            },
          ),
          const SizedBox(height: KolabingSpacing.md),
          _label('Ends (optional)'),
          _DateField(
            value: _endsAt,
            hint: 'Pick end date & time',
            onClear: _endsAt == null ? null : () => setState(() => _endsAt = null),
            onTap: () async {
              final picked = await _pickDateTime(_endsAt ?? _startsAt);
              if (picked != null) setState(() => _endsAt = picked);
            },
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _label('Location (optional)'),
          TextField(controller: _location, decoration: _dec('Ciutadella Park')),
          const SizedBox(height: KolabingSpacing.lg),
          Row(
            children: [
              Expanded(child: _label('Capacity (optional)')),
              const Text('Limit'),
              Switch(
                value: _limited,
                onChanged: (v) => setState(() => _limited = v),
              ),
            ],
          ),
          if (_limited)
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: _dec('30'),
            )
          else
            Text('Unlimited',
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: KolabingColors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.md),
          _label('Who can join'),
          Text('All members  ·  tier-gating coming soon',
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _publish,
              style: FilledButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.calendarPlus, size: 18),
              label: Text('Publish event',
                  style: KolabingTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
        child: Text(t,
            style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurfaceVariant)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: KolabingColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.hint,
    required this.onTap,
    this.onClear,
  });

  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: KolabingColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16), onPressed: onClear)
              : const Icon(LucideIcons.calendar, size: 18),
        ),
        child: Text(
          value != null ? _fmt(value!) : hint,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: value != null
                ? KolabingColors.onSurface
                : KolabingColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$m';
  }
}
