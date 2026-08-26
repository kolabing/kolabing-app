/// A community's events: filter chips over a date-grouped timeline.
///
/// Extracted from `community_detail_screen.dart` for the same reason the rewards
/// admin was — it was private to that screen, so the merged profile page's
/// Manage → Events row had to push the entire old Community page (cover, photo
/// strip, rewards admin, roster) to get at it. It is a widget now, so
/// [CommunityEventsScreen] can show only the events.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../event/screens/event_detail_screen.dart';
import '../../event/widgets/event_timeline.dart';
import '../models/community.dart';
import 'community_page_sections.dart';

class CommunityEventsPanel extends ConsumerStatefulWidget {
  const CommunityEventsPanel({
    super.key,
    required this.community,
    required this.canManage,
  });

  final Community community;

  /// Whether the viewer manages this community. Decides whether tapping an
  /// event opens it in leader mode — without it a leader reaching their own
  /// event from here got the member view, with no way to show its check-in QR.
  final bool canManage;

  @override
  ConsumerState<CommunityEventsPanel> createState() =>
      _CommunityEventsPanelState();
}

class _CommunityEventsPanelState extends ConsumerState<CommunityEventsPanel> {
  CommunityEventFilter _filter = CommunityEventFilter.upcoming;

  static bool _isPublic(Event e) => (e.visibility ?? 'members') == 'public';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.community.id;

    final upcomingAsync = ref.watch(communityUpcomingEventsProvider(id));
    final upcoming = upcomingAsync.maybeWhen(
      data: (e) => e,
      orElse: () => const <Event>[],
    );
    // Past events make a community between events look alive rather than
    // abandoned. The provider has existed since NF-6 and nothing called it.
    final past = ref
        .watch(communityPastEventsProvider(id))
        .maybeWhen(data: (e) => e, orElse: () => const <Event>[]);

    final counts = <CommunityEventFilter, int>{
      CommunityEventFilter.upcoming: upcoming.length,
      CommunityEventFilter.past: past.length,
      CommunityEventFilter.publicOnly: upcoming.where(_isPublic).length,
      CommunityEventFilter.membersOnly: upcoming
          .where((e) => !_isPublic(e))
          .length,
    };

    final shown = switch (_filter) {
      CommunityEventFilter.upcoming => upcoming,
      CommunityEventFilter.past => past,
      CommunityEventFilter.publicOnly => upcoming.where(_isPublic).toList(),
      CommunityEventFilter.membersOnly =>
        upcoming.where((e) => !_isPublic(e)).toList(),
    };

    if (upcomingAsync.isLoading && upcoming.isEmpty && past.isEmpty) {
      return const _InlineLoader();
    }
    // Nothing at all, ever — the honest empty state.
    if (upcoming.isEmpty && past.isEmpty) return const _NoEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityFilterChips(
          counts: counts,
          selected: _filter,
          onSelect: (f) => setState(() => _filter = f),
        ),
        if (shown.isEmpty)
          _EmptyLine(text: l10n.communityDetailNoEventsBody)
        else
          EventTimeline(
            events: shown,
            onOpen: (event) => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailScreen.forEvent(
                  event,
                  isLeader: widget.canManage,
                ),
              ),
            ),
            onLocked: (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.communityDetailEventLockedSnack)),
            ),
          ),
      ],
    );
  }
}

class _NoEvents extends StatelessWidget {
  const _NoEvents();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
      child: EmptyStateCard(
        icon: LucideIcons.calendar,
        title: l10n.communityDetailNoEventsTitle,
        message: l10n.communityDetailNoEventsBody,
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
    child: Text(
      text,
      style: KolabingTextStyles.bodySmall.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.primary,
        ),
      ),
    ),
  );
}
