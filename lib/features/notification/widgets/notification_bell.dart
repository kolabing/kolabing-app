import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../providers/notification_provider.dart';

/// Notification bell icon with unread count badge.
///
/// Place this in an AppBar's actions or as a standalone widget.
/// Tapping navigates to the notifications screen.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({
    super.key,
    this.color,
    this.size = 24,
  });

  /// Icon color override
  final Color? color;

  /// Icon size
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            LucideIcons.bell,
            color: color ?? KolabingColors.textPrimary,
            size: size,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: KolabingColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: KolabingColors.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.push(KolabingRoutes.notifications),
      tooltip: 'Notifications',
    );
  }
}
