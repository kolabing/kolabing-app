import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/legal.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Full-screen blocking gate shown when the signed-in user must (re-)accept an
/// updated Terms of Service + Privacy Policy version. Rendered as an overlay
/// above the whole app; it dismisses automatically once consent is recorded
/// and the refreshed `terms` block reports `needs_acceptance: false`.
class ReconsentGate extends ConsumerStatefulWidget {
  const ReconsentGate({super.key});

  @override
  ConsumerState<ReconsentGate> createState() => _ReconsentGateState();
}

class _ReconsentGateState extends ConsumerState<ReconsentGate> {
  final TapGestureRecognizer _termsTap = TapGestureRecognizer();
  final TapGestureRecognizer _privacyTap = TapGestureRecognizer();
  bool _submitting = false;
  String? _error;

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

  Future<void> _accept() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // On success the auth state's `needsTermsConsent` flips to false and this
      // overlay is removed by its parent — nothing more to do here.
      await ref.read(authProvider.notifier).acceptTerms();
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context).reconsentError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final body = KolabingTextStyles.bodyMedium.copyWith(
      color: context.colors.onSurfaceVariant,
      height: 1.45,
    );
    final link = body.copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    _termsTap.onTap = () => _open(LegalLinks.termsUrl(lang));
    _privacyTap.onTap = () => _open(LegalLinks.privacyUrl(lang));

    // Consent is mandatory — block the Android system back gesture too.
    return PopScope(
      canPop: false,
      child: Material(
        color: context.colors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.gavel_rounded,
                  size: 48,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.reconsentTitle,
                  style: KolabingTextStyles.titleLarge.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.reconsentBody, style: body),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: body,
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
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: body.copyWith(color: context.colors.errorText),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      disabledBackgroundColor: context.colors.primary
                          .withValues(alpha: 0.6),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            l10n.reconsentAcceptButton,
                            style: KolabingTextStyles.button.copyWith(
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
