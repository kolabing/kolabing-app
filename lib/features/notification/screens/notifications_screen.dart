import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_navigation.dart';

/// Notifications listing screen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationProvider.notifier).loadNotifications(),
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context).notificationsScreenTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text(
                AppLocalizations.of(context).notificationsScreenMarkAllRead,
                style: KolabingTextStyles.labelMedium.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return _buildErrorState(context, state.error!);
    }

    if (state.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        itemCount:
            state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          color: context.colors.darkBorder,
        ),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(KolabingSpacing.md),
                child:
                    CircularProgressIndicator(color: context.colors.primary),
              ),
            );
          }

          final notification = state.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    final route = resolveNotificationRoute(
      type: notification.rawType,
      id: notification.targetId,
      deeplink: notification.deeplink,
    );

    if (route != KolabingRoutes.notifications) {
      context.push(route);
    }
  }

  Widget _buildLoadingState() => Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      );

  Widget _buildErrorState(BuildContext context, String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: context.colors.textTertiary,
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                error,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).refresh(),
                child: Text(AppLocalizations.of(context).commonRetry),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bellOff,
                size: 48,
                color: context.colors.textTertiary,
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                AppLocalizations.of(context).notificationsScreenEmptyTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).notificationsScreenEmptyBody,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Notification Tile
// =============================================================================

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? context.colors.surface
          : context.colors.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Avatar
              _buildLeading(),
              const SizedBox(width: KolabingSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.actorName ?? notification.title,
                            style: KolabingTextStyles.titleSmall.copyWith(
                              color: context.colors.onSurface,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: KolabingSpacing.xs),
                        Text(
                          notification.timeAgo,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Body
                    Text(
                      notification.body,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: notification.isRead
                            ? context.colors.textTertiary
                            : context.colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (!notification.isRead) ...[
                const SizedBox(width: KolabingSpacing.xs),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    // Show avatar if available
    if (notification.actorAvatarUrl != null &&
        notification.actorAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: context.colors.surfaceVariant,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: notification.actorAvatarUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _buildIconAvatar(),
          ),
        ),
      );
    }

    return _buildIconAvatar();
  }

  Widget _buildIconAvatar() {
    final (IconData icon, Color bgColor, Color iconColor) =
        switch (notification.type) {
      NotificationType.newMessage => (
          LucideIcons.messageCircle,
          context.colors.info.withValues(alpha: 0.12),
          context.colors.info,
        ),
      NotificationType.applicationReceived => (
          LucideIcons.inbox,
          context.colors.primary.withValues(alpha: 0.15),
          context.colors.accentOrangeText,
        ),
      NotificationType.applicationAccepted => (
          LucideIcons.checkCircle,
          context.colors.success.withValues(alpha: 0.15),
          const Color(0xFF155724),
        ),
      NotificationType.applicationDeclined => (
          LucideIcons.xCircle,
          context.colors.error.withValues(alpha: 0.12),
          context.colors.error,
        ),
      NotificationType.badgeAwarded => (
          LucideIcons.badgeCheck,
          context.colors.primary.withValues(alpha: 0.12),
          context.colors.primary,
        ),
      NotificationType.challengeVerified => (
          LucideIcons.shieldCheck,
          context.colors.info.withValues(alpha: 0.12),
          context.colors.info,
        ),
      NotificationType.rewardWon => (
          LucideIcons.gift,
          context.colors.success.withValues(alpha: 0.15),
          const Color(0xFF155724),
        ),
      NotificationType.collabDayReminder ||
      NotificationType.collabFollowUpReminder => (
          LucideIcons.calendarCheck,
          context.colors.primary.withValues(alpha: 0.15),
          context.colors.accentOrangeText,
        ),
      NotificationType.unknown => (
          LucideIcons.bell,
          context.colors.surfaceVariant,
          context.colors.onSurfaceVariant,
        ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: KolabingRadius.borderRadiusMd,
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}
