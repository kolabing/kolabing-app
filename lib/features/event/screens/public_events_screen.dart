import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/public_event.dart';
import '../providers/event_provider.dart';
import '../providers/public_events_provider.dart';
import '../services/event_service.dart';
import '../widgets/public_event_card.dart';

/// Attendee Explore: the public-events feed (`GET /events/discovery`).
///
/// Each card RSVPs directly (public events accept any attendee). A members-only
/// event would never appear here, but if an RSVP comes back 403
/// `community_membership_required` we surface the "Join community to RSVP" gate
/// instead of a raw error.
class PublicEventsScreen extends ConsumerStatefulWidget {
  const PublicEventsScreen({super.key});

  @override
  ConsumerState<PublicEventsScreen> createState() => _PublicEventsScreenState();
}

class _PublicEventsScreenState extends ConsumerState<PublicEventsScreen> {
  final Set<String> _rsvping = <String>{};
  final Set<String> _going = <String>{};

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> _rsvp(PublicEvent event) async {
    if (_rsvping.contains(event.id)) return;
    setState(() => _rsvping.add(event.id));
    try {
      await ref.read(eventServiceProvider).signup(event.id);
      if (!mounted) return;
      setState(() {
        _rsvping.remove(event.id);
        _going.add(event.id);
      });
      ref.read(publicEventsProvider.notifier).markGoing(event.id);
      _snack(_l10n.exploreRsvpSuccess);
    } on MembersOnlyRsvpException catch (gate) {
      if (!mounted) return;
      setState(() => _rsvping.remove(event.id));
      await _showMembersOnlyGate(event, gate);
    } catch (e) {
      if (!mounted) return;
      setState(() => _rsvping.remove(event.id));
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showMembersOnlyGate(
    PublicEvent event,
    MembersOnlyRsvpException gate,
  ) async {
    final communityId = gate.communityId ?? event.community?.id;
    final communityName = gate.communityName ?? event.community?.name;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MembersOnlyGateSheet(
        communityName: communityName,
        canDeepLink: communityId != null,
        onViewCommunity: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.surface
          : KolabingColors.background,
      appBar: AppBar(title: Text(_l10n.exploreTitle)),
      body: RefreshIndicator(
        color: KolabingColors.primary,
        onRefresh: () => ref.read(publicEventsProvider.notifier).refresh(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(PublicEventsState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: KolabingColors.primary),
      );
    }
    if (state.error != null && state.events.isEmpty) {
      return _errorState(state.error!);
    }
    if (state.isEmpty) {
      return _emptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: state.events.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= state.events.length) {
          return Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator(
                      color: KolabingColors.primary,
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          ref.read(publicEventsProvider.notifier).loadMore(),
                      icon: const Icon(LucideIcons.chevronDown, size: 16),
                      label: Text(_l10n.exploreLoadMore),
                    ),
            ),
          );
        }
        final event = state.events[index];
        return PublicEventCard(
          event: event,
          isRsvping: _rsvping.contains(event.id),
          isGoing: _going.contains(event.id),
          onTap: () =>
              context.push(KolabingRoutes.buildEventDetailPath(event.id)),
          onRsvp: () => _rsvp(event),
        );
      },
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 96),
        Icon(
          LucideIcons.calendarSearch,
          size: 56,
          color: KolabingColors.textTertiary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          _l10n.exploreEmpty,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: KolabingColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xl),
          child: Text(
            _l10n.exploreEmptyHint,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String error) {
    return ListView(
      children: [
        const SizedBox(height: 96),
        Icon(
          LucideIcons.alertCircle,
          size: 48,
          color: KolabingColors.error.withValues(alpha: 0.7),
        ),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          _l10n.exploreLoadFailed,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xl),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: () => ref.read(publicEventsProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(AppLocalizations.of(context).commonRetry),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet shown when an attendee hits a members-only event they can't
/// RSVP to. Offers the "Join community to RSVP" deep-link path.
class _MembersOnlyGateSheet extends StatelessWidget {
  const _MembersOnlyGateSheet({
    required this.communityName,
    required this.canDeepLink,
    required this.onViewCommunity,
  });

  final String? communityName;
  final bool canDeepLink;
  final VoidCallback onViewCommunity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            const Icon(
              LucideIcons.lock,
              size: 32,
              color: KolabingColors.primary,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.exploreMembersOnlyTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              communityName != null
                  ? l10n.exploreMembersOnlyBody(communityName!)
                  : l10n.exploreMembersOnlyBodyGeneric,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            FilledButton.icon(
              onPressed: canDeepLink ? onViewCommunity : null,
              style: FilledButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
              ),
              icon: const Icon(LucideIcons.users, size: 18),
              label: Text(l10n.exploreJoinToRsvp),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}
