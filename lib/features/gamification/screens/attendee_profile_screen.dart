import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/services/profile_service.dart';
import '../../chat/providers/chat_providers.dart';
import '../../community/models/community_membership.dart';
import '../../community/providers/community_providers.dart';
import '../../friends/models/friendship.dart';
import '../../friends/providers/friends_provider.dart';
import '../../identity/widgets/handle_field.dart';

/// Attendee profile — a Flaire-style social hub.
///
/// Layout: a brand-gradient cover band; a large circular avatar overlapping its
/// bottom edge, flanked by four stats (Friends / Events | Chats / Points);
/// name + city centred below; then the user's communities (horizontal cards),
/// a friends preview row, and a compact settings list.
class AttendeeProfileScreen extends ConsumerStatefulWidget {
  const AttendeeProfileScreen({super.key});

  @override
  ConsumerState<AttendeeProfileScreen> createState() =>
      _AttendeeProfileScreenState();
}

class _AttendeeProfileScreenState extends ConsumerState<AttendeeProfileScreen> {
  static const double _coverHeight = 132;
  static const double _avatarSize = 96;

  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _uploadingPhoto = false;

  // ---- Inline name + @handle editing ----------------------------------------
  bool _editingIdentity = false;
  bool _savingIdentity = false;
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  String? _initialHandle;
  String _handle = '';
  bool _handleOk = true;

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final l10n = AppLocalizations.of(context);
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      await _profileService.updateProfilePhotoFile(filePath: picked.path);
      await ref.read(authProvider.notifier).checkAuthStatus();
    } on ApiException catch (e) {
      _showError(e.error.message);
    } on Exception {
      _showError(l10n.editProfileSaveError);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _startEditingIdentity() {
    final user = ref.read(authProvider).user;
    _nameController.text = user?.displayName ?? '';
    _initialHandle = user?.handle?.toLowerCase();
    _handle = _initialHandle ?? '';
    _handleOk = true;
    _handleController.text = _initialHandle ?? '';
    setState(() => _editingIdentity = true);
  }

  void _cancelEditingIdentity() {
    setState(() => _editingIdentity = false);
  }

  Future<void> _saveIdentity() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError(l10n.editProfileNameRequired);
      return;
    }
    if (_handle.isNotEmpty && !_handleOk) {
      _showError(l10n.handleFieldFormatError);
      return;
    }

    setState(() => _savingIdentity = true);
    try {
      final handleChanged =
          _handle.isNotEmpty && _handle != (_initialHandle ?? '');
      await _profileService.updateProfile({
        'name': name,
        if (handleChanged) 'handle': _handle,
      });
      await ref.read(authProvider.notifier).checkAuthStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editProfileSaved),
          backgroundColor: KolabingColors.success,
        ),
      );
      setState(() => _editingIdentity = false);
    } on ApiException catch (e) {
      _showError(e.error.message);
    } on NetworkException catch (e) {
      _showError(e.message);
    } on Exception {
      _showError(l10n.editProfileSaveError);
    } finally {
      if (mounted) setState(() => _savingIdentity = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: KolabingColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final attendeeProfile = user?.attendeeProfile;
    final l10n = AppLocalizations.of(context);

    // Stat sources.
    final friendsCount =
        ref.watch(friendsProvider).maybeWhen(data: (f) => f.length, orElse: () => 0);
    final chatsCount = ref.watch(chatThreadsProvider).value?.length ?? 0;
    final eventsCount = attendeeProfile?.totalEventsAttended ?? 0;
    final pointsCount = attendeeProfile?.totalPoints ?? 0;

    final cityName = user?.communityProfile?.city?.name ??
        user?.businessProfile?.city?.name ??
        user?.cityName;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Cover + flanking stats + avatar -----------------------------
            SizedBox(
              height: _coverHeight + _avatarSize / 2 + 8,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Brand gradient cover band.
                  Container(
                    height: _coverHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          KolabingColors.primary,
                          KolabingColors.surfaceVariant,
                        ],
                      ),
                    ),
                  ),

                  // Stats row flanking the avatar, sitting near the cover bottom.
                  Positioned(
                    left: KolabingSpacing.md,
                    right: KolabingSpacing.md,
                    top: _coverHeight - 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _FlankStat(
                                value: friendsCount,
                                label: l10n.attendeeProfileStatFriends,
                                onTap: () => context.push(KolabingRoutes.friends),
                              ),
                              _FlankStat(
                                value: eventsCount,
                                label: l10n.attendeeProfileStatEvents,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _avatarSize),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _FlankStat(
                                value: chatsCount,
                                label: l10n.attendeeProfileStatChats,
                              ),
                              _FlankStat(
                                value: pointsCount,
                                label: l10n.attendeeProfileStatPoints,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Centred circular avatar overlapping the cover bottom edge.
                  // Tap → change photo (NF-18).
                  Positioned(
                    top: _coverHeight - _avatarSize / 2,
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _changePhoto,
                      child: Stack(
                        children: [
                          _ProfileAvatar(
                            size: _avatarSize,
                            photoUrl: user?.profilePhotoUrl,
                            initial: _getInitials(user?.displayName ?? 'A'),
                          ),
                          if (_uploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: KolabingColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(KolabingSpacing.xxs),
                              decoration: BoxDecoration(
                                color: KolabingColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: KolabingColors.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                size: 14,
                                color: KolabingColors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: KolabingSpacing.sm),

            // ---- Name + @handle (inline editable, NF-18) ---------------------
            if (_editingIdentity)
              _buildIdentityEditor(l10n)
            else
              _buildIdentityDisplay(user?.displayName, user?.handle, cityName,
                  l10n),

            const SizedBox(height: KolabingSpacing.lg),

            // ---- My communities ---------------------------------------------
            const _MyCommunitiesSection(),

            const SizedBox(height: KolabingSpacing.lg),

            // ---- Friends preview --------------------------------------------
            const _FriendsPreviewSection(),

            const SizedBox(height: KolabingSpacing.md),

            // ---- Settings list ----------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
              child: Column(
                children: [
                  const Divider(height: 1, color: KolabingColors.outlineVariant),
                  _SettingsRow(
                    icon: LucideIcons.bell,
                    label: l10n.notifSettingsTitle,
                    onTap: () => context.push(KolabingRoutes.notificationSettings),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.globe,
                    label: l10n.settingsLanguage,
                    onTap: () => context.push(KolabingRoutes.language),
                  ),
                  const Divider(height: 1, color: KolabingColors.outlineVariant),
                  const SizedBox(height: KolabingSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context, ref),
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: Text(l10n.attendeeProfileSignOut),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KolabingColors.error,
                        side: const BorderSide(color: KolabingColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KolabingRadius.md),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: KolabingSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// Read-only name + @handle + city, with a tap target to begin editing.
  Widget _buildIdentityDisplay(
    String? displayName,
    String? handle,
    String? cityName,
    AppLocalizations l10n,
  ) =>
      GestureDetector(
        onTap: _startEditingIdentity,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName ?? l10n.attendeeRoleLabel,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.xs),
                const Icon(
                  LucideIcons.edit3,
                  size: 16,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ],
            ),
            if (handle != null && handle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '@$handle',
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (cityName != null && cityName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: KolabingColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cityName,
                    style: KolabingTextStyles.bodySmall
                        .copyWith(color: KolabingColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  /// Inline name + @handle editor shown in place of the display block.
  Widget _buildIdentityEditor(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_savingIdentity,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l10n.editProfileNameHint,
                filled: true,
                fillColor: KolabingColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(KolabingRadius.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm + 2,
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            HandleField(
              controller: _handleController,
              initialHandle: _initialHandle,
              enabled: !_savingIdentity,
              onChanged: (handle, ok) {
                _handle = handle;
                if (ok != _handleOk && mounted) {
                  setState(() => _handleOk = ok);
                } else {
                  _handleOk = ok;
                }
              },
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _savingIdentity ? null : _cancelEditingIdentity,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KolabingColors.onSurface,
                      side:
                          const BorderSide(color: KolabingColors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KolabingRadius.md),
                      ),
                    ),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savingIdentity ? null : _saveIdentity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KolabingRadius.md),
                      ),
                    ),
                    child: _savingIdentity
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KolabingColors.onPrimary,
                            ),
                          )
                        : Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.attendeeProfileSignOut),
        content: Text(l10n.attendeeProfileSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: Text(l10n.attendeeProfileSignOut),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go(KolabingRoutes.login);
      }
    }
  }
}

// =============================================================================
// Flanking stat (big number + small label)
// =============================================================================

class _FlankStat extends StatelessWidget {
  const _FlankStat({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

// =============================================================================
// Avatar
// =============================================================================

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.size,
    required this.initial,
    this.photoUrl,
  });

  final double size;
  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: KolabingColors.surface, width: 4);
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _initialCircle(border),
          ),
        ),
      );
    }
    return _initialCircle(border);
  }

  Widget _initialCircle(BoxBorder border) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KolabingColors.primary.withValues(alpha: 0.25),
          border: border,
        ),
        child: Center(
          child: Text(
            initial,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: KolabingColors.onPrimary,
            ),
          ),
        ),
      );
}

