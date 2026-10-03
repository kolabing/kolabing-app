import 'dart:async';

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
import '../../../widgets/kolabing_button.dart';
import '../models/instagram_models.dart';
import '../models/instagram_return_link.dart';
import '../providers/instagram_providers.dart';
import 'instagram_professional_helper_sheet.dart';

/// "Instagram" card on the business and community profile screens, under the
/// gallery.
///
/// States:
/// - hidden  -> loading, error, `null` (endpoint not deployed / wrong role) or
///              `enabled: false` (flag off until Meta approves the app, and
///              the profile is not a tester). No gap is left behind.
/// - not connected -> "Connect Instagram" + personal-account helper link
/// - connected     -> @username, "Import photos and videos", "Disconnect"
///
/// Connect opens the backend's authorize URL in the system browser. The
/// backend's callback sends the browser to `kolabing://instagram/connected`,
/// which arrives here through [InstagramReturnBus]. The status is also
/// re-read whenever the app resumes after a connect attempt, so closing the
/// browser without finishing still leaves the card correct.
class InstagramConnectCard extends ConsumerStatefulWidget {
  const InstagramConnectCard({
    this.bottomSpacing = 0,
    this.onOpenImport,
    super.key,
  });

  /// Space below the card, applied only while it is shown.
  final double bottomSpacing;

  /// Opens the media picker. Defaults to pushing
  /// [KolabingRoutes.instagramImport].
  final VoidCallback? onOpenImport;

  @override
  ConsumerState<InstagramConnectCard> createState() =>
      _InstagramConnectCardState();
}

class _InstagramConnectCardState extends ConsumerState<InstagramConnectCard>
    with WidgetsBindingObserver {
  StreamSubscription<InstagramReturnLink>? _returnSub;
  bool _connecting = false;
  bool _disconnecting = false;

  /// A connect attempt is in flight in the browser.
  bool _awaitingReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _returnSub = ref
        .read(instagramReturnBusProvider)
        .stream
        .listen(_onReturnLink);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_returnSub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn) {
      ref.invalidate(instagramStatusProvider);
    }
  }

  void _onReturnLink(InstagramReturnLink link) {
    if (!mounted) return;
    _awaitingReturn = false;
    ref.invalidate(instagramStatusProvider);

    final l10n = AppLocalizations.of(context);
    _snack(link.ok ? l10n.instagramConnectSuccess : l10n.instagramConnectError);
    if (link.isPersonalAccountError) {
      unawaited(InstagramProfessionalHelperSheet.show(context));
    }
  }

  Future<void> _connect() async {
    if (_connecting) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _connecting = true);
    try {
      final url = await ref.read(instagramServiceProvider).getConnectUrl();
      final opened = await ref.read(instagramUrlLauncherProvider)(url);
      if (!mounted) return;
      if (opened) {
        _awaitingReturn = true;
      } else {
        _snack(l10n.instagramOpenFailed);
      }
    } on Exception catch (e) {
      debugPrint('Instagram connect failed: $e');
      if (mounted) _snack(l10n.instagramOpenFailed);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('instagram-disconnect-dialog'),
        title: Text(l10n.instagramDisconnectTitle),
        content: Text(l10n.instagramDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.instagramCancel),
          ),
          TextButton(
            key: const Key('instagram-disconnect-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.error,
            ),
            child: Text(l10n.instagramDisconnectButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _disconnecting = true);
    try {
      await ref.read(instagramServiceProvider).disconnect();
      ref.invalidate(instagramStatusProvider);
      if (mounted) _snack(l10n.instagramDisconnected);
    } on Exception catch (e) {
      debugPrint('Instagram disconnect failed: $e');
      if (mounted) _snack(l10n.instagramActionFailed);
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  void _openImport() {
    final open = widget.onOpenImport;
    if (open != null) {
      open();
    } else {
      unawaited(context.push(KolabingRoutes.instagramImport));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(instagramStatusProvider);
    // Keep the last value while a refresh is in flight so the card does not
    // blink out and back in after every connect/disconnect.
    final status = statusAsync.hasError ? null : statusAsync.value;

    if (status == null || !status.enabled) {
      return const SizedBox.shrink(key: Key('instagram-card-hidden'));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpacing),
      child: _CardShell(
        child: status.connected
            ? _ConnectedBody(
                status: status,
                disconnecting: _disconnecting,
                onImport: _openImport,
                onDisconnect: _disconnect,
                onHelp: () => InstagramProfessionalHelperSheet.show(context),
              )
            : _ConnectBody(
                connecting: _connecting,
                onConnect: _connect,
                onHelp: () => InstagramProfessionalHelperSheet.show(context),
              ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('instagram-card'),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(LucideIcons.instagram, size: 20, color: context.colors.primary),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          l10n.instagramCardTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HelpLink extends StatelessWidget {
  const _HelpLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      key: const Key('instagram-personal-help'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        foregroundColor: context.colors.onSurfaceVariant,
      ),
      child: Text(
        AppLocalizations.of(context).instagramPersonalAccountLink,
        style: KolabingTextStyles.bodySmall.copyWith(
          decoration: TextDecoration.underline,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _ConnectBody extends StatelessWidget {
  const _ConnectBody({
    required this.connecting,
    required this.onConnect,
    required this.onHelp,
  });

  final bool connecting;
  final VoidCallback onConnect;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CardHeader(),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.instagramConnectBody,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),
        KolabingButton(
          key: const Key('instagram-connect-button'),
          label: l10n.instagramConnectButton,
          onPressed: onConnect,
          isLoading: connecting,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.instagram, size: 18),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        _HelpLink(onTap: onHelp),
      ],
    );
  }
}

class _ConnectedBody extends StatelessWidget {
  const _ConnectedBody({
    required this.status,
    required this.disconnecting,
    required this.onImport,
    required this.onDisconnect,
    required this.onHelp,
  });

  final InstagramStatus status;
  final bool disconnecting;
  final VoidCallback onImport;
  final VoidCallback onDisconnect;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = status.username;
    final picture = status.profilePictureUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CardHeader(),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.colors.surfaceContainer,
              foregroundImage: picture == null ? null : NetworkImage(picture),
              onForegroundImageError: picture == null ? null : (_, _) {},
              child: Icon(
                LucideIcons.instagram,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                username == null
                    ? l10n.instagramConnectedGeneric
                    : l10n.instagramConnectedAs(username),
                key: const Key('instagram-connected-label'),
                style: KolabingTextStyles.bodyLarge.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),
        KolabingButton(
          key: const Key('instagram-import-button'),
          label: l10n.instagramImportButton,
          onPressed: status.isPersonalAccount ? null : onImport,
          isDisabled: status.isPersonalAccount,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.imagePlus, size: 18),
        ),
        if (status.isPersonalAccount) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          _HelpLink(onTap: onHelp),
        ],
        const SizedBox(height: KolabingSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('instagram-disconnect-button'),
            onPressed: disconnecting ? null : onDisconnect,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              foregroundColor: context.colors.error,
            ),
            icon: const Icon(LucideIcons.unlink, size: 16),
            label: Text(l10n.instagramDisconnectButton),
          ),
        ),
      ],
    );
  }
}
