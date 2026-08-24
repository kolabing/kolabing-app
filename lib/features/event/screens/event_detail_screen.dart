import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/feature_flags.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/hero_circle_action.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../community/providers/community_providers.dart';
import '../../community/widgets/membership_prompt.dart';
import '../../gamification/providers/active_event_session_provider.dart';
import '../../gamification/providers/checkin_provider.dart';
import '../../gamification/screens/attendee_scanner_screen.dart';
import '../../gamification/services/checkin_service.dart';
import '../../profile/providers/public_profile_provider.dart';
import '../models/event.dart';
import '../models/event_signup.dart';
import '../providers/event_provider.dart';
import '../providers/ticket_provider.dart';
import '../widgets/event_page_sections.dart';
import '../widgets/my_ticket_sheet.dart';
import 'create_event_screen.dart';

/// The one event page.
///
/// It used to be two. This screen (reached from the feed) showed three facts
/// and a green slab whose only job was to *undo* an RSVP, while
/// `EventHubScreen` — reached from the community timeline — held check-in, the
/// organizer's door QR, the attendee roster and photo upload. Two screens for
/// one event drifted apart until the report was "I can't find the event QR
/// code". This is both of them, role-aware:
///
/// - **anyone**: cover, what/when/where, who hosts it (with their socials), how
///   full it is, who can get in, photos;
/// - **going**: their ticket and check-in, in a bar that never scrolls away;
/// - **the host**: the door QR, the roster, edit / photos / extend / delete.
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.isReadOnly = true,
    this.seed,
    this.isLeader = false,
    this.communityName,
  });

  /// For callers that already hold the event — the community timeline and hub,
  /// which used to push `EventHubScreen`. Seeding avoids a spinner on a page
  /// whose content the caller was already rendering.
  factory EventDetailScreen.forEvent(
    Event event, {
    Key? key,
    bool isLeader = false,
    String? communityName,
  }) => EventDetailScreen(
    key: key,
    eventId: event.id,
    seed: event,
    isLeader: isLeader,
    communityName: communityName,
    isReadOnly: !isLeader,
  );

  final String eventId;

  /// False when the caller knows the viewer may manage this event.
  final bool isReadOnly;

  /// A copy the caller already had, rendered until the fetch lands.
  final Event? seed;

  /// The viewer manages the host community (`can_manage`). Host-ness is also
  /// derived from `host_profile_id`, so this only matters for a manager who
  /// does not own the community.
  final bool isLeader;

  /// Passed through to the edit form, which needs a community name.
  final String? communityName;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  /// Local mutable copy so RSVP toggles, edits and photo uploads show at once.
  /// Seeded from whichever source resolves first; the detail fetch is
  /// authoritative for signup state (`my_signup`, counts).
  Event? _event;

  bool _rsvpBusy = false;
  bool _checkinBusy = false;
  bool _openingChat = false;
  bool _uploadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _event = widget.seed;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Event? _cached(EventsState state) {
    for (final e in state.events) {
      if (e.id == widget.eventId) return e;
    }
    return null;
  }

  /// The viewer hosts this event, so every organizer affordance is theirs.
  bool _isHost(Event event) {
    final myProfileId = ref.read(authProvider).user?.id;
    return widget.isLeader ||
        (myProfileId != null &&
            event.hostProfileId != null &&
            event.hostProfileId == myProfileId);
  }

  // ---------------------------------------------------------------------------
  // Attendee actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleRsvp(Event event) async {
    if (_rsvpBusy) return;
    setState(() => _rsvpBusy = true);
    final svc = ref.read(eventServiceProvider);
    final wasIn = event.isGoing || event.isWaitlisted;
    try {
      final updated = wasIn
          ? await svc.cancelSignup(event.id)
          : await svc.signup(event.id);
      if (!mounted) return;
      setState(() {
        _event = updated;
        _rsvpBusy = false;
      });
      // A sign-up mints a ticket server-side; a cancellation retires it.
      ref.invalidate(myTicketsProvider);
      final cid = updated.communityId;
      if (cid != null) {
        ref.read(communityUpcomingEventsProvider(cid).notifier).reload();
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _rsvpBusy = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Check in without an organizer, then open the session so pairing works.
  Future<void> _selfCheckIn(Event event) async {
    if (_checkinBusy) return;
    setState(() => _checkinBusy = true);
    try {
      final checkin = await ref
          .read(checkinServiceProvider)
          .selfCheckIn(event.id);

      // Start the session from the check-in when we got one, and from the event
      // otherwise — a 409 body is not guaranteed to carry it, and the event id
      // is the only thing the session actually needs.
      final sessions = ref.read(activeEventSessionProvider.notifier);
      if (checkin != null) {
        await sessions.start(checkin);
      } else {
        await sessions.startForEvent(eventId: event.id, eventName: event.name);
      }

      if (!mounted) return;
      setState(() => _checkinBusy = false);
      _snack(_l10n.eventCheckinYoureIn);
      // Admission is what the ticket reports, so re-read it.
      ref.invalidate(myTicketsProvider);

      if (checkin != null && mounted) {
        await MembershipPrompt.maybeOffer(context, ref, checkin);
      }
    } on CheckinException catch (e) {
      if (!mounted) return;
      setState(() => _checkinBusy = false);
      // Not deployed yet → send them to the door that does exist, rather than
      // telling them the event refused them.
      if (e.kind == CheckinFailure.unavailable) {
        await AttendeeScannerScreen.open(
          context,
          eventId: event.id,
          eventName: event.name,
        );
        return;
      }
      _snack(e.message);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _checkinBusy = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openChat(Event event) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      // Idempotent create-or-get. Signup-gated for members on the backend.
      final thread = await ref
          .read(chatServiceProvider)
          .createEventChat(event.id, name: event.name);
      if (!mounted) return;
      setState(() => _openingChat = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(thread: thread),
        ),
      );
      // Returning may have moved the read pointer / created the thread.
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(chatUnreadProvider.notifier).refresh();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _openingChat = false);
      _snack(e.message);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _openingChat = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Open the venue in a maps app. The event carries a venue name, a street
  /// address, or both; either is enough for a search, and a printed address
  /// nobody can act on was one of this page's quieter failures.
  Future<void> _directions(Event event) async {
    final query = [
      if (event.location != null && event.location!.isNotEmpty) event.location!,
      if (event.address != null && event.address!.isNotEmpty) event.address!,
      if (event.cityName != null && event.cityName!.isNotEmpty) event.cityName!,
    ].join(', ');
    if (query.isEmpty) return;
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      Platform.isIOS
          ? 'https://maps.apple.com/?q=$encoded'
          : 'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ---------------------------------------------------------------------------
  // Host actions
  // ---------------------------------------------------------------------------

  void _showDoorQr(Event event) => context.push(
    KolabingRoutes.buildEventQRCodePath(event.id, name: event.name),
  );

  Future<void> _edit(Event event) async {
    final updated = await Navigator.of(context).push<Event>(
      MaterialPageRoute<Event>(
        builder: (_) => CreateEventScreen(
          communityId: event.communityId ?? '',
          communityName: widget.communityName ?? event.hostName,
          existing: event,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _event = updated);
      final cid = updated.communityId;
      if (cid != null) {
        ref.read(communityUpcomingEventsProvider(cid).notifier).reload();
      }
    }
  }

  Future<void> _addPhotos(Event event) async {
    if (_uploadingPhotos) return;

    // Gallery caps: up to [kEventGalleryMaxPerAdd] picked per add, and never
    // more than [kEventGalleryMaxTotal] photos on the event in total.
    final existing = event.photos.length;
    if (existing >= kEventGalleryMaxTotal) {
      _snack(_l10n.eventPhotosTotalCapReached(existing, kEventGalleryMaxTotal));
      return;
    }

    final picked = await ImagePicker().pickMultiImage(
      limit: kEventGalleryMaxPerAdd,
    );
    if (picked.isEmpty || !mounted) return;

    var toUpload = picked;
    if (picked.length > kEventGalleryMaxPerAdd) {
      _snack(_l10n.eventPhotosMaxPerAdd(kEventGalleryMaxPerAdd));
      toUpload = picked.take(kEventGalleryMaxPerAdd).toList();
    }
    final remaining = kEventGalleryMaxTotal - existing;
    if (toUpload.length > remaining) {
      _snack(
        _l10n.eventPhotosTotalCapPartial(remaining, kEventGalleryMaxTotal),
      );
      toUpload = toUpload.take(remaining).toList();
    }
    if (toUpload.isEmpty) return;

    setState(() => _uploadingPhotos = true);
    try {
      final updated = await ref
          .read(eventServiceProvider)
          .addEventPhotos(event.id, toUpload.map((x) => x.path).toList());
      if (!mounted) return;
      setState(() {
        _event = updated;
        _uploadingPhotos = false;
      });
      _snack(_l10n.eventFormPhotosUploaded);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhotos = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _extend(Event event) async {
    final seriesId = event.seriesId;
    if (seriesId == null) return;
    try {
      final created = await ref
          .read(eventServiceProvider)
          .extendSeries(seriesId);
      final cid = event.communityId;
      if (cid != null) {
        ref.read(communityUpcomingEventsProvider(cid).notifier).reload();
      }
      if (!mounted) return;
      _snack(
        created > 0
            ? _l10n.eventHubExtended(created)
            : _l10n.eventHubExtendedNone,
      );
    } on Object catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Scope-aware delete: one occurrence, this and the following, or the series.
  Future<void> _delete(Event event) async {
    var scope = 'this';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(_l10n.eventHubDeleteConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_l10n.eventHubDeleteConfirmBody(event.name)),
              if (event.isRecurring) ...[
                const SizedBox(height: KolabingSpacing.sm),
                for (final opt in [
                  ('this', _l10n.eventHubDeleteScopeThis),
                  ('following', _l10n.eventHubDeleteScopeFollowing),
                  ('series', _l10n.eventHubDeleteScopeSeries),
                ])
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: opt.$1,
                    groupValue: scope,
                    title: Text(opt.$2),
                    onChanged: (v) => setLocal(() => scope = v ?? 'this'),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              child: Text(_l10n.commonDelete),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(eventServiceProvider).deleteEvent(event.id, scope: scope);
      final cid = event.communityId;
      if (cid != null) {
        ref.read(communityUpcomingEventsProvider(cid).notifier).reload();
      }
      if (!mounted) return;
      _snack(_l10n.eventHubDeleted);
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // A local mutation (RSVP, edit, photos) already produced an event.
    final local = _event;
    if (local != null) return _content(local);

    // Always fetch detail for authoritative signup state (my_signup + counts).
    final asyncEvent = ref.watch(eventDetailProvider(widget.eventId));
    return asyncEvent.when(
      loading: () {
        final cached = _cached(ref.watch(eventsProvider));
        return cached != null ? _content(cached) : _loading();
      },
      error: (error, _) {
        final cached = _cached(ref.watch(eventsProvider));
        return cached != null
            ? _content(cached)
            : _missing(title: _l10n.eventDetailNotFound, message: '$error');
      },
      data: _content,
    );
  }

  Widget _loading() => Scaffold(
    backgroundColor: context.colors.background,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(LucideIcons.arrowLeft),
        color: context.colors.onSurface,
      ),
    ),
    body: Center(
      child: CircularProgressIndicator(color: context.colors.primary),
    ),
  );

  Widget _missing({required String title, String? message}) => Scaffold(
    backgroundColor: context.colors.background,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(LucideIcons.arrowLeft),
        color: context.colors.onSurface,
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarX,
              size: 48,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.titleMedium.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _content(Event event) {
    final isHost = _isHost(event);
    final session = ref.watch(activeEventSessionProvider);
    final checkedIn = session?.eventId == event.id;
    final ticket = ref
        .watch(myTicketForEventProvider(event.id))
        .maybeWhen(data: (t) => t, orElse: () => null);

    return Scaffold(
      backgroundColor: context.colors.background,
      bottomNavigationBar: EventActionBar(
        children: _barActions(
          event,
          isHost: isHost,
          checkedIn: checkedIn,
          hasTicket: ticket != null,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _appBar(event, isHost: isHost),

          SliverToBoxAdapter(
            child: EventTitleBlock(
              event: event,
              onDirections: () => _directions(event),
              statusLine: _statusLine(event),
            ),
          ),

          SliverToBoxAdapter(
            child: _HostCard(event: event, onOpen: () => _openHost(event)),
          ),

          SliverToBoxAdapter(child: EventDetailsSection(event: event)),

          if (isHost) SliverToBoxAdapter(child: _Attendees(eventId: event.id)),

          if (event.photos.length > 1)
            SliverToBoxAdapter(child: _photos(event)),

          if (event.videos.isNotEmpty)
            SliverToBoxAdapter(child: _videos(event)),

          // Chat: the host always, an attendee once they are coming.
          if (isHost || event.isGoing)
            SliverToBoxAdapter(
              child: EventNavRow(
                icon: LucideIcons.messageCircle,
                title: _l10n.eventHubOpenChat,
                busy: _openingChat,
                onTap: () => _openChat(event),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: KolabingSpacing.xl)),
        ],
      ),
    );
  }

  Widget _appBar(Event event, {required bool isHost}) => SliverAppBar(
    expandedHeight: 260,
    pinned: true,
    backgroundColor: context.colors.surface,
    automaticallyImplyLeading: false,
    leading: Padding(
      padding: const EdgeInsets.only(left: KolabingSpacing.xs),
      child: Center(
        child: HeroCircleAction(
          icon: LucideIcons.arrowLeft,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
    actions: [
      if (isHost)
        Center(
          child: PopupMenuButton<String>(
            icon: const HeroCircleAction(
              icon: LucideIcons.moreHorizontal,
              onTap: _noop,
            ),
            onSelected: (v) => switch (v) {
              'edit' => _edit(event),
              'photos' => _addPhotos(event),
              'extend' => _extend(event),
              'delete' => _delete(event),
              _ => null,
            },
            itemBuilder: (_) => [
              _menuItem('edit', LucideIcons.pencil, _l10n.eventHubEdit),
              _menuItem(
                'photos',
                LucideIcons.imagePlus,
                _l10n.eventHubAddPhotos,
              ),
              if (event.isRecurring)
                _menuItem(
                  'extend',
                  LucideIcons.calendarPlus,
                  _l10n.eventHubExtendSeries,
                ),
              _menuItem(
                'delete',
                LucideIcons.trash2,
                _l10n.eventHubDelete,
                danger: true,
              ),
            ],
          ),
        ),
      const SizedBox(width: KolabingSpacing.xs),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: EventHeroBackground(
        photos: event.photos,
        controller: _pageController,
        currentIndex: _currentPhotoIndex,
        onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
      ),
    ),
  );

  static void _noop() {}

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) => PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: danger ? context.colors.error : context.colors.onSurface,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Text(label),
      ],
    ),
  );

  /// The RSVP state, as a line rather than the page's loudest control.
  Widget? _statusLine(Event event) {
    if (event.isGoing) {
      return EventStatusLine(
        label: _l10n.eventHubGoingTapToLeave,
        icon: LucideIcons.check,
        fill: context.colors.activeBg,
        ink: context.colors.activeText,
        busy: _rsvpBusy,
        onUndo: () => _toggleRsvp(event),
      );
    }
    if (event.isWaitlisted) {
      return EventStatusLine(
        label: _l10n.eventHubOnWaitlistTapToLeave,
        icon: LucideIcons.clock,
        fill: context.colors.pendingBg,
        ink: context.colors.pendingText,
        busy: _rsvpBusy,
        onUndo: () => _toggleRsvp(event),
      );
    }
    return null;
  }

  /// The sticky bar, by state. At most two actions: a door is not the place to
  /// choose between five.
  List<Widget> _barActions(
    Event event, {
    required bool isHost,
    required bool checkedIn,
    required bool hasTicket,
  }) {
    if (isHost) {
      return [
        if (kEventCheckinQrEnabled)
          EventActionButton(
            label: _l10n.eventHubShowCheckinQr,
            icon: LucideIcons.qrCode,
            filled: true,
            onTap: () => _showDoorQr(event),
          ),
        EventActionButton(
          label: _l10n.eventHubOpenChat,
          icon: LucideIcons.messageCircle,
          filled: !kEventCheckinQrEnabled,
          busy: _openingChat,
          onTap: () => _openChat(event),
        ),
      ];
    }

    // Past or read-only events have nothing to act on.
    if (!event.isUpcoming) return const [];

    final myTicket = EventActionButton(
      label: _l10n.eventPageMyTicket,
      icon: LucideIcons.ticket,
      filled: true,
      onTap: () async {
        final ticket = await ref.read(
          myTicketForEventProvider(event.id).future,
        );
        if (ticket != null && mounted) {
          await MyTicketSheet.show(context, ticket);
        }
      },
    );

    if (event.isGoing) {
      return [
        if (hasTicket) myTicket,
        if (kEventCheckinQrEnabled)
          checkedIn
              ? EventActionButton(
                  label: _l10n.challengeFirstChoose,
                  icon: LucideIcons.swords,
                  filled: !hasTicket,
                  onTap: () => context.push(
                    KolabingRoutes.buildEventChallengesPath(event.id),
                  ),
                )
              : EventActionButton(
                  label: _l10n.eventCheckinImHere,
                  icon: LucideIcons.mapPin,
                  filled: !hasTicket,
                  busy: _checkinBusy,
                  onTap: () => _selfCheckIn(event),
                ),
      ];
    }

    if (event.isWaitlisted) {
      return [if (hasTicket) myTicket];
    }

    return [
      EventActionButton(
        label: event.isFull
            ? _l10n.eventHubJoinWaitlist
            : _l10n.eventHubImGoing,
        icon: event.isFull ? LucideIcons.userPlus : LucideIcons.check,
        filled: true,
        busy: _rsvpBusy,
        onTap: () => _toggleRsvp(event),
      ),
    ];
  }

  /// Open the host. The destination is viewer-scoped: a BUSINESS viewer keeps
  /// the profile-id-keyed `PublicProfileScreen` (Send-Kolab flow); everyone else
  /// gets the community-keyed page. `communityId` is a `communities.id`, so
  /// pushing it into `/profile/{id}` would 404 the profile endpoints (F1).
  void _openHost(Event event) {
    final communityId = event.communityId;
    final hostProfileId = event.hostProfileId;
    final isBusiness =
        ref.read(authProvider).user?.userType == UserType.business;

    if (isBusiness && hostProfileId != null && hostProfileId.isNotEmpty) {
      context.push('/profile/$hostProfileId');
      return;
    }
    if (communityId != null && communityId.isNotEmpty) {
      context.push(KolabingRoutes.buildCommunityProfilePath(communityId));
    }
  }

  Widget _photos(Event event) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.lg,
      KolabingSpacing.md,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventSectionLabel(_l10n.eventDetailPhotosTitle),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: KolabingSpacing.xs,
            crossAxisSpacing: KolabingSpacing.xs,
          ),
          itemCount: event.photos.length,
          itemBuilder: (_, i) {
            final photo = event.photos[i];
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KolabingRadius.md),
                  border: Border.all(
                    color: _currentPhotoIndex == i
                        ? context.colors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(KolabingRadius.md),
                  child: Image.network(
                    photo.thumbnailUrl ?? photo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: context.colors.surfaceVariant,
                      child: Icon(
                        LucideIcons.image,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _videos(Event event) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.lg,
      KolabingSpacing.md,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventSectionLabel(_l10n.eventDetailVideosTitle),
        for (var i = 0; i < event.videos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: EventNavRow(
              icon: LucideIcons.playCircle,
              title: _l10n.eventDetailRecapVideoTitle(i + 1),
              subtitle: _l10n.eventDetailRecapVideoSubtitle,
              onTap: () => _openVideo(event.videos[i].url),
            ),
          ),
      ],
    ),
  );

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) _snack(_l10n.eventDetailVideoOpenError);
  }
}

// =============================================================================
// Host card — identity + about + socials, from the host's public profile
// =============================================================================

/// The host, with the socials the old page had nowhere to put.
///
/// `community_profiles` stores instagram, tiktok and website; the about text is
/// the community's, which is the honest cost of an `events` table with no
/// description of its own — the same paragraph on every event it runs.
class _HostCard extends ConsumerWidget {
  const _HostCard({required this.event, required this.onOpen});

  final Event event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hostProfileId = event.hostProfileId;

    // Self-gated: no host profile id on older payloads, and the fetch may be in
    // flight — the card renders from the event alone until it lands.
    final profile = hostProfileId == null || hostProfileId.isEmpty
        ? null
        : ref
              .watch(publicProfileProvider(hostProfileId))
              .maybeWhen(data: (p) => p, orElse: () => null);

    final canOpen =
        (event.communityId != null && event.communityId!.isNotEmpty) ||
        (hostProfileId != null && hostProfileId.isNotEmpty);

    return EventHostCard(
      hostName: event.hostName,
      // The community's own type ("Running club"), resolved through the same
      // dynamic taxonomy the community pages use. Falls back to the generic
      // label while it loads or for a business host, which has no such slug.
      typeLabel:
          ref.watch(communityTypeLabelProvider(event.communityType)) ??
          l10n.eventDetailKolabWithLabel,
      avatarUrl: profile?.avatarUrl ?? event.partner.profilePhoto,
      about: profile?.about,
      instagram: profile?.instagram,
      tiktok: profile?.tiktok,
      website: profile?.website,
      onOpen: canOpen ? onOpen : null,
    );
  }
}

// =============================================================================
// Attendees — host-only roster, ported from the deleted event hub
// =============================================================================

/// Host-only: confirmed attendees + waitlist from `GET /events/{id}/signups`.
class _Attendees extends ConsumerWidget {
  const _Attendees({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventSignupsProvider(eventId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.lg,
        KolabingSpacing.md,
        0,
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _empty(context, l10n),
        data: (signups) {
          if (signups.isEmpty) return _empty(context, l10n);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventSectionLabel(
                '${l10n.eventHubAttendeesTitle} · '
                '${l10n.eventHubGoingCount(signups.going.length)}',
              ),
              for (final s in signups.going) _AttendeeTile(signup: s),
              if (signups.waitlist.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.sm),
                EventSectionLabel(l10n.eventHubWaitlistTitle),
                for (final s in signups.waitlist) _AttendeeTile(signup: s),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EventSectionLabel(l10n.eventHubAttendeesTitle),
      Text(
        l10n.eventHubNoAttendees,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _AttendeeTile extends StatelessWidget {
  const _AttendeeTile({required this.signup});

  final EventSignup signup;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: CircleAvatar(
      backgroundColor: context.colors.primary.withValues(alpha: 0.2),
      backgroundImage: signup.avatarUrl != null
          ? NetworkImage(signup.avatarUrl!)
          : null,
      child: signup.avatarUrl == null
          ? Text(
              signup.name.isNotEmpty ? signup.name[0].toUpperCase() : '?',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    ),
    title: Text(
      signup.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: KolabingTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: signup.isWaitlisted && signup.waitlistPosition != null
        ? Text(
            '#${signup.waitlistPosition}',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        : null,
  );
}
