import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/navigation/kolabing_app_bar.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/ui_icon.dart';
import 'attendee_home_screen.dart';
import 'attendee_profile_screen.dart';
import 'qr_scanner_screen.dart';

/// Attendee user main screen with bottom navigation
///
/// This is the main container for attendee users after login.
/// Contains 3 tabs: Home, Scan QR, Profile
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
    // Index 1 is QR Scanner - open as modal
    if (index == 1) {
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

    final navItems = [
      NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: l10n.attendeeNavHome,
        iconSlug: UiIconSlug.home,
      ),
      NavItem(
        icon: LucideIcons.qrCode,
        activeIcon: LucideIcons.qrCode,
        label: l10n.attendeeNavScan,
      ),
      NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: l10n.attendeeNavProfile,
        iconSlug: UiIconSlug.user,
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.surface : KolabingColors.background,
      appBar: const KolabingAppBar(),
      body: IndexedStack(
        index: _currentIndex > 1 ? _currentIndex - 1 : _currentIndex,
        children: const [
          AttendeeHomeScreen(),
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