// =============================================================================
// My communities
// =============================================================================

class _MyCommunitiesSection extends ConsumerWidget {
  const _MyCommunitiesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(myMembershipsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
          child: Row(
            children: [
              Text(
                l10n.attendeeProfileMyCommunities,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                // Attendees DISCOVER and join communities — open the discovery
                // surface (NOT the leader collab-create flow).
                onTap: () =>
                    context.push(KolabingRoutes.discoverCommunities),
                child: Container(
                  padding: const EdgeInsets.all(KolabingSpacing.xxs),
                  decoration: BoxDecoration(
                    color: KolabingColors.primary,
                    borderRadius: BorderRadius.circular(KolabingRadius.round),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: KolabingColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        async.when(
          loading: () => const SizedBox(
            height: 96,
            child: Center(
              child: CircularProgressIndicator(color: KolabingColors.primary),
            ),
          ),
          error: (_, _) => _MyCommunitiesEmpty(l10n: l10n),
          data: (memberships) {
            if (memberships.isEmpty) return _MyCommunitiesEmpty(l10n: l10n);
            return SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                ),
                itemCount: memberships.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: KolabingSpacing.sm),
                itemBuilder: (_, i) =>
                    _CommunityCard(membership: memberships[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.membership});

  final CommunityMembership membership;

  @override
  Widget build(BuildContext context) {
    final community = membership.community;
    final tier = membership.tier;
    return Container(
      width: 124,
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
            backgroundImage: community.avatarUrl != null
                ? NetworkImage(community.avatarUrl!)
                : null,
            child: community.avatarUrl == null
                ? const Icon(LucideIcons.users, color: KolabingColors.onSurface)
                : null,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            community.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tier?.name ?? AppLocalizations.of(context).myCommunitiesNoTier,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCommunitiesEmpty extends StatelessWidget {
  const _MyCommunitiesEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: KolabingColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(KolabingRadius.lg),
            border: Border.all(color: KolabingColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.users,
                    size: 22,
                    color: KolabingColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.attendeeProfileNoCommunities,
                      style: KolabingTextStyles.bodySmall
                          .copyWith(color: KolabingColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push(KolabingRoutes.discoverCommunities),
                  icon: const Icon(LucideIcons.compass, size: 18),
                  label: Text(l10n.discoverCommunitiesCta),
                ),
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Friends preview
// =============================================================================

class _FriendsPreviewSection extends ConsumerWidget {
  const _FriendsPreviewSection();

  static const int _maxPreview = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final friends = ref.watch(friendsProvider).maybeWhen(
          data: (f) => f,
          orElse: () => const <FriendSummary>[],
        );

    // Always show the Friends widget. When empty, invite the user to find
    // friends instead of hiding the section.
    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.attendeeProfileFriends,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(KolabingRoutes.addFriend),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: Text(l10n.attendeeProfileFindFriends),
              ),
            ),
          ],
        ),
      );
    }

    final preview = friends.take(_maxPreview).toList();
    final remaining = friends.length - preview.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
          child: Row(
            children: [
              Text(
                l10n.attendeeProfileFriends,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(KolabingRoutes.friends),
                child: Text(
                  l10n.attendeeProfileSeeAll,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            children: [
              for (final friend in preview) ...[
                _FriendAvatar(
                  avatarUrl: friend.avatarUrl,
                  initial: friend.initial,
                  onTap: () => context.push('/profile/${friend.profileId}'),
                ),
                const SizedBox(width: KolabingSpacing.sm),
              ],
              if (remaining > 0)
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: KolabingColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+$remaining',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({
    required this.initial,
    required this.onTap,
    this.avatarUrl,
  });

  final String? avatarUrl;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _initialCircle(),
                ),
              )
            : _initialCircle(),
      );

  Widget _initialCircle() => Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: KolabingColors.onSurface,
          ),
        ),
      );
}

// =============================================================================
// Settings row
// =============================================================================

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm + 2),
          child: Row(
            children: [
              Icon(icon, size: 20, color: KolabingColors.onSurfaceVariant),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.onSurface,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: KolabingColors.textTertiary,
              ),
            ],
          ),
        ),
      );
}
