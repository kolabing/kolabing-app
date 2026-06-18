import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/environment.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/navigation/kolabing_app_bar.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/navigation/profile_avatar_button.dart';
import '../../../widgets/ui_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chats_screen.dart';
import '../../community/screens/my_communities_screen.dart';
import 'attendee_home_screen.dart';

/// Attendee (Community Member) main screen with bottom navigation
///
/// This is the main container for attendee users after login.
/// 3 tabs: Home, Communities (NF-6), Chats. The QR scanner left the bottom nav;
/// the attendee's own profile-QR opens from the app-bar QR action so others can
/// scan to check them in / connect. Profile moved off the nav (NF-12) — reached
/// via the app-bar avatar.
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
    setState(() {
      _currentIndex = index;
    });
  }

  /// Show the attendee's OWN profile QR (#4) so a host can scan to check them in
  /// or connect. Encodes the user's profile id (handle fallback).
  Future<void> _openMyQr() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _MyProfileQrSheet(),
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
    ];

    return Scaffold(
      backgroundColor:
          isDark ? context.colors.surface : context.colors.background,
      appBar: KolabingAppBar(
        // QR action shows the attendee's OWN profile QR (#4); the avatar still
        // opens the profile.
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode),
            color: context.colors.charcoal,
            tooltip: l10n.attendeeMyQrTooltip,
            onPressed: _openMyQr,
          ),
          const ProfileAvatarButton(),
        ],
      ),
      body: IndexedStack(
        // Nav indices: Home 0, Communities 1, Chats 2.
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

/// Bottom sheet showing the attendee's OWN profile QR (#4). Encodes a stable
/// profile reference (id, handle fallback) so a host can scan to check them in
/// or connect.
class _MyProfileQrSheet extends ConsumerWidget {
  const _MyProfileQrSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;

    // Prefer the universal profile id; fall back to the handle. Empty → no QR.
    final payload =
        (user?.id.isNotEmpty ?? false) ? user!.id : (user?.handle ?? '');
    final qrData = payload.isNotEmpty
        ? 'https://${Environment.shareHost}/u/$payload'
        : '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              l10n.attendeeMyQrTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.attendeeMyQrSubtitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            if (qrData.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.xl,
                ),
                child: Text(
                  l10n.attendeeMyQrUnavailable,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.error,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  size: 220,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            if (user?.displayName != null &&
                user!.displayName.isNotEmpty) ...[
              const SizedBox(height: KolabingSpacing.md),
              Text(
                user.displayName,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurface,
                ),
              ),
            ],
            const SizedBox(height: KolabingSpacing.md),
          ],
        ),
      ),
    );
  }
}
