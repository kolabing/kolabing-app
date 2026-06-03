import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Lets the user pick the app language, or follow the device language.
///
/// Selecting an option updates [localeProvider]; [MaterialApp] rebuilds with
/// the new [Locale] immediately, so no restart is needed.
class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    // Null == follow the system language.
    final entries = <_LanguageOption>[
      _LanguageOption(locale: null, label: l10n.languageSystemDefault),
      _LanguageOption(locale: const Locale('en'), label: l10n.languageEnglish),
      _LanguageOption(locale: const Locale('es'), label: l10n.languageSpanish),
      _LanguageOption(locale: const Locale('ca'), label: l10n.languageCatalan),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageScreenTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = entries[index];
          final selected =
              state.locale?.languageCode == option.locale?.languageCode;
          return ListTile(
            title: Text(option.label),
            trailing: selected
                ? const Icon(LucideIcons.check, color: KolabingColors.primary)
                : null,
            onTap: () => notifier.setLocale(option.locale),
          );
        },
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.locale, required this.label});
  final Locale? locale;
  final String label;
}
