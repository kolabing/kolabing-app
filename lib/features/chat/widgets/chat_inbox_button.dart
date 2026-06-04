import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../providers/chat_providers.dart';
import '../screens/chats_screen.dart';

/// App-bar inbox icon with an unread badge. Opens the [ChatsScreen]. Lives in
/// the standard app bar so chat is one tap away from any main tab (NF-CHAT).
class ChatInboxButton extends ConsumerWidget {
  const ChatInboxButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadProvider);
    final iconColor = color ?? KolabingColors.charcoal;
    return IconButton(
      tooltip: 'Chats',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ChatsScreen()),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.messageCircle, color: iconColor),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: KolabingColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
