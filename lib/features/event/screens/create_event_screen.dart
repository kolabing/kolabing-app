import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../community/models/community_tier.dart';
import '../../community/providers/community_providers.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// Create / edit an UPCOMING event (NF-16 B2).
///
/// Fields: name · starts_at · ends_at · location · capacity (+ Unlimited) ·
/// who-can-join (All members / selected tiers → `tier_gate`) · photos.
///
/// - Create: `POST /events` (JSON), then optional `POST /events/{id}/photos`.
/// - Edit (when [existing] is set): `PUT /events/{id}` (JSON). Photos upload
///   immediately via `POST /events/{id}/photos`.
///
/// On create, pops `true` (so the legacy hub caller refreshes). On edit, pops
/// the updated [Event] so the hub can swap it in.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    this.existing,
  });

  final String communityId;
  final String communityName;

  /// When set, the form edits this upcoming event instead of creating one.
  final Event? existing;

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

  /// Tier-gate: empty list (+ [_allMembers] true) = open to all. When
  /// [_allMembers] is false, the selected tier ids become `tier_gate`.
  bool _allMembers = true;
  final Set<String> _selectedTierIds = {};

  /// Newly picked photos (paths) to upload (edit mode uploads after save).
  final List<XFile> _pickedPhotos = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _location.text = e.location ?? '';
      _startsAt = e.startsAt ?? e.date;
      _limited = e.capacity != null;
      if (e.capacity != null) _capacity.text = e.capacity.toString();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

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
      initialTime:
          TimeOfDay.fromDateTime(initial ?? now.add(const Duration(hours: 1))),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    setState(() => _pickedPhotos.addAll(picked));
  }

  List<String>? _tierGate() {
    if (_allMembers || _selectedTierIds.isEmpty) return null;
    return _selectedTierIds.toList();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      _snack(_l10n.eventFormErrName);
      return;
    }
    if (_startsAt == null) {
      _snack(_l10n.eventFormErrStart);
      return;
    }
    if (_startsAt!.isBefore(DateTime.now())) {
      _snack(_l10n.eventFormErrStartFuture);
      return;
    }
    if (_endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      _snack(_l10n.eventFormErrEndAfterStart);
      return;
    }
    int? cap;
    if (_limited) {
      cap = int.tryParse(_capacity.text.trim());
      if (cap == null || cap < 1) {
        _snack(_l10n.eventFormErrCapacity);
        return;
      }
    }

    setState(() => _busy = true);
    final svc = ref.read(eventServiceProvider);
    try {
      Event result;
      if (_isEdit) {
        result = await svc.updateUpcomingEvent(
          widget.existing!.id,
          name: name,
          startsAt: _startsAt,
          endsAt: _endsAt,
          clearEndsAt: _endsAt == null,
          location: _location.text.trim(),
          capacity: cap,
          clearCapacity: !_limited,
          tierGate: _tierGate() ?? const [],
        );
      } else {
        result = await svc.createUpcomingEvent(
          communityId: widget.communityId,
          name: name,
          startsAt: _startsAt!,
          endsAt: _endsAt,
          location: _location.text.trim(),
          capacity: cap,
          tierGate: _tierGate(),
        );
      }

      // Upload any picked photos against the (now-known) event id.
      if (_pickedPhotos.isNotEmpty) {
        try {
          result = await svc.addEventPhotos(
            result.id,
            _pickedPhotos.map((x) => x.path).toList(),
          );
        } catch (_) {
          // Photo endpoint ships in parallel; don't fail the whole save if it
          // isn't deployed yet — the event itself was saved.
        }
      }

      ref.invalidate(communityUpcomingEventsProvider(widget.communityId));
      if (!mounted) return;
      Navigator.of(context).pop<Object>(_isEdit ? result : true);
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
    final tiersAsync = ref.watch(communityTiersProvider(widget.communityId));
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? _l10n.eventFormEditTitle : _l10n.eventFormNewTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: Text(_l10n.eventFormSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          Text(widget.communityName,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.md),
          _label(_l10n.eventFormNameLabel),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(_l10n.eventFormNameHint),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _label(_l10n.eventFormStartsLabel),
          _DateField(
            value: _startsAt,
            hint: _l10n.eventFormPickStart,
            onTap: () async {
              final picked = await _pickDateTime(_startsAt);
              if (picked != null) setState(() => _startsAt = picked);
            },
          ),
          const SizedBox(height: KolabingSpacing.md),
          _label(_l10n.eventFormEndsLabel),
          _DateField(
            value: _endsAt,
            hint: _l10n.eventFormPickEnd,
            onClear:
                _endsAt == null ? null : () => setState(() => _endsAt = null),
            onTap: () async {
              final picked = await _pickDateTime(_endsAt ?? _startsAt);
              if (picked != null) setState(() => _endsAt = picked);
            },
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _label(_l10n.eventFormLocationLabel),
          TextField(
              controller: _location,
              decoration: _dec(_l10n.eventFormLocationHint)),
          const SizedBox(height: KolabingSpacing.lg),
          Row(
            children: [
              Expanded(child: _label(_l10n.eventFormCapacityLabel)),
              Text(_l10n.eventFormLimit),
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
            Text(_l10n.eventHubUnlimited,
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: KolabingColors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.lg),
          _label(_l10n.eventFormWhoCanJoin),
          _tierGatePicker(tiersAsync),
          const SizedBox(height: KolabingSpacing.lg),
          _label(_l10n.eventFormPhotos),
          _photosPicker(),
          const SizedBox(height: KolabingSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
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
                  : Icon(_isEdit ? LucideIcons.check : LucideIcons.calendarPlus,
                      size: 18),
              label: Text(_isEdit ? _l10n.eventFormSave : _l10n.eventFormPublish,
                  style: KolabingTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierGatePicker(AsyncValue<List<CommunityTier>> tiersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          value: true,
          groupValue: _allMembers,
          onChanged: (v) => setState(() => _allMembers = v ?? true),
          title: Text(_l10n.eventFormAllMembers),
        ),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          value: false,
          groupValue: _allMembers,
          onChanged: (v) => setState(() => _allMembers = v ?? false),
          title: Text(_l10n.eventFormSelectedTiers),
        ),
        if (!_allMembers)
          tiersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (tiers) => Wrap(
              spacing: KolabingSpacing.xs,
              runSpacing: KolabingSpacing.xs,
              children: [
                for (final t in tiers)
                  FilterChip(
                    label: Text(t.name),
                    selected: _selectedTierIds.contains(t.id),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _selectedTierIds.add(t.id);
                      } else {
                        _selectedTierIds.remove(t.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _photosPicker() {
    return Column(
      // NOTE: the app's OutlinedButtonTheme sets minimumSize.width = infinity
      // (full-width buttons). Such a button MUST NOT sit in a Row (Rows measure
      // children with unbounded width → "BoxConstraints forces an infinite
      // width" → blank screen). Keep it a full-width column child.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickPhotos,
          icon: const Icon(LucideIcons.imagePlus, size: 18),
          label: Text(_pickedPhotos.isEmpty
              ? _l10n.eventFormAddFromGallery
              : '${_l10n.eventFormAddFromGallery} (${_pickedPhotos.length})'),
        ),
        if (_pickedPhotos.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedPhotos.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: KolabingSpacing.xs),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _pickedPhotos[i].path,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: KolabingColors.surfaceVariant,
                        child: const Icon(LucideIcons.image,
                            color: KolabingColors.textTertiary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () =>
                          setState(() => _pickedPhotos.removeAt(i)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
