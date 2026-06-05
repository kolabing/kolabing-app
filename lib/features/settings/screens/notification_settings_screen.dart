import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/models/notification_preferences.dart';
import '../providers/notification_settings_provider.dart';

/// Notification preferences (NF-16 B3). Toggles bound to
/// `GET`/`PUT /me/notification-preferences`, including `message_notifications`
/// (default on). Works for any role — the endpoint is account-scoped.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notificationSettingsProvider);
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
                Text(e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodySmall
                        .copyWith(color: context.colors.onSurfaceVariant)),
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
        data: (prefs) => _Toggles(prefs: prefs),
      ),
    );
  }
}

class _Toggles extends ConsumerWidget {
  const _Toggles({required this.prefs});

  final NotificationPreferences prefs;

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
        SnackBar(content: Text(AppLocalizations.of(context).notifSettingsSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        SwitchListTile(
          value: prefs.messagesEnabled,
          title: Text(l10n.notifSettingsMessages),
          subtitle: Text(l10n.notifSettingsMessagesSubtitle),
          onChanged: (v) =>
              _save(context, ref, prefs.copyWith(messagesEnabled: v)),
        ),
        SwitchListTile(
          value: prefs.applicationsEnabled,
          title: Text(l10n.notifSettingsApplications),
          subtitle: Text(l10n.notifSettingsApplicationsSubtitle),
          onChanged: (v) =>
              _save(context, ref, prefs.copyWith(applicationsEnabled: v)),
        ),
        SwitchListTile(
          value: prefs.collaborationsEnabled,
          title: Text(l10n.notifSettingsCollaborations),
          subtitle: Text(l10n.notifSettingsCollaborationsSubtitle),
          onChanged: (v) =>
              _save(context, ref, prefs.copyWith(collaborationsEnabled: v)),
        ),
        SwitchListTile(
          value: prefs.marketingEnabled,
          title: Text(l10n.notifSettingsMarketing),
          subtitle: Text(l10n.notifSettingsMarketingSubtitle),
          onChanged: (v) =>
              _save(context, ref, prefs.copyWith(marketingEnabled: v)),
        ),
      ],
    );
  }
}
