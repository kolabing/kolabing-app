import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/models/community_tier.dart';
import '../../community/providers/community_providers.dart';
import '../../onboarding/models/place_suggestion.dart';
import '../../onboarding/providers/onboarding_provider.dart';
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

  /// Visibility (#1): 'public' | 'members' | 'tier'. `public` surfaces the
  /// event in city discovery; `tier` gates it to [_selectedTierIds]
  /// (sent as `tier_gate`). Defaults to `members` (backend-safe default).
  String _visibility = 'members';
  final Set<String> _selectedTierIds = {};

  /// Event location city (Fix: events.city_id). Defaults to the user's city;
  /// sent as `city_id` only when set (self-gated — backend FK ships in
  /// parallel). On create/edit it is auto-derived from the Google Places venue
  /// the leader picks (NF-20) — see [_handlePlaceSelected].
  String? _cityId;
  String? _cityName;

  /// Places autocomplete (NF-20): the live query string driving
  /// [placeSuggestionsProvider], whether a place was explicitly picked, and
  /// whether we are resolving the picked place's details.
  String _placeQuery = '';
  bool _placeSelected = false;
  bool _resolvingPlace = false;

  /// Newly picked photos (paths) to upload (edit mode uploads after save).
  final List<XFile> _pickedPhotos = [];

  // Recurrence (create only). 'none' | 'weekly' | 'biweekly' | 'monthly'.
  String _repeat = 'none';
  final Set<int> _weekdays = {}; // 0=Sun .. 6=Sat (multi-day = 2x/week etc.)
  String _endsMode = 'never'; // never | count | until
  final _endsCount = TextEditingController(text: '8');
  DateTime? _endsOn;
  String _chatMode = 'per_event'; // per_event | series

  bool get _isEdit => widget.existing != null;

  /// The event being edited is already part of a series.
  bool get _existingIsRecurring => widget.existing?.isRecurring ?? false;

  /// Show the Repeat section: on create, or when editing a one-off (→ convert).
  bool get _showRepeat => !_existingIsRecurring;

  /// This save will produce a series (a fresh create or a one-off conversion).
  bool get _isRecurring => _showRepeat && _repeat != 'none';

  /// Scope for editing an occurrence of an existing series.
  String _editScope = 'this';

  /// Dart weekday (Mon=1..Sun=7) → our 0=Sun..6=Sat.
  int get _startWeekday => ((_startsAt ?? DateTime.now()).weekday % 7);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _location.text = e.location ?? '';
      _placeQuery = _location.text;
      // Treat a seeded location as an already-chosen place so the suggestions
      // list stays collapsed until the leader actively edits the field.
      _placeSelected = _location.text.trim().isNotEmpty;
      _startsAt = e.startsAt ?? e.date;
      _limited = e.capacity != null;
      if (e.capacity != null) _capacity.text = e.capacity.toString();
      // Seed visibility from the existing event (#1). Older events without a
      // value default to members.
      _visibility = (e.visibility == 'public' ||
              e.visibility == 'members' ||
              e.visibility == 'tier')
          ? e.visibility!
          : 'members';
    }
    // Default the event city to the user's city (the community's city falls back
    // server-side). The user's city is on UserModel; degrade gracefully when
    // absent.
    final user = ref.read(authProvider).user;
    if (user?.cityId != null && user!.cityId!.isNotEmpty) {
      _cityId = user.cityId;
      _cityName = user.cityName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _capacity.dispose();
    _endsCount.dispose();
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

  /// The leader picked a place from the autocomplete (NF-20). Set the location
  /// text to the formatted address and auto-derive the event city from the
  /// place details (`PlaceDetailsImport.cityId` / `cityName`). A place with no
  /// resolvable city leaves the city unset — the event simply won't be
  /// city-discoverable; we never block on it.
  Future<void> _handlePlaceSelected(PlaceSuggestion place) async {
    if (_resolvingPlace) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _placeSelected = true;
      _resolvingPlace = true;
      _location.text = place.formattedAddress;
      _placeQuery = place.formattedAddress;
      // Optimistic city from the suggestion (details refine it below).
      if (place.cityId != null && place.cityId!.isNotEmpty) {
        _cityId = place.cityId;
        _cityName = place.city.isNotEmpty ? place.city : _cityName;
      }
    });

    try {
      final details = await ref
          .read(onboardingServiceProvider)
          .getPlaceDetails(place.placeId);
      if (!mounted) return;
      setState(() {
        _location.text = details.primaryVenue.formattedAddress.isNotEmpty
            ? details.primaryVenue.formattedAddress
            : place.formattedAddress;
        _placeQuery = _location.text;
        if (details.cityId != null && details.cityId!.isNotEmpty) {
          _cityId = details.cityId;
          _cityName = details.cityName ?? details.primaryVenue.city;
        }
      });
    } on Object {
      // Details lookup failed — keep the suggestion's address + optimistic city.
      // Don't surface an error; the location text is already usable.
    } finally {
      if (mounted) setState(() => _resolvingPlace = false);
    }
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    setState(() => _pickedPhotos.addAll(picked));
  }

  List<String>? _tierGate() {
    if (_visibility != 'tier' || _selectedTierIds.isEmpty) return null;
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
    if (_visibility == 'tier' && _selectedTierIds.isEmpty) {
      _snack(_l10n.eventFormErrTier);
      return;
    }

    Map<String, dynamic>? recurrence;
    if (_isRecurring) {
      final byweekday = _repeat == 'monthly'
          ? <int>[_startWeekday]
          : _weekdays.toList();
      if (byweekday.isEmpty) {
        _snack(_l10n.eventFormErrWeekday);
        return;
      }
      int? endsCount;
      if (_endsMode == 'count') {
        endsCount = int.tryParse(_endsCount.text.trim());
        if (endsCount == null || endsCount < 1) {
          _snack(_l10n.eventFormErrEndsCount);
          return;
        }
      }
      if (_endsMode == 'until' &&
          (_endsOn == null || !_endsOn!.isAfter(_startsAt!))) {
        _snack(_l10n.eventFormErrEndsOn);
        return;
      }
      recurrence = {
        'frequency': _repeat,
        'byweekday': byweekday,
        'chat_mode': _chatMode,
        'ends_mode': _endsMode,
        if (_endsMode == 'count') 'ends_count': endsCount,
        if (_endsMode == 'until')
          'ends_on': _endsOn!.toUtc().toIso8601String(),
      };
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
          visibility: _visibility,
          cityId: _cityId,
          // Editing a recurring occurrence → scope; editing a one-off with a
          // pattern picked → recurrence (backend converts it to a series).
          scope: _existingIsRecurring ? _editScope : 'this',
          recurrence: recurrence,
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
          visibility: _visibility,
          cityId: _cityId,
          recurrence: recurrence,
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

      ref
          .read(communityUpcomingEventsProvider(widget.communityId).notifier)
          .reload();
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
      backgroundColor: context.colors.background,
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
                  .copyWith(color: context.colors.onSurfaceVariant)),
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
          _locationField(),
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
                    .copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: KolabingSpacing.lg),
          _label(_l10n.eventFormVisibilityLabel),
          _visibilityPicker(tiersAsync),
          const SizedBox(height: KolabingSpacing.lg),
          if (_showRepeat) ...[
            _label(_l10n.eventFormRepeatLabel),
            _repeatSection(),
            const SizedBox(height: KolabingSpacing.lg),
          ],
          if (_isEdit && _existingIsRecurring) ...[
            _label(_l10n.eventFormApplyTo),
            _scopeSelector(),
            const SizedBox(height: KolabingSpacing.lg),
          ],
          _label(_l10n.eventFormPhotos),
          _photosPicker(),
          const SizedBox(height: KolabingSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_isEdit ? LucideIcons.check : LucideIcons.calendarPlus,
                      size: 18),
              label: Text(
                  _isEdit
                      ? _l10n.eventFormSave
                      : (_isRecurring
                          ? _l10n.eventFormPublishSeries
                          : _l10n.eventFormPublish),
                  style: KolabingTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityPicker(AsyncValue<List<CommunityTier>> tiersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'public',
          groupValue: _visibility,
          onChanged: (v) => setState(() => _visibility = v ?? 'members'),
          title: Text(_l10n.eventFormVisibilityPublic),
          subtitle: Text(_l10n.eventFormVisibilityPublicHint,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'members',
          groupValue: _visibility,
          onChanged: (v) => setState(() => _visibility = v ?? 'members'),
          title: Text(_l10n.eventFormVisibilityMembers),
          subtitle: Text(_l10n.eventFormVisibilityMembersHint,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'tier',
          groupValue: _visibility,
          onChanged: (v) => setState(() => _visibility = v ?? 'members'),
          title: Text(_l10n.eventFormVisibilityTier),
          subtitle: Text(_l10n.eventFormVisibilityTierHint,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
        ),
        if (_visibility == 'tier')
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

  Widget _scopeSelector() {
    return Wrap(
      spacing: KolabingSpacing.xs,
      children: [
        for (final opt in [
          ('this', _l10n.eventHubDeleteScopeThis),
          ('following', _l10n.eventHubDeleteScopeFollowing),
          ('series', _l10n.eventHubDeleteScopeSeries),
        ])
          ChoiceChip(
            label: Text(opt.$2),
            selected: _editScope == opt.$1,
            onSelected: (_) => setState(() => _editScope = opt.$1),
          ),
      ],
    );
  }

  Widget _repeatSection() {
    // narrowWeekdays is Sunday-first → index matches our 0=Sun..6=Sat.
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: KolabingSpacing.xs,
          children: [
            for (final opt in [
              ('none', _l10n.eventFormRepeatNone),
              ('weekly', _l10n.eventFormRepeatWeekly),
              ('biweekly', _l10n.eventFormRepeatBiweekly),
              ('monthly', _l10n.eventFormRepeatMonthly),
            ])
              ChoiceChip(
                label: Text(opt.$2),
                selected: _repeat == opt.$1,
                onSelected: (_) => setState(() {
                  _repeat = opt.$1;
                  if (_repeat != 'none' && _weekdays.isEmpty) {
                    _weekdays.add(_startWeekday);
                  }
                }),
              ),
          ],
        ),
        if (_repeat == 'weekly' || _repeat == 'biweekly') ...[
          const SizedBox(height: KolabingSpacing.sm),
          Wrap(
            spacing: KolabingSpacing.xs,
            children: [
              for (var d = 0; d < 7; d++)
                FilterChip(
                  label: Text(narrow[d]),
                  selected: _weekdays.contains(d),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _weekdays.add(d);
                    } else {
                      _weekdays.remove(d);
                    }
                  }),
                ),
            ],
          ),
        ],
        if (_repeat != 'none') ...[
          const SizedBox(height: KolabingSpacing.md),
          _label(_l10n.eventFormRepeatEnds),
          Wrap(
            spacing: KolabingSpacing.xs,
            children: [
              for (final opt in [
                ('never', _l10n.eventFormRepeatNever),
                ('count', _l10n.eventFormRepeatAfter),
                ('until', _l10n.eventFormRepeatOnDate),
              ])
                ChoiceChip(
                  label: Text(opt.$2),
                  selected: _endsMode == opt.$1,
                  onSelected: (_) => setState(() => _endsMode = opt.$1),
                ),
            ],
          ),
          if (_endsMode == 'count') ...[
            const SizedBox(height: KolabingSpacing.sm),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _endsCount,
                    keyboardType: TextInputType.number,
                    decoration: _dec('8'),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Text(_l10n.eventFormRepeatEvents,
                    style: KolabingTextStyles.bodyMedium),
              ],
            ),
          ],
          if (_endsMode == 'until') ...[
            const SizedBox(height: KolabingSpacing.sm),
            _DateField(
              value: _endsOn,
              hint: _l10n.eventFormRepeatOnDate,
              onClear:
                  _endsOn == null ? null : () => setState(() => _endsOn = null),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endsOn ??
                      (_startsAt ?? now).add(const Duration(days: 28)),
                  firstDate: _startsAt ?? now,
                  lastDate: now.add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _endsOn = picked);
              },
            ),
          ],
          const SizedBox(height: KolabingSpacing.md),
          _label(_l10n.eventFormRepeatChatLabel),
          Wrap(
            spacing: KolabingSpacing.xs,
            children: [
              for (final opt in [
                ('per_event', _l10n.eventFormRepeatChatPerEvent),
                ('series', _l10n.eventFormRepeatChatShared),
              ])
                ChoiceChip(
                  label: Text(opt.$2),
                  selected: _chatMode == opt.$1,
                  onSelected: (_) => setState(() => _chatMode = opt.$1),
                ),
            ],
          ),
        ],
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
                        color: context.colors.surfaceVariant,
                        child: Icon(LucideIcons.image,
                            color: context.colors.textTertiary),
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

  /// Google Places autocomplete location field (NF-20). Mirrors the business
  /// onboarding step-5 UX: type → suggestions → tap. On select the city is
  /// auto-derived and shown read-only beneath the field. No API key is needed —
  /// suggestions/details are backend-proxied via `placeSuggestionsProvider` /
  /// `OnboardingService.getPlaceDetails`.
  Widget _locationField() {
    // Only query for suggestions while the leader is actively typing (i.e. has
    // not just picked a place). This keeps the list collapsed on edit-seed.
    final suggestions = ref.watch(
      placeSuggestionsProvider(_placeSelected ? '' : _placeQuery.trim()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _location,
          decoration: _dec(_l10n.eventFormLocationSearchHint).copyWith(
            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
            suffixIcon: _resolvingPlace
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_location.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => setState(() {
                          _location.clear();
                          _placeQuery = '';
                          _placeSelected = false;
                          _cityId = null;
                          _cityName = null;
                        }),
                      )
                    : null),
          ),
          onChanged: (v) => setState(() {
            _placeQuery = v;
            // Re-opening the suggestions: the text no longer reflects a picked
            // place, and the derived city is stale until a new pick.
            _placeSelected = false;
            _cityId = null;
            _cityName = null;
          }),
        ),
        // Derived-city hint (read-only) so the leader sees what was detected.
        if (_placeSelected) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            _cityName != null && _cityName!.isNotEmpty
                ? _l10n.eventFormCityDetected(_cityName!)
                : _l10n.eventFormCityNotDetected,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: _cityName != null && _cityName!.isNotEmpty
                  ? KolabingColors.onSurfaceVariant
                  : KolabingColors.error,
            ),
          ),
        ],
        // Suggestions list — shown only while actively typing a query.
        if (!_placeSelected && _placeQuery.trim().isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.xs),
          suggestions.when(
            data: (items) {
              if (_placeQuery.trim().length < 2) {
                return _placeHint(_l10n.eventFormLocationStartTyping);
              }
              if (items.isEmpty) {
                return _placeHint(_l10n.eventFormLocationNoMatches);
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: KolabingColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    for (final place in items)
                      ListTile(
                        dense: true,
                        leading: const Icon(LucideIcons.mapPin, size: 18),
                        title: Text(place.title,
                            style: KolabingTextStyles.bodyMedium),
                        subtitle: Text(place.displaySubtitle,
                            style: KolabingTextStyles.bodySmall.copyWith(
                                color: KolabingColors.onSurfaceVariant)),
                        onTap: () => _handlePlaceSelected(place),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => _placeHint(_l10n.eventFormLocationError),
          ),
        ],
      ],
    );
  }

  Widget _placeHint(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
        child: Text(message,
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.onSurfaceVariant)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
        child: Text(t,
            style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurfaceVariant)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.colors.surfaceContainerLow,
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
          fillColor: context.colors.surfaceContainerLow,
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
                ? context.colors.onSurface
                : context.colors.onSurfaceVariant,
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
