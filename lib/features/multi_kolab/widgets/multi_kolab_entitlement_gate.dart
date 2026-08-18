import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/constants/support.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Opens [uri]; returns whether a handler was found. Injected so widget tests
/// can assert the composed `mailto:` without a platform channel.
typedef MailtoLauncher = Future<bool> Function(Uri uri);

/// Shown to a profile that does not hold the Event Creator entitlement.
///
/// The Event Creator capability is **independent of the Business
/// subscription** — a Community can hold it, and a subscribed Business can
/// lack it. Nothing in this feature may consult `hasActiveSubscription()`.
/// The backend remains the authority: this widget only avoids showing
/// create/publish affordances that would be refused with
/// `403 event_creator_required`.
///
/// The "Request access" CTA is a **client-only contact mechanism**: it opens
/// the user's mail app at the published Kolabing support address. It grants
/// nothing. Event Creator is still granted exclusively by a maintainer
/// (entitlement `source = maintainer`); there is no self-serve API for it,
/// and this CTA must never route at the Business subscription paywall.
class MultiKolabEntitlementGate extends ConsumerWidget {
  const MultiKolabEntitlementGate({
    super.key,
    this.onRequestAccess,
    this.launcher,
  });

  /// Overrides the default mailto behaviour of the CTA. The CTA is always
  /// rendered — the mailto fallback means it is never dead.
  final VoidCallback? onRequestAccess;

  /// Test seam for the mailto launch. Defaults to `url_launcher`.
  final MailtoLauncher? launcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          key: const Key('multiKolabEntitlementGate'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: colors.primaryTint,
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
              child: Icon(LucideIcons.sparkles, color: colors.ink, size: 28),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.multiKolabEntitlementGateTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.sectionHeader.copyWith(
                color: colors.ink,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.multiKolabEntitlementGateBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.inkBody,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            KolabingButton(
              key: const Key('multiKolabEntitlementGateCta'),
              label: l10n.multiKolabEntitlementGateCta,
              onPressed:
                  onRequestAccess ?? () => _requestAccess(context, ref, l10n),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.multiKolabEntitlementGateCtaHint,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.captionSecondary.copyWith(
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAccess(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = buildRequestAccessMailto(
      subject: l10n.multiKolabEntitlementGateEmailSubject,
      body: l10n.multiKolabEntitlementGateEmailBody,
      user: ref.read(authProvider).user,
    );

    var opened = false;
    try {
      opened = await (launcher ?? launchUrl)(uri);
    } on Exception {
      opened = false;
    }

    if (opened) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.multiKolabEntitlementGateLaunchError(KolabingSupport.email),
        ),
      ),
    );
  }
}

/// Builds the `mailto:` URI for an Event Creator access request.
///
/// Only the account *type* and the profile id are appended — never a token,
/// an email address, or any other profile data. Those two lines are
/// deliberately left in stable English: they are operational metadata that
/// Kolabing staff triage, not copy the user reads, whereas the greeting and
/// subject follow the app locale like every other user-facing string.
///
/// Query parts are percent-encoded with [Uri.encodeComponent] rather than
/// `Uri(queryParameters:)`, which would encode the spaces in the body as `+`
/// — legal in a URL query, but rendered literally by mail clients.
@visibleForTesting
Uri buildRequestAccessMailto({
  required String subject,
  required String body,
  UserModel? user,
}) {
  final buffer = StringBuffer(body);
  if (user != null && user.id.isNotEmpty) {
    buffer
      ..write('\n\nAccount type: ')
      ..write(_accountTypeLabel(user.userType))
      ..write('\nProfile ID: ')
      ..write(user.id);
  }

  return Uri(
    scheme: 'mailto',
    path: KolabingSupport.email,
    query:
        'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(buffer.toString())}',
  );
}

String _accountTypeLabel(UserType type) => switch (type) {
  UserType.business => 'Business',
  UserType.community => 'Community',
  UserType.attendee => 'Attendee',
};
