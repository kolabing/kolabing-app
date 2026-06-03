import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/kolabing_app_bar.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/ui_icon.dart';
import '../../community/screens/my_communities_screen.dart';
import 'attendee_home_screen.dart';
import 'attendee_profile_screen.dart';
import 'qr_scanner_screen.dart';

/// Attendee (Community Member) main screen with bottom navigation
///
/// This is the main container for attendee users after login.
/// Contains 4 tabs: Home, Communities (NF-6), Scan QR (modal), Profile
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
    // Index 2 is the QR Scanner - open as a modal, don't change the tab.
    if (index == 2) {
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

    final navItems = [
      const NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: 'Home',
        iconSlug: UiIconSlug.home,
      ),
      const NavItem(
        icon: LucideIcons.users,
        activeIcon: LucideIcons.users,
        label: 'Communities',
      ),
      const NavItem(
        icon: LucideIcons.qrCode,
        activeIcon: LucideIcons.qrCode,
        label: 'Scan',
      ),
      const NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profile',
        iconSlug: UiIconSlug.user,
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.surface : KolabingColors.background,
      appBar: const KolabingAppBar(),
      body: IndexedStack(
        // Nav indices: Home 0, Communities 1, Scan 2 (modal, no child),
        // Profile 3. Collapse the modal slot so children stay 0,1,2.
        index: _currentIndex < 2 ? _currentIndex : _currentIndex - 1,
        children: const [
          AttendeeHomeScreen(),
          MyCommunitiesScreen(),
          AttendeeProfileScreen(),
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
