import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/legal.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

/// Auto-renewal disclosure + functional Terms of Use (EULA) and Privacy Policy
/// links, shown on every subscription purchase surface.
///
/// App Store Review Guideline 3.1.2 requires the app binary itself (not only
/// the App Store metadata) to disclose the auto-renewal terms and expose a
/// functional link to the Terms of Use (EULA) and to the Privacy Policy at the
/// point of purchase. The Jul 31, 2026 review (submission
/// 18720871-a906-4023-8ac0-c0054e1818f1) rejected v1.5 for a missing EULA link.
///
/// Links reuse the canonical [LegalLinks] URLs (locale-aware) and open in an
/// external browser, matching `TermsConsentCheckbox` on the sign-up screens.
class SubscriptionLegalFooter extends StatelessWidget {
  const SubscriptionLegalFooter({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    final noticeStyle = KolabingTextStyles.bodySmall.copyWith(
      fontSize: 11,
      height: 1.4,
      color: context.colors.textTertiary,
    );
    // Dark, bold, underlined — signals tappability against the light sheet.
    final linkStyle = KolabingTextStyles.bodySmall.copyWith(
      fontSize: 11,
      color: context.colors.onSurface,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: context.colors.onSurface,
    );

    Widget legalLink(String label, String url) => GestureDetector(
      onTap: () => _open(url),
      behavior: HitTestBehavior.opaque,
      child: Text(label, style: linkStyle),
    );

    return Column(
      children: [
        Text(
          l10n.subscriptionLegalAutoRenewNotice,
          style: noticeStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            legalLink(
              l10n.subscriptionLegalTermsOfUse,
              LegalLinks.termsUrl(lang),
            ),
            Text('·', style: noticeStyle),
            legalLink(
              l10n.subscriptionLegalPrivacyPolicy,
              LegalLinks.privacyUrl(lang),
            ),
          ],
        ),
      ],
    );
  }
}
