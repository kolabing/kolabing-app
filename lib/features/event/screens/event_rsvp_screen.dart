import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// Event detail + RSVP (Phase 3). One-tap "I'm going" / waitlist via
/// `POST`/`DELETE /events/{id}/signup`. The backend handles capacity + the
/// auto-promoting waitlist; we just reflect the returned counts/status.
class EventRsvpScreen extends ConsumerStatefulWidget {
  const EventRsvpScreen({super.key, required this.event});

  final Event event;

  @override
  ConsumerState<EventRsvpScreen> createState() => _EventRsvpScreenState();
}

class _EventRsvpScreenState extends ConsumerState<EventRsvpScreen> {
  late Event _event;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final svc = ref.read(eventServiceProvider);
    final wasIn = _event.isGoing || _event.isWaitlisted;
    try {
      final updated =
          wasIn ? await svc.cancelSignup(_event.id) : await svc.signup(_event.id);
      if (!mounted) return;
      setState(() {
        _event = updated;
        _busy = false;
      });
      // Refresh the community list so its counts/state update too.
      final cid = _event.communityId;
      if (cid != null) {
        ref.invalidate(communityUpcomingEventsProvider(cid));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    final when = e.startsAt ?? e.date;
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          Text(e.name,
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: KolabingSpacing.sm),
          _InfoRow(LucideIcons.calendar, _fmt(when)),
          if (e.location != null && e.location!.isNotEmpty)
            _InfoRow(LucideIcons.mapPin, e.location!),
          _InfoRow(
            LucideIcons.users,
            e.capacity != null
                ? '${e.goingCount} going · ${e.capacity! - e.goingCount} spot(s) left'
                : '${e.goingCount} going',
          ),
          if (e.waitlistCount > 0)
            _InfoRow(LucideIcons.clock, '${e.waitlistCount} on waitlist'),
          const SizedBox(height: KolabingSpacing.xl),
          _rsvpButton(e),
          if (e.isWaitlisted && e.waitlistPosition != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Center(
              child: Text('You’re #${e.waitlistPosition} on the waitlist',
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rsvpButton(Event e) {
    final (String label, IconData icon, Color bg, Color fg) = switch (e) {
      _ when e.isGoing => (
          'Going ✓  ·  tap to leave',
          LucideIcons.check,
          KolabingColors.success,
          KolabingColors.onSurface,
        ),
      _ when e.isWaitlisted => (
          'On waitlist  ·  tap to leave',
          LucideIcons.clock,
          KolabingColors.surfaceContainerHigh,
          KolabingColors.onSurface,
        ),
      _ when e.isFull => (
          'Join waitlist',
          LucideIcons.userPlus,
          KolabingColors.surfaceContainerHigh,
          KolabingColors.onSurface,
        ),
      _ => (
          'I’m going',
          LucideIcons.check,
          KolabingColors.primary,
          KolabingColors.onPrimary,
        ),
    };
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _busy ? null : _toggle,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Expanded(
              child: Text(text, style: KolabingTextStyles.bodyMedium),
            ),
          ],
        ),
      );
}
