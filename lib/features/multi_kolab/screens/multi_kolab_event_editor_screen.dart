import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_input.dart';
import '../../../widgets/kolabing_segmented_control.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../../auth/models/auth_response.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../providers/multi_kolab_providers.dart';
import '../providers/multi_kolab_repository_provider.dart';
import '../repositories/api_multi_kolab_repository.dart';

/// Create or edit a Multi-Kolab event draft.
///
/// Draft-first by design: the backend's draft validation is deliberately
/// lenient (only `title` is required — contract §3), so this form never
/// blocks a partially completed event. Only format-level rules that would
/// produce an unusable value (a non-HTTPS RSVP link, an inverted date range)
/// are enforced client-side; everything else is the publish step's job,
/// where the backend is the final authority.
class MultiKolabEventEditorScreen extends ConsumerStatefulWidget {
  const MultiKolabEventEditorScreen({super.key, this.eventId});

  /// Null when creating; an existing draft's id when editing.
  final String? eventId;

  bool get isEditing => eventId != null;

  @override
  ConsumerState<MultiKolabEventEditorScreen> createState() =>
      _MultiKolabEventEditorScreenState();
}

class _MultiKolabEventEditorScreenState
    extends ConsumerState<MultiKolabEventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _valueSummary = TextEditingController();
  final _city = TextEditingController();
  final _category = TextEditingController();
  final _rsvpUrl = TextEditingController();

  bool _venueNeeded = false;
  MultiKolabDateMode _dateMode = MultiKolabDateMode.exact;
  DateTime? _eventDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  bool _seeded = false;
  bool _dirty = false;
  bool _submitting = false;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    // When creating there is nothing to seed, so the form is "settled"
    // immediately and any keystroke counts as an unsaved change. Without
    // this the guard only ever armed itself on the edit path.
    _seeded = !widget.isEditing;
    for (final c in [
      _title,
      _description,
      _valueSummary,
      _city,
      _category,
      _rsvpUrl,
    ]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _valueSummary,
      _city,
      _category,
      _rsvpUrl,
    ]) {
      c
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && _seeded) setState(() => _dirty = true);
  }

  /// Restores every previously saved value so editing a draft never silently
  /// drops a field the organizer already filled in.
  void _seedFrom(MultiKolabEvent event) {
    if (_seeded) return;
    _seeded = true;
    _title.text = event.title;
    _description.text = event.description ?? '';
    _valueSummary.text = event.valueSummary ?? '';
    _city.text = event.city ?? '';
    _category.text = event.category ?? '';
    _rsvpUrl.text = event.rsvpUrl ?? '';
    _venueNeeded = event.venueNeeded;
    _dateMode = event.dateMode ?? MultiKolabDateMode.exact;
    _eventDate = event.eventDate;
    _rangeStart = event.dateRangeStart;
    _rangeEnd = event.dateRangeEnd;
    _dirty = false;
  }

  String? _validateRsvp(String? value, AppLocalizations l10n) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    // HTTPS-only is a Global Constraint the backend also enforces
    // (`must_be_https`); catching it here saves a round trip.
    if (uri == null || uri.scheme != 'https' || (uri.host).isEmpty) {
      return l10n.multiKolabEventFormRsvpInvalid;
    }
    return null;
  }

  bool _validateDates(AppLocalizations l10n) {
    if (_dateMode != MultiKolabDateMode.range) {
      setState(() => _rangeError = null);
      return true;
    }
    if (_rangeStart != null &&
        _rangeEnd != null &&
        _rangeEnd!.isBefore(_rangeStart!)) {
      setState(() => _rangeError = l10n.multiKolabEventFormDateRangeInvalid);
      return false;
    }
    setState(() => _rangeError = null);
    return true;
  }

  String? _nullIfBlank(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  CreateMultiKolabEventInput _buildInput() {
    final isRange = _dateMode == MultiKolabDateMode.range;
    return CreateMultiKolabEventInput(
      title: _title.text.trim(),
      description: _nullIfBlank(_description),
      valueSummary: _nullIfBlank(_valueSummary),
      venueNeeded: _venueNeeded,
      dateMode: _dateMode,
      // Only the fields belonging to the selected mode are sent, so a stale
      // value from the other mode can never reach the backend.
      eventDate: isRange ? null : _eventDate,
      dateRangeStart: isRange ? _rangeStart : null,
      dateRangeEnd: isRange ? _rangeEnd : null,
      city: _nullIfBlank(_city),
      category: _nullIfBlank(_category),
      rsvpUrl: _nullIfBlank(_rsvpUrl),
      // The editor submits the whole form, so an emptied field must be sent as
      // null and actually cleared rather than silently kept.
      isWholeForm: true,
      // `eligible_account_type` is deliberately NOT sent. Eligibility is a
      // property of a ROLE, not of an event: one event can carry a
      // community-only role, a business-only role and an open-to-either role
      // at the same time, so a single event-level answer to "who can apply?"
      // can only ever contradict them. The field is optional on
      // `POST/PATCH /multi-kolab-events`, so omitting it leaves the backend
      // default in place and the per-role `eligible_account_type` — which is
      // what Explore actually filters on — remains the only source of truth.
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateDates(l10n)) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    final repository = ref.read(multiKolabRepositoryProvider);

    try {
      final input = _buildInput();
      final saved = widget.isEditing
          ? await repository.updateDraft(widget.eventId!, input)
          : await repository.createDraft(input);

      ref
        ..invalidate(multiKolabMyEventsProvider)
        ..invalidate(multiKolabEventDetailProvider(saved.id));

      if (!mounted) return;
      _dirty = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.multiKolabEventFormSaved)));

      if (widget.isEditing) {
        if (context.canPop()) context.pop();
      } else {
        // A new draft has no roles yet; land the organizer straight on the
        // Roles tab of the management screen rather than an empty overview.
        context.pushReplacement(
          multiKolabOrganizerEventLocation(saved.id, tab: 'roles'),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(e, l10n))));
    } on NetworkException {
      // Was unhandled: the spinner stopped and no snackbar appeared, so the
      // organizer could not tell whether the draft had saved.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.networkOfflineBannerMessage)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(ApiException e, AppLocalizations l10n) {
    // Stable machine-readable codes only — never the human-readable message
    // (contract §10).
    return switch (e.error.stableCode) {
      'not_owner' => l10n.multiKolabErrorNotOwner,
      'invalid_transition' => l10n.multiKolabErrorInvalidTransition,
      'event_creator_required' => l10n.multiKolabEntitlementGateBody,
      _ => l10n.multiKolabErrorGeneric,
    };
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('multiKolabDiscardDialog'),
        title: Text(l10n.multiKolabEventFormDiscardTitle),
        content: Text(l10n.multiKolabEventFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.multiKolabDismissCta),
          ),
          TextButton(
            key: const Key('multiKolabDiscardConfirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.multiKolabEventFormDiscardConfirm),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);
    // Clamped, not passed through: showDatePicker asserts
    // firstDate <= initialDate <= lastDate, and a draft saved with a date
    // older than a year (or beyond the window) would trip it the moment the
    // organizer tapped the field.
    final seed = current ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: seed.isBefore(firstDate)
          ? firstDate
          : (seed.isAfter(lastDate) ? lastDate : seed),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
        _dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    if (widget.isEditing && !_seeded) {
      final asyncEvent = ref.watch(
        multiKolabEventDetailProvider(widget.eventId!),
      );
      final event = asyncEvent.value;
      if (event == null) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: KolabingTopBar(title: l10n.multiKolabEventFormEditTitle),
          body: asyncEvent.hasError
              ? Center(child: Text(l10n.multiKolabExploreErrorBody))
              : const Center(child: CircularProgressIndicator()),
        );
      }
      _seedFrom(event);
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: KolabingTopBar(
          title: widget.isEditing
              ? l10n.multiKolabEventFormEditTitle
              : l10n.multiKolabEventFormCreateTitle,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              children: [
                KolabingInput(
                  key: const Key('multiKolabEventTitleField'),
                  controller: _title,
                  label: l10n.multiKolabEventFormNameLabel,
                  maxLength: 255,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.multiKolabEventFormNameRequired
                      : null,
                ),
                const SizedBox(height: KolabingSpacing.md),
                KolabingInput(
                  key: const Key('multiKolabEventDescriptionField'),
                  controller: _description,
                  label: l10n.multiKolabEventFormDescriptionLabel,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 5000,
                ),
                const SizedBox(height: KolabingSpacing.md),
                KolabingInput(
                  key: const Key('multiKolabEventValueField'),
                  controller: _valueSummary,
                  label: l10n.multiKolabEventFormValueLabel,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 1000,
                ),
                const SizedBox(height: KolabingSpacing.md),
                SwitchListTile.adaptive(
                  key: const Key('multiKolabEventVenueNeededSwitch'),
                  contentPadding: EdgeInsets.zero,
                  value: _venueNeeded,
                  title: Text(
                    l10n.multiKolabEventFormVenueNeededLabel,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: colors.ink,
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _venueNeeded = v;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                _SectionLabel(l10n.multiKolabEventFormDateModeLabel),
                KolabingSegmentedControl<MultiKolabDateMode>(
                  key: const Key('multiKolabEventDateModeControl'),
                  segments: [
                    (
                      MultiKolabDateMode.exact,
                      l10n.multiKolabEventFormDateModeExact.toUpperCase(),
                    ),
                    (
                      MultiKolabDateMode.range,
                      l10n.multiKolabEventFormDateModeRange.toUpperCase(),
                    ),
                  ],
                  selectedValue: _dateMode,
                  onChanged: (mode) => setState(() {
                    _dateMode = mode;
                    _dirty = true;
                    _rangeError = null;
                  }),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                if (_dateMode == MultiKolabDateMode.exact)
                  _DateField(
                    fieldKey: const Key('multiKolabEventDateField'),
                    label: l10n.multiKolabEventFormDateLabel,
                    value: _eventDate,
                    onTap: () => _pickDate(_eventDate, (d) => _eventDate = d),
                  )
                else ...[
                  _DateField(
                    fieldKey: const Key('multiKolabEventRangeStartField'),
                    label: l10n.multiKolabEventFormDateFromLabel,
                    value: _rangeStart,
                    onTap: () => _pickDate(_rangeStart, (d) => _rangeStart = d),
                  ),
                  const SizedBox(height: KolabingSpacing.sm),
                  _DateField(
                    fieldKey: const Key('multiKolabEventRangeEndField'),
                    label: l10n.multiKolabEventFormDateToLabel,
                    value: _rangeEnd,
                    errorText: _rangeError,
                    onTap: () => _pickDate(_rangeEnd, (d) => _rangeEnd = d),
                  ),
                ],
                const SizedBox(height: KolabingSpacing.md),
                KolabingInput(
                  key: const Key('multiKolabEventCityField'),
                  controller: _city,
                  label: l10n.multiKolabEventFormCityLabel,
                  maxLength: 100,
                ),
                const SizedBox(height: KolabingSpacing.md),
                KolabingInput(
                  key: const Key('multiKolabEventCategoryField'),
                  controller: _category,
                  label: l10n.multiKolabEventFormCategoryLabel,
                  maxLength: 100,
                ),
                const SizedBox(height: KolabingSpacing.md),
                KolabingInput(
                  key: const Key('multiKolabEventRsvpField'),
                  controller: _rsvpUrl,
                  label: l10n.multiKolabEventFormRsvpLabel,
                  helperText: l10n.multiKolabEventFormRsvpHelper,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (v) => _validateRsvp(v, l10n),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                KolabingButton(
                  key: const Key('multiKolabEventSaveDraftCta'),
                  label: l10n.multiKolabEventFormSaveDraft,
                  isLoading: _submitting,
                  isDisabled: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
                const SizedBox(height: KolabingSpacing.md),
                if (!widget.isEditing)
                  Text(
                    l10n.multiKolabEventFormAddRolesNudge,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.inkBody,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Text(
        text,
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.inkBody,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final Key fieldKey;
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      label:
          '$label. ${value == null ? l10n.multiKolabEventFormDatePick : DateFormat.yMMMd().format(value!)}',
      excludeSemantics: true,
      child: InkWell(
        key: fieldKey,
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          child: Text(
            value == null
                ? l10n.multiKolabEventFormDatePick
                : DateFormat.yMMMd().format(value!),
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: value == null ? colors.muted : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
