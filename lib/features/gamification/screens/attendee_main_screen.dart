import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/ui_icon.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chats_screen.dart';
import '../../community/screens/my_communities_screen.dart';
import 'attendee_home_screen.dart';
import 'qr_scanner_screen.dart';

/// Attendee (Community Member) main screen with bottom navigation
///
/// This is the main container for attendee users after login.
/// 4 tabs: Home, Communities (NF-6), Chats, Scan QR (modal). Profile moved off
/// the nav (NF-12) — reached via the app-bar avatar.
class AttendeeMainScreen extends ConsumerStatefulWidget {
  const AttendeeMainScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<AttendeeMainScreen> createState() => _AttendeeMainScreenState();
}

class _AttendeeMainScreenState extends ConsumerState<AttendeeMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabChanged(int index) {
    // Index 3 is the QR Scanner — open as a modal, don't change the tab.
    if (index == 3) {
      _openQRScanner();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openQRScanner() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QRScannerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final chatUnread = ref.watch(chatUnreadProvider);

    final navItems = [
      NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: l10n.attendeeNavHome,
        iconSlug: UiIconSlug.home,
      ),
      NavItem(
        // Flag (chapter/club banner) — distinct from the lone-person Profile
        // icon, which looked near-identical when this used users vs user.
        icon: LucideIcons.flag,
        activeIcon: LucideIcons.flag,
        label: l10n.attendeeNavCommunities,
      ),
      NavItem(
        // Chats promoted to the nav (NF-12); unread badge moves here from the
        // old app-bar inbox button. TODO(i18n): localize when chat is localized.
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: 'Chats',
        badgeCount: chatUnread > 0 ? chatUnread : null,
      ),
      NavItem(
        icon: LucideIcons.qrCode,
        activeIcon: LucideIcons.qrCode,
        label: l10n.attendeeNavScan,
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? context.colors.surface : context.colors.background,
      body: IndexedStack(
        // Nav indices: Home 0, Communities 1, Chats 2, Scan 3 (modal, no child).
        // Scan returns early in _onTabChanged, so _currentIndex is only 0..2.
        index: _currentIndex,
        children: const [
          AttendeeHomeScreen(),
          MyCommunitiesScreen(),
          ChatsScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: KolabingBottomNavBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
