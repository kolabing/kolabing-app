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
import '../models/challenge_completion.dart';
import '../providers/pending_challenge_provider.dart';
import 'attendee_scanner_screen.dart';
import 'challenge_together_screen.dart';

/// Attendee (Community Member) main screen with bottom navigation
///
/// This is the main container for attendee users after login.
/// 3 tabs: Home, Communities (NF-6), Chats. The QR scanner left the bottom nav;
/// the attendee's own profile-QR opens from the app-bar QR action so others can
/// scan to check them in / connect. Profile moved off the nav (NF-12) — reached
/// via the app-bar avatar.
class AttendeeMainScreen extends ConsumerStatefulWidget {
  const AttendeeMainScreen({super.key, this.initialTab = 0});

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

  /// Open the QR hub: everything QR in one place, so a member never has to
  /// work out whether this moment calls for scanning or for being scanned.
  ///
  /// Scanning is the primary action — check-in, pairing up and confirming a
  /// challenge all go through it.
  Future<void> _openQrHub() async {
    final action = await showModalBottomSheet<_QrHubAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QrHubSheet(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _QrHubAction.scan:
        await AttendeeScannerScreen.open(context);
      case _QrHubAction.myQr:
        await _openMyQr();
    }
  }

  /// Show the attendee's OWN profile QR so someone can scan them to pair up
  /// for a challenge (or a host can check them in).
  Future<void> _openMyQr() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      // Scroll-controlled so the sheet sizes to its content. A default sheet is
      // capped near half the screen, which the QR plus two lines of copy
      // overflows — and would again at a larger text scale.
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _MyProfileQrSheet(),
    );
  }

  /// Guards against opening the shared screen twice for the same challenge if
  /// the provider emits again while it is already on screen.
  String? _showingCompletionId;

  /// Someone just asked this device to do a challenge together — open the same
  /// screen they are looking at (#140). This is what removed the second QR
  /// scan: the partner's phone finds out by itself.
  void _openPendingChallenge(ChallengeCompletion completion) async {
    if (!mounted || _showingCompletionId == completion.id) return;
    _showingCompletionId = completion.id;

    await ChallengeTogetherScreen.openForPartner(context, completion);

    if (mounted) _showingCompletionId = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final chatUnread = ref.watch(chatUnreadProvider);

    ref.listen(pendingChallengeProvider, (previous, next) {
      if (next != null) _openPendingChallenge(next);
    });

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
      backgroundColor: isDark
          ? context.colors.surface
          : context.colors.background,
      appBar: KolabingAppBar(
        // QR action shows the attendee's OWN profile QR (#4); the avatar still
        // opens the profile.
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode),
            color: context.colors.charcoal,
            tooltip: l10n.qrHubTitle,
            onPressed: _openQrHub,
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

/// What the member chose in the QR hub.
enum _QrHubAction { scan, myQr }

/// The QR hub: scan a code, or show yours.
///
/// Two options, each with a line saying what it is for. The loop needs both
/// sides — someone scans, someone is scanned — and members swap roles
/// constantly, so neither is buried behind the other.
class _QrHubSheet extends StatelessWidget {
  const _QrHubSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.lg,
                vertical: KolabingSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.qrHubTitle,
                    style: KolabingTextStyles.labelMedium.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _QrHubTile(
              icon: LucideIcons.scan,
              title: l10n.qrHubScanTitle,
              subtitle: l10n.qrHubScanSubtitle,
              onTap: () => Navigator.of(context).pop(_QrHubAction.scan),
            ),
            _QrHubTile(
              icon: LucideIcons.qrCode,
              title: l10n.qrHubMyQrTitle,
              subtitle: l10n.qrHubMyQrSubtitle,
              onTap: () => Navigator.of(context).pop(_QrHubAction.myQr),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrHubTile extends StatelessWidget {
  const _QrHubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colors.charcoal, size: 22),
      ),
      title: Text(
        title,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: context.colors.onSurfaceVariant,
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
    final payload = (user?.id.isNotEmpty ?? false)
        ? user!.id
        : (user?.handle ?? '');
    final qrData = payload.isNotEmpty
        ? 'https://${Environment.shareHost}/u/$payload'
        : '';

    return SafeArea(
      // Scrolls rather than overflows: the QR has a fixed size, so anything
      // that grows around it — translated copy wrapping to another line, a
      // long display name, a large accessibility text scale — has to give
      // somewhere.
      child: SingleChildScrollView(
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
            if (user?.displayName != null && user!.displayName.isNotEmpty) ...[
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
