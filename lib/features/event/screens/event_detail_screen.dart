import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// Detail screen for viewing a single event
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.isReadOnly = true,
  });

  final String eventId;
  final bool isReadOnly;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  /// Local mutable copy of the event so RSVP toggles reflect immediately. Seeded
  /// from whichever source first resolves (cached list or the detail fetch); the
  /// fetch is authoritative for signup state (`my_signup`, counts).
  Event? _event;
  bool _rsvpBusy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Event? _getEvent(EventsState state) {
    try {
      return state.events.firstWhere((e) => e.id == widget.eventId);
    } catch (_) {
      return null;
    }
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  // RSVP / sign-up (attendee / public viewer) --------------------------------

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
      final cid = updated.communityId;
      if (cid != null) {
        ref.read(communityUpcomingEventsProvider(cid).notifier).reload();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _rsvpBusy = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleDelete(Event event) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.eventDetailDeleteTitle),
        content: Text(l10n.eventDetailDeleteConfirm(event.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(l10n.eventDetailDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(eventsProvider.notifier)
          .deleteEvent(event.id);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.eventDetailDeletedSnack),
            backgroundColor: context.colors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = !widget.isReadOnly;

    // A local RSVP toggle already produced an updated event — render it.
    if (_event != null) {
      return _buildContent(_event!, canDelete: canDelete);
    }

    // Always fetch detail for authoritative signup state (my_signup + counts).
    // The cached list event is only a fallback while the fetch is in flight.
    final asyncEvent = ref.watch(eventDetailProvider(widget.eventId));

    return asyncEvent.when(
      loading: () {
        final cached = _getEvent(ref.watch(eventsProvider));
        if (cached != null) {
          return _buildContent(cached, canDelete: canDelete);
        }
        return _buildLoadingState();
      },
      error: (error, _) {
        final cached = _getEvent(ref.watch(eventsProvider));
        if (cached != null) {
          return _buildContent(cached, canDelete: canDelete);
        }
        return _buildMissingState(
          title: AppLocalizations.of(context).eventDetailNotFound,
          message: error.toString(),
        );
      },
      data: (event) => _buildContent(event, canDelete: canDelete),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
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
  }

  Widget _buildMissingState({required String title, String? message}) {
    return Scaffold(
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
              style: KolabingTextStyles.titleMedium.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: KolabingSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.lg,
                ),
                child: Text(
                  message,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Event event, {required bool canDelete}) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          _buildSliverAppBar(event),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    event.name,
                    style: KolabingTextStyles.headlineMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Info Cards
                  _buildInfoCard(event),

                  // RSVP / sign-up for upcoming, signup-able events.
                  if (event.isUpcoming) ...[
                    const SizedBox(height: KolabingSpacing.lg),
                    _buildRsvpButton(event),
                    if (event.isWaitlisted &&
                        event.waitlistPosition != null) ...[
                      const SizedBox(height: KolabingSpacing.sm),
                      Center(
                        child: Text(
                          _l10n.eventHubWaitlistPosition(
                            event.waitlistPosition!,
                          ),
                          style: KolabingTextStyles.bodySmall.copyWith(
                            color: KolabingColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: KolabingSpacing.lg),

                  // Photo Gallery
                  if (event.photos.length > 1) ...[
                    Text(
                      AppLocalizations.of(context).eventDetailPhotosTitle,
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    _buildPhotoGrid(event),
                    const SizedBox(height: KolabingSpacing.lg),
                  ],

                  if (event.videos.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context).eventDetailVideosTitle,
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    _buildVideoList(event),
                  ],

                  const SizedBox(height: KolabingSpacing.xl),

                  if (canDelete)
                    OutlinedButton.icon(
                      onPressed: () => _handleDelete(event),
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: Text(
                        AppLocalizations.of(context).eventDetailDeleteButton,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: KolabingSpacing.sm,
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                  const SizedBox(height: KolabingSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// RSVP button mirroring `event_hub_screen._rsvpButton`: going (mint
  /// active-state tokens) / waitlisted / join-waitlist (full) / I'm going.
  Widget _buildRsvpButton(Event event) {
    final (String label, IconData icon, Color bg, Color fg) = switch (event) {
      _ when event.isGoing => (
        _l10n.eventHubGoingTapToLeave,
        LucideIcons.check,
        KolabingColors.activeBg,
        KolabingColors.activeText,
      ),
      _ when event.isWaitlisted => (
        _l10n.eventHubOnWaitlistTapToLeave,
        LucideIcons.clock,
        KolabingColors.surfaceContainerHigh,
        KolabingColors.onSurface,
      ),
      _ when event.isFull => (
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
        onPressed: _rsvpBusy ? null : () => _toggleRsvp(event),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _rsvpBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: context.colors.surface,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Photo Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: event.photos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = event.photos[index];
                return Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: context.colors.surfaceVariant,
                    child: Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Page Indicator
            if (event.photos.length > 1)
              Positioned(
                bottom: KolabingSpacing.md,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    event.photos.length,
                    (index) => Container(
                      width: _currentPhotoIndex == index ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _currentPhotoIndex == index
                            ? context.colors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Partner / host community (tappable → public profile when known).
          _buildInfoRow(
            icon: LucideIcons.users,
            label: AppLocalizations.of(context).eventDetailKolabWithLabel,
            child: _buildPartnerChild(event),
          ),

          Divider(height: KolabingSpacing.lg, color: context.colors.darkBorder),

          // Date
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: AppLocalizations.of(context).eventDetailDateLabel,
            value: event.formattedDate,
          ),

          Divider(height: KolabingSpacing.lg, color: context.colors.darkBorder),

          // Attendees
          _buildInfoRow(
            icon: LucideIcons.userCheck,
            label: AppLocalizations.of(context).eventDetailAttendeesLabel,
            value: AppLocalizations.of(
              context,
            ).eventDetailAttendeesCount(event.attendeeCount),
          ),
        ],
      ),
    );
  }

  /// The host partner block. When the event carries a `communityId`, the whole
  /// row becomes tappable and opens the community's public profile
  /// (`/profile/:id`); otherwise it renders inert.
  Widget _buildPartnerChild(Event event) {
    final communityId = event.communityId;
    final tappable = communityId != null && communityId.isNotEmpty;

    final row = Row(
      children: [
        // Partner avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KolabingColors.darkBorder, width: 1),
          ),
          child: ClipOval(
            child: event.partner.profilePhoto != null
                ? Image.network(
                    event.partner.profilePhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPartnerPlaceholder(event.partner.name),
                  )
                : _buildPartnerPlaceholder(event.partner.name),
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.partner.name,
                style: KolabingTextStyles.titleSmall.copyWith(
                  color: KolabingColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: event.partner.type == PartnerType.business
                      ? KolabingColors.softYellow
                      : KolabingColors.info.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
                child: Text(
                  event.partner.type.name.toUpperCase(),
                  style: KolabingTextStyles.labelSmall.copyWith(
                    color: event.partner.type == PartnerType.business
                        ? KolabingColors.accentOrangeText
                        : KolabingColors.info,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (tappable)
          Padding(
            padding: const EdgeInsets.only(left: KolabingSpacing.xs),
            child: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: KolabingColors.textTertiary,
              semanticLabel: _l10n.eventDetailViewCommunity,
            ),
          ),
      ],
    );

    if (!tappable) return row;

    return InkWell(
      onTap: () => context.push('/profile/$communityId'),
      borderRadius: KolabingRadius.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }

  Widget _buildVideoList(Event event) {
    return Column(
      children: List.generate(event.videos.length, (index) {
        final video = event.videos[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == event.videos.length - 1 ? 0 : KolabingSpacing.sm,
          ),
          child: InkWell(
            onTap: () => _openVideo(video.url),
            borderRadius: KolabingRadius.borderRadiusMd,
            child: Container(
              padding: const EdgeInsets.all(KolabingSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(color: context.colors.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: KolabingRadius.borderRadiusMd,
                      image: video.thumbnailUrl != null
                          ? DecorationImage(
                              image: NetworkImage(video.thumbnailUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: video.thumbnailUrl == null
                        ? Icon(
                            LucideIcons.playCircle,
                            color: context.colors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).eventDetailRecapVideoTitle(index + 1),
                          style: KolabingTextStyles.titleSmall.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).eventDetailRecapVideoSubtitle,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: context.colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).eventDetailVideoOpenError),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
          child: Icon(icon, size: 20, color: context.colors.primary),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: KolabingTextStyles.labelSmall.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              if (child != null)
                child
              else if (value != null)
                Text(
                  value,
                  style: KolabingTextStyles.titleSmall.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerPlaceholder(String name) => Container(
    color: context.colors.primary,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
  );

  Widget _buildPhotoGrid(Event event) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: KolabingSpacing.xs,
        crossAxisSpacing: KolabingSpacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: event.photos.length,
      itemBuilder: (context, index) {
        final photo = event.photos[index];
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(
                color: _currentPhotoIndex == index
                    ? context.colors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: KolabingRadius.borderRadiusSm,
              child: Image.network(
                photo.thumbnailUrl ?? photo.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
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
    );
  }
}
