import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../chat/services/chat_service.dart';
import '../models/event.dart';
import '../models/event_signup.dart';
import '../providers/event_provider.dart';
import 'create_event_screen.dart';

/// Event detail = management hub (NF-16 B1).
///
/// One screen, two modes:
/// - Leader (`isLeader: true`): details + gallery, the ATTENDEES roster
///   (`GET /events/{id}/signups`), Edit/Add-photos, and "Open event chat".
/// - Member: details + gallery, the RSVP button (going / waitlist via
///   `POST`/`DELETE /events/{id}/signup`) and, once going, "Open event chat".
///
/// Replaces the old standalone RSVP screen; the chat thread it opens is the
/// existing [ChatThreadScreen] (created/fetched idempotently).
class EventHubScreen extends ConsumerStatefulWidget {
  const EventHubScreen({
    super.key,
    required this.event,
    this.isLeader = false,
    this.communityName,
  });

  final Event event;
  final bool isLeader;
  final String? communityName;

  @override
  ConsumerState<EventHubScreen> createState() => _EventHubScreenState();
}

class _EventHubScreenState extends ConsumerState<EventHubScreen> {
  late Event _event;
  bool _busy = false;
  bool _openingChat = false;
  bool _uploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  // RSVP (member) ------------------------------------------------------------

