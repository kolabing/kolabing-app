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
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

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
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textPrimary,
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
                'Mark all read',
                style: KolabingTextStyles.labelMedium.copyWith(
                  color: KolabingColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: KolabingColors.primary,
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        itemCount:
            state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 72,
          color: KolabingColors.border,
        ),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(KolabingSpacing.md),
                child:
                    CircularProgressIndicator(color: KolabingColors.primary),
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

    // Navigate based on target type and notification type
    if (notification.targetId != null &&
        notification.targetType == 'application') {
      if (notification.type == NotificationType.newMessage) {
        // Navigate to chat screen
        context.push(
          KolabingRoutes.applicationChat
              .replaceFirst(':id', notification.targetId!),
        );
      } else {
        // Navigate to application detail screen
        context.push(
          KolabingRoutes.applicationDetails
              .replaceFirst(':id', notification.targetId!),
        );
      }
    }
  }

  Widget _buildLoadingState() => const Center(
        child: CircularProgressIndicator(color: KolabingColors.primary),
      );

  Widget _buildErrorState(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                error,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bellOff,
                size: 48,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                'No notifications yet',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'When you receive messages or application updates, they\'ll show up here.',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textTertiary,
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
          ? KolabingColors.surface
          : KolabingColors.primary.withValues(alpha: 0.06),
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
                              color: KolabingColors.textPrimary,
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
                            color: KolabingColors.textTertiary,
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
                            ? KolabingColors.textTertiary
                            : KolabingColors.textSecondary,
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
                  decoration: const BoxDecoration(
                    color: KolabingColors.primary,
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
        backgroundColor: KolabingColors.surfaceVariant,
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
          KolabingColors.info.withValues(alpha: 0.12),
          KolabingColors.info,
        ),
      NotificationType.applicationReceived => (
          LucideIcons.inbox,
          KolabingColors.primary.withValues(alpha: 0.15),
          KolabingColors.accentOrangeText,
        ),
      NotificationType.applicationAccepted => (
          LucideIcons.checkCircle,
          KolabingColors.success.withValues(alpha: 0.15),
          const Color(0xFF155724),
        ),
      NotificationType.applicationDeclined => (
          LucideIcons.xCircle,
          KolabingColors.error.withValues(alpha: 0.12),
          KolabingColors.error,
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
