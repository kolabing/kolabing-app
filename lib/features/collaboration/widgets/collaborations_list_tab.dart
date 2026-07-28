import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/collaboration.dart';
import '../providers/collaborations_list_provider.dart';

/// Renders one bucket of collaborations (Active or Finished) inside the
/// My Kolabs hub. Pure presentation over [activeCollaborationsProvider] /
/// [finishedCollaborationsProvider]; pull-to-refresh re-fetches the shared
/// [collaborationsListProvider].
class CollaborationsListTab extends ConsumerWidget {
  const CollaborationsListTab({
    required this.bucket,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onEmptyExplore,
    super.key,
  });

  /// Which derived bucket to show.
  final CollaborationBucket bucket;
  final String emptyTitle;
  final String emptyMessage;

  /// When set, the empty state offers a "Find a Kolab" CTA that jumps to the
  /// Explore tab — so an empty Active tab is a starting point, not a dead end.
  final VoidCallback? onEmptyExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = bucket == CollaborationBucket.active
        ? ref.watch(activeCollaborationsProvider)
        : ref.watch(finishedCollaborationsProvider);

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.refresh(collaborationsListProvider.future),
      child: async.when(
        loading: () => Center(
          child: Padding(
            padding: EdgeInsets.all(KolabingSpacing.xl),
            child: CircularProgressIndicator(
              color: context.colors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (e, _) => _ScrollableCenter(
          child: _Message(
            icon: LucideIcons.alertCircle,
            title: AppLocalizations.of(context).commonErrorGeneric,
            message: '$e',
            isDark: isDark,
            onRetry: () => ref.refresh(collaborationsListProvider.future),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _ScrollableCenter(
              child: _Message(
                icon: bucket == CollaborationBucket.active
                    ? LucideIcons.calendarClock
                    : LucideIcons.checkCircle2,
                title: emptyTitle,
                message: emptyMessage,
                isDark: isDark,
                action: onEmptyExplore == null
                    ? null
                    : KolabingButton(
                        label: AppLocalizations.of(context).dashboardFindAKolab,
                        onPressed: onEmptyExplore!,
                        variant: KolabingButtonVariant.secondary,
                        size: KolabingButtonSize.compact,
                        icon: const Icon(LucideIcons.search),
                      ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.md,
              KolabingSpacing.md,
              KolabingSpacing.md,
              KolabingSpacing.xxl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: KolabingSpacing.sm),
            itemBuilder: (context, index) =>
                _CollaborationCard(collaboration: items[index], isDark: isDark),
          );
        },
      ),
    );
  }
}

/// Which derived bucket a [CollaborationsListTab] renders.
enum CollaborationBucket { active, finished }

class _CollaborationCard extends ConsumerWidget {
  const _CollaborationCard({required this.collaboration, required this.isDark});

  final Collaboration collaboration;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show the counterpart (the party you are kolabing with), not your own
    // name: business viewers see the community partner, community viewers
    // see the business partner. Previously this always led with the business
    // name, so a long business name would push the actual partner off the
    // card entirely (maxLines: 2 truncated before "× partner" ever showed).
    final viewer = ref.watch(authProvider).user;
    final counterpart = viewer?.isBusiness ?? false
        ? collaboration.communityPartner
        : collaboration.businessPartner;
    final partner = counterpart.name.isNotEmpty
        ? counterpart.name
        : (collaboration.businessPartner.name.isNotEmpty
              ? collaboration.businessPartner.name
              : collaboration.communityPartner.name);
    final counterpartPhoto = counterpart.profilePhoto;
    final imageUrl = (counterpartPhoto != null && counterpartPhoto.isNotEmpty)
        ? counterpartPhoto
        : collaboration.opportunity?.offerPhoto;
    final initials = partner.isNotEmpty ? partner[0].toUpperCase() : 'K';

    return KolabCardShell(
      imageUrl: imageUrl,
      initials: initials,
      onTap: () => context.push('/collaboration/${collaboration.id}'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KolabStatusBadge(status: collaboration.status.toApiValue()),
          const SizedBox(height: 6),
          Text(
            partner,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: context.colors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 12,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                collaboration.formattedDate,
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (collaboration.scheduledTime != null &&
                  collaboration.scheduledTime!.isNotEmpty) ...[
                const SizedBox(width: KolabingSpacing.sm),
                Icon(
                  LucideIcons.clock,
                  size: 12,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    collaboration.scheduledTime!,
                    style: KolabingTextStyles.captionSecondary.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.colors.textTertiary,
              ),
            ],
          ),
          // Two-sided feedback gate: once the viewer confirmed but the Kolab is
          // not yet completed, surface a subtle line so the Active card doesn't
          // look like nothing happened after submitting feedback.
          if (collaboration.ownFeedbackSubmitted &&
              collaboration.status != CollaborationStatus.completed &&
              collaboration.status != CollaborationStatus.cancelled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  size: 12,
                  color: context.colors.success,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).collaborationCardWaitingForPartner,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  // Wraps content so pull-to-refresh works even when the bucket is empty.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.isDark,
    this.onRetry,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isDark;

  /// Optional retry handler — renders a Retry button under the message.
  final VoidCallback? onRetry;

  /// Optional custom action widget (e.g. an empty-state CTA). Rendered after
  /// [onRetry] when both are present.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.darkSurface
                : context.colors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Icon(icon, size: 36, color: context.colors.textTertiary),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          title,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? context.colors.textOnDark
                : context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          message,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: AppLocalizations.of(context).commonRetry,
            onPressed: onRetry!,
            variant: KolabingButtonVariant.primary,
            size: KolabingButtonSize.compact,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: KolabingSpacing.lg),
          action!,
        ],
      ],
    ),
  );
}