  Future<void> _toggleRsvp() async {
    if (_busy) return;
    setState(() => _busy = true);
    final svc = ref.read(eventServiceProvider);
    final wasIn = _event.isGoing || _event.isWaitlisted;
    try {
      final updated = wasIn
          ? await svc.cancelSignup(_event.id)
          : await svc.signup(_event.id);
      if (!mounted) return;
      setState(() {
        _event = updated;
        _busy = false;
      });
      final cid = _event.communityId;
      if (cid != null) {
        ref.invalidate(communityUpcomingEventsProvider(cid));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Event chat (both roles) --------------------------------------------------

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      // Idempotent create-or-get. Signup-gated for members on the backend.
      final thread = await ref
          .read(chatServiceProvider)
          .createEventChat(_event.id, name: _event.name);
      if (!mounted) return;
      setState(() => _openingChat = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ChatThreadScreen(thread: thread)),
      );
      // Returning may have moved the read pointer / created the thread.
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(chatUnreadProvider.notifier).refresh();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _openingChat = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _openingChat = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Leader: edit + add photos ------------------------------------------------

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Event>(
      MaterialPageRoute<Event>(
        builder: (_) => CreateEventScreen(
          communityId: _event.communityId ?? '',
          communityName: widget.communityName ?? _event.partner.name,
          existing: _event,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _event = updated);
      final cid = _event.communityId;
      if (cid != null) ref.invalidate(communityUpcomingEventsProvider(cid));
    }
  }

  Future<void> _addPhotos() async {
    if (_uploadingPhotos) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploadingPhotos = true);
    try {
      final updated = await ref
          .read(eventServiceProvider)
          .addEventPhotos(_event.id, picked.map((x) => x.path).toList());
      if (!mounted) return;
      setState(() {
        _event = updated;
        _uploadingPhotos = false;
      });
      _snack(_l10n.eventFormPhotosUploaded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhotos = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final e = _event;
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.isLeader)
            TextButton(
              onPressed: _busy ? null : _edit,
              child: Text(_l10n.eventHubEdit),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          if (e.photos.isNotEmpty) ...[
            _Gallery(event: e),
            const SizedBox(height: KolabingSpacing.md),
          ],
          if (widget.isLeader) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadingPhotos ? null : _addPhotos,
                icon: _uploadingPhotos
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.imagePlus, size: 18),
                label: Text(_l10n.eventHubAddPhotos),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
          ],
          Text(
            e.name,
            style: KolabingTextStyles.bodyLarge
                .copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _InfoRow(LucideIcons.calendar, _fmt(e.startsAt ?? e.date)),
          if (e.location != null && e.location!.isNotEmpty)
            _InfoRow(LucideIcons.mapPin, e.location!),
          _InfoRow(LucideIcons.users, _capacityLine(e)),
          if (e.waitlistCount > 0)
            _InfoRow(
              LucideIcons.clock,
              _l10n.eventHubWaitlistCount(e.waitlistCount),
            ),
          const SizedBox(height: KolabingSpacing.lg),
          if (!widget.isLeader) ...[
            _rsvpButton(e),
            if (e.isWaitlisted && e.waitlistPosition != null) ...[
              const SizedBox(height: KolabingSpacing.sm),
              Center(
                child: Text(
                  _l10n.eventHubWaitlistPosition(e.waitlistPosition!),
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: KolabingSpacing.sm),
          ],
          // Open event chat: always for the leader; for members once going.
          if (widget.isLeader || e.isGoing) _chatButton(),
          if (widget.isLeader) ...[
            const SizedBox(height: KolabingSpacing.xl),
            _AttendeesSection(eventId: e.id),
          ],
          const SizedBox(height: KolabingSpacing.xxl),
        ],
      ),
    );
  }

  String _capacityLine(Event e) {
    if (e.capacity == null) {
      return '${_l10n.eventHubGoingCount(e.goingCount)} · ${_l10n.eventHubUnlimited}';
    }
    final left = (e.capacity! - e.goingCount).clamp(0, e.capacity!);
    return '${_l10n.eventHubGoingCount(e.goingCount)} · '
        '${_l10n.eventHubCapacity(e.capacity!)} · ${_l10n.eventHubSpotsLeft(left)}';
  }

  Widget _chatButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: _openingChat ? null : _openChat,
          style: FilledButton.styleFrom(
            backgroundColor: KolabingColors.surfaceContainerHigh,
            foregroundColor: KolabingColors.onSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _openingChat
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(LucideIcons.messageCircle, size: 18),
          label: Text(
            _l10n.eventHubOpenChat,
            style: KolabingTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );

  Widget _rsvpButton(Event e) {
    final (String label, IconData icon, Color bg, Color fg) = switch (e) {
      _ when e.isGoing => (
          _l10n.eventHubGoingTapToLeave,
          LucideIcons.check,
          KolabingColors.success,
          KolabingColors.onSurface,
        ),
      _ when e.isWaitlisted => (
          _l10n.eventHubOnWaitlistTapToLeave,
          LucideIcons.clock,
          KolabingColors.surfaceContainerHigh,
          KolabingColors.onSurface,
        ),
      _ when e.isFull => (
          _l10n.eventHubJoinWaitlist,
          LucideIcons.userPlus,
          KolabingColors.surfaceContainerHigh,
          KolabingColors.onSurface,
        ),
      _ => (
          _l10n.eventHubImGoing,
          LucideIcons.check,
          KolabingColors.primary,
          KolabingColors.onPrimary,
        ),
    };
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _busy ? null : _toggleRsvp,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 18),
        label: Text(label,
            style: KolabingTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700)),
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

/// Leader-only: confirmed attendees + waitlist from `GET /events/{id}/signups`.
class _AttendeesSection extends ConsumerWidget {
  const _AttendeesSection({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventSignupsProvider(eventId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        child: Text(
          l10n.eventHubNoAttendees,
          style: KolabingTextStyles.bodySmall
              .copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      ),
      data: (signups) {
        if (signups.isEmpty) {
          return Text(
            l10n.eventHubNoAttendees,
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.onSurfaceVariant),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              '${l10n.eventHubAttendeesTitle} · ${l10n.eventHubGoingCount(signups.going.length)}',
            ),
            for (final s in signups.going) _AttendeeTile(signup: s),
            if (signups.waitlist.isNotEmpty) ...[
              const SizedBox(height: KolabingSpacing.md),
              _SectionLabel(l10n.eventHubWaitlistTitle),
              for (final s in signups.waitlist) _AttendeeTile(signup: s),
            ],
          ],
        );
      },
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  const _AttendeeTile({required this.signup});

  final EventSignup signup;

  @override
  Widget build(BuildContext context) {
    final initial = signup.name.isNotEmpty ? signup.name[0].toUpperCase() : '?';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
        backgroundImage:
            signup.avatarUrl != null ? NetworkImage(signup.avatarUrl!) : null,
        child: signup.avatarUrl == null
            ? Text(initial,
                style: KolabingTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700))
            : null,
      ),
      title: Text(
        signup.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KolabingTextStyles.bodyMedium
            .copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: signup.isWaitlisted && signup.waitlistPosition != null
          ? Text('#${signup.waitlistPosition}',
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant))
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
        child: Text(
          text.toUpperCase(),
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: KolabingColors.onSurfaceVariant,
          ),
        ),
      );
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: event.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: KolabingSpacing.xs),
        itemBuilder: (_, i) {
          final p = event.photos[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p.thumbnailUrl ?? p.url,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: KolabingColors.surfaceVariant,
                child: const Icon(LucideIcons.image,
                    color: KolabingColors.textTertiary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 18, color: KolabingColors.onSurfaceVariant),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(child: Text(text, style: KolabingTextStyles.bodyMedium)),
          ],
        ),
      );
}
