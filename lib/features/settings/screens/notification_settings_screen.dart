import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/permission_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/models/notification_preferences.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/push_permission_provider.dart';

/// Notification preferences (NF-16 B3). Toggles bound to
/// `GET`/`PUT /me/notification-preferences`. Works for any role — the endpoint
/// is account-scoped.
///
/// Every push toggle is gated on the OS notification permission. Until that is
/// granted the switches read off and act as the opt-in, because Apple guideline
/// 4.5.4 treats a pre-enabled toggle as consent the user never gave.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notificationSettingsProvider);
    final pushGranted =
        ref.watch(pushPermissionGrantedProvider).asData?.value ?? false;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(notificationSettingsProvider.notifier).reload(),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (prefs) => _Toggles(prefs: prefs, pushGranted: pushGranted),
      ),
    );
  }
}

class _Toggles extends ConsumerWidget {
  const _Toggles({required this.prefs, required this.pushGranted});

  final NotificationPreferences prefs;

  /// Whether iOS/Android will actually deliver a push right now.
  final bool pushGranted;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences updated,
  ) async {
    try {
      await ref
          .read(notificationSettingsProvider.notifier)
          .setPreference(updated);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).notifSettingsSaveError),
        ),
      );
    }
  }

  /// Raises the system prompt and reports whether the user accepted.
  ///
  /// Nothing is stored and no token is registered unless they do. A permission
  /// the OS will no longer prompt for sends the user to Settings instead.
  Future<bool> _requestPushPermission(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final status = await PermissionService.instance
        .requestNotificationPermission();

    if (status.isGranted) {
      await ref.read(authProvider.notifier).syncPushPermissionGrant();
    }
    ref.invalidate(pushPermissionGrantedProvider);

    if (!status.isGranted && status.isPermanentlyDenied && context.mounted) {
      await PermissionService.instance.openSettings();
    }

    return status.isGranted;
  }

  /// One switch changed.
  ///
  /// Without the OS permission the switch is the opt-in: prompt first, and only
  /// write the preference once the user has actually said yes.
  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref, {
    required NotificationPreferences Function({required bool value}) update,
    required bool value,
  }) async {
    if (!pushGranted) {
      final granted = await _requestPushPermission(context, ref);
      if (!granted || !context.mounted) return;
      await _save(context, ref, update(value: true));
      return;
    }

    await _save(context, ref, update(value: value));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        if (!pushGranted)
          _PushOffBanner(onEnable: () => _requestPushPermission(context, ref)),
        SwitchListTile(
          value: pushGranted && prefs.messagesEnabled,
          title: Text(l10n.notifSettingsMessages),
          subtitle: Text(l10n.notifSettingsMessagesSubtitle),
          onChanged: (v) => _onToggle(
            context,
            ref,
            update: ({required bool value}) =>
                prefs.copyWith(messagesEnabled: value),
            value: v,
          ),
        ),
        SwitchListTile(
          value: pushGranted && prefs.applicationsEnabled,
          title: Text(l10n.notifSettingsApplications),
          subtitle: Text(l10n.notifSettingsApplicationsSubtitle),
          onChanged: (v) => _onToggle(
            context,
            ref,
            update: ({required bool value}) =>
                prefs.copyWith(applicationsEnabled: value),
            value: v,
          ),
        ),
        SwitchListTile(
          value: pushGranted && prefs.collaborationsEnabled,
          title: Text(l10n.notifSettingsCollaborations),
          subtitle: Text(l10n.notifSettingsCollaborationsSubtitle),
          onChanged: (v) => _onToggle(
            context,
            ref,
            update: ({required bool value}) =>
                prefs.copyWith(collaborationsEnabled: value),
            value: v,
          ),
        ),
        SwitchListTile(
          value: pushGranted && prefs.marketingEnabled,
          title: Text(l10n.notifSettingsMarketing),
          subtitle: Text(l10n.notifSettingsMarketingSubtitle),
          onChanged: (v) => _onToggle(
            context,
            ref,
            update: ({required bool value}) =>
                prefs.copyWith(marketingEnabled: value),
            value: v,
          ),
        ),
      ],
    );
  }
}

class _PushOffBanner extends StatelessWidget {
  const _PushOffBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(KolabingRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notifSettingsPushOffTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.notifSettingsPushOffBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            OutlinedButton(
              onPressed: onEnable,
              child: Text(l10n.notifSettingsPushOffCta),
            ),
          ],
        ),
      ),
    );
  }
}
