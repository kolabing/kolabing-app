import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolab_status_badge.dart';
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
      color: KolabingColors.primary,
      onRefresh: () => ref.refresh(collaborationsListProvider.future),
      child: async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(KolabingSpacing.xl),
            child: CircularProgressIndicator(
              color: KolabingColors.primary,
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

class _CollaborationCard extends StatelessWidget {
  const _CollaborationCard({required this.collaboration, required this.isDark});

  final Collaboration collaboration;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final partner = collaboration.businessPartner.name.isNotEmpty
        ? '${collaboration.businessPartner.name} × ${collaboration.communityPartner.name}'
        : collaboration.communityPartner.name;

    final imageUrl = collaboration.opportunity?.offerPhoto;
    final initials = partner.isNotEmpty ? partner[0].toUpperCase() : 'K';

    return Material(
      color: Colors.transparent,
      borderRadius: KolabingRadius.borderRadiusLg,
      child: InkWell(
        borderRadius: KolabingRadius.borderRadiusLg,
        onTap: () => context.push('/collaboration/${collaboration.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? KolabingColors.darkSurface : Colors.white,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: isDark
                ? null
                : Border.all(color: KolabingColors.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KolabStatusBadge(status: collaboration.status.toApiValue()),
                    const SizedBox(height: 6),
                    Text(
                      partner,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark
                            ? KolabingColors.textOnDark
                            : KolabingColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: KolabingColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          collaboration.formattedDate,
                          style: KolabingTextStyles.captionSecondary.copyWith(
                            color: KolabingColors.onSurfaceVariant,
                          ),
                        ),
                        if (collaboration.scheduledTime != null &&
                            collaboration.scheduledTime!.isNotEmpty) ...[
                          const SizedBox(width: KolabingSpacing.sm),
                          const Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: KolabingColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              collaboration.scheduledTime!,
                              style: KolabingTextStyles.captionSecondary.copyWith(
                                color: KolabingColors.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: KolabingColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              _buildSquareImage(imageUrl, initials),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareImage(String? imageUrl, String initials) {
    const size = 68.0;
    const radius = 14.0;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size, radius, initials),
        ),
      );
    }
    return _placeholder(size, radius, initials);
  }

  Widget _placeholder(double size, double radius, String initials) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C4A12),
      ),
    ),
  );
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? KolabingColors.darkSurface
                : KolabingColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Icon(icon, size: 36, color: KolabingColors.textTertiary),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          title,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? KolabingColors.textOnDark
                : KolabingColors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          message,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
