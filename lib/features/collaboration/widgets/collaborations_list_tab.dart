import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../../widgets/verified_tick.dart';
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
    super.key,
  });

  /// Which derived bucket to show.
  final CollaborationBucket bucket;
  final String emptyTitle;
  final String emptyMessage;

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
            title: 'Something went wrong',
            message: '$e',
            isDark: isDark,
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
    final partner = collaboration.businessPartner.name.isNotEmpty
        ? '${collaboration.businessPartner.name} × ${collaboration.communityPartner.name}'
        : collaboration.communityPartner.name;

    // Show the counterpart (the party you are kolabing with) first: business
    // viewers see the community partner, community viewers see the business
    // partner. Fall back to the kolab's own posted photo.
    final viewer = ref.watch(authProvider).user;
    final counterpart = viewer?.isBusiness ?? false
        ? collaboration.communityPartner
        : collaboration.businessPartner;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  partner,
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: context.colors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (collaboration.communityPartner.isVerified) ...[
                const SizedBox(width: KolabingSpacing.xs),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: VerifiedTick(isVerified: true),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: context.colors.textTertiary),
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
                Icon(LucideIcons.clock, size: 12, color: context.colors.textTertiary),
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
              Icon(LucideIcons.chevronRight, size: 16, color: context.colors.textTertiary),
            ],
          ),
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
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand empty-state treatment: yellow glyph in a soft-yellow circle.
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Icon(icon, size: 36, color: context.colors.primary),
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
      ],
    ),
  );
}
