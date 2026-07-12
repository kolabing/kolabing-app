import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/legal.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

/// Mandatory Terms of Service + Privacy Policy consent checkbox for the sign-up
/// screens. The primary sign-up button must stay disabled until [value] is
/// true. Tapping a link opens the locale-appropriate legal page; tapping the
/// surrounding text toggles the checkbox.
class TermsConsentCheckbox extends StatefulWidget {
  const TermsConsentCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  State<TermsConsentCheckbox> createState() => _TermsConsentCheckboxState();
}

class _TermsConsentCheckboxState extends State<TermsConsentCheckbox> {
  final TapGestureRecognizer _termsTap = TapGestureRecognizer();
  final TapGestureRecognizer _privacyTap = TapGestureRecognizer();

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _toggle() {
    if (widget.enabled) widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final base = KolabingTextStyles.bodySmall.copyWith(
      fontSize: 12,
      color: context.colors.onSurfaceVariant,
    );
    final link = base.copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    _termsTap.onTap = () => _open(LegalLinks.termsUrl(lang));
    _privacyTap.onTap = () => _open(LegalLinks.privacyUrl(lang));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: widget.value,
            onChanged: widget.enabled
                ? (v) => widget.onChanged(v ?? false)
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: context.colors.primary,
            checkColor: context.colors.onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  TextSpan(text: l10n.consentAgreeLead),
                  TextSpan(
                    text: l10n.consentTermsLabel,
                    style: link,
                    recognizer: _termsTap,
                  ),
                  TextSpan(text: l10n.consentAgreeConjunction),
                  TextSpan(
                    text: l10n.consentPrivacyLabel,
                    style: link,
                    recognizer: _privacyTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
