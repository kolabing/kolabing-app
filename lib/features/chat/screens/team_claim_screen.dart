import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/team_claim_preview.dart';
import '../services/team_claim_service.dart';

/// Where an owner claims a profile the Kolabing team created for them
/// (SERR-1344), from the claim link in the team's message.
///
/// Shows the offer and whose page it is, then Google / Apple sign-in. Signing in
/// IS the claim: the backend makes that account the profile's holder and
/// accepts the offer. The line that the owner can delete the page afterwards
/// sits on this screen (no banner on the unclaimed page itself).
class TeamClaimScreen extends ConsumerStatefulWidget {
  const TeamClaimScreen({required this.token, this.service, super.key});

  final String token;

  /// Injected in tests.
  final TeamClaimService? service;

  @override
  ConsumerState<TeamClaimScreen> createState() => _TeamClaimScreenState();
}

class _TeamClaimScreenState extends ConsumerState<TeamClaimScreen> {
  late final TeamClaimService _service = widget.service ?? TeamClaimService();
  TeamClaimPreview? _preview;
  TeamClaimException? _error;
  bool _loading = true;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await _service.preview(widget.token);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on TeamClaimException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _claim({required bool apple}) async {
    if (_claiming) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _claiming = true);

    final result = await ref
        .read(authProvider.notifier)
        .claimTeamProfile(widget.token, apple: apple);
    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teamClaimDone)));
      // The session is the owner's now; let the app resolve where they belong.
      context.go(KolabingRoutes.splash);
      return;
    }

    setState(() => _claiming = false);
    if (result.cancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.error?.message ?? result.errorMessage ?? l10n.teamClaimFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = _preview;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (preview == null) {
      body = _message(
        (_error?.isUnknown ?? false) || (_error?.isExpiredOrUsed ?? false)
            ? l10n.teamClaimInvalid
            : l10n.teamClaimFailed,
        const ValueKey('team-claim-error'),
      );
    } else if (preview.expired) {
      body = _message(
        l10n.teamClaimExpired,
        const ValueKey('team-claim-expired'),
      );
    } else if (!preview.claimable) {
      body = _message(
        l10n.teamClaimInvalid,
        const ValueKey('team-claim-error'),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        children: [
          Text(
            l10n.teamClaimIntro(preview.profileName),
            key: const ValueKey('team-claim-intro'),
            style: KolabingTextStyles.bodyMedium,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            preview.offer.title,
            key: const ValueKey('team-claim-offer-title'),
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview.offer.message != null &&
              preview.offer.message!.trim().isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(preview.offer.message!, style: KolabingTextStyles.bodySmall),
          ],
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            l10n.teamClaimDeleteLine,
            key: const ValueKey('team-claim-delete-line'),
            style: KolabingTextStyles.bodySmall,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          FilledButton(
            key: const ValueKey('team-claim-google'),
            onPressed: _claiming ? null : () => _claim(apple: false),
            child: Text(l10n.teamClaimWithGoogle),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            const SizedBox(height: KolabingSpacing.sm),
            OutlinedButton(
              key: const ValueKey('team-claim-apple'),
              onPressed: _claiming ? null : () => _claim(apple: true),
              child: Text(l10n.teamClaimWithApple),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamClaimTitle)),
      body: body,
    );
  }

  Widget _message(String text, Key key) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Text(text, key: key, textAlign: TextAlign.center),
    ),
  );
}
