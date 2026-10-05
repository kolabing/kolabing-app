import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/layout.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kolabing_button.dart';

/// Organiser onboarding "what's next" — Direction A (static cards).
///
/// Shown once, right after a community leader finishes creating their
/// community: 3 static informational cards (community is live → how members
/// discover/join kolabs → CTA to post the first kolab). No backend call.
///
/// This is the immediate fallback while Direction C (a live preview backed
/// by `/me/community-rank`) waits on its leaderboards backend endpoint — see
/// the deferred-items note at the bottom of this file.
///
/// Reached from two entry paths:
/// 1. The community-leader onboarding flow (go_router): inserted between
///    [CommunityFinalScreen] and the existing `/permissions` gate /
///    community dashboard. See [KolabingRoutes.communityOnboardingCards].
/// 2. The in-app "create a community" path from [CommunityHubScreen]
///    (`Navigator.push`, not a go_router route): pushed on top of that
///    stack after `CreateCommunityScreen` pops success.
///
/// [onPostFirstKolab] (and optionally [onSkip]) let each entry path decide
/// how to leave this screen once the user is finished (go_router
/// `context.go`/`push` vs. plain `Navigator.pop`) without this widget
/// knowing which one it's running under.
class CommunityOnboardingCardsScreen extends StatefulWidget {
  const CommunityOnboardingCardsScreen({
    required this.onPostFirstKolab,
    this.onSkip,
    super.key,
  });

  /// Called when the user taps the final card's "Post your first kolab" CTA.
  final VoidCallback onPostFirstKolab;

  /// Called when the user taps "Skip" on an earlier card. Defaults to the
  /// same action as [onPostFirstKolab] (land wherever "done" lands) so a
  /// skip never strands the user on this screen.
  final VoidCallback? onSkip;

  @override
  State<CommunityOnboardingCardsScreen> createState() =>
      _CommunityOnboardingCardsScreenState();
}

class _CommunityOnboardingCardsScreenState
    extends State<CommunityOnboardingCardsScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _cardCount = 3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.appBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _cardCount - 1) {
      widget.onPostFirstKolab();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip() => (widget.onSkip ?? widget.onPostFirstKolab)();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <_CardContent>[
      _CardContent(
        icon: LucideIcons.rocket,
        title: l10n.communityOnboardingCardsLiveTitle,
        body: l10n.communityOnboardingCardsLiveBody,
      ),
      _CardContent(
        icon: LucideIcons.users,
        title: l10n.communityOnboardingCardsDiscoverTitle,
        body: l10n.communityOnboardingCardsDiscoverBody,
      ),
      _CardContent(
        icon: LucideIcons.megaphone,
        title: l10n.communityOnboardingCardsCtaTitle,
        body: l10n.communityOnboardingCardsCtaBody,
      ),
    ];
    final isLast = _page == cards.length - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colors.appBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Skip — top-right, hidden on the last card where "Post your
              // first kolab" is itself the way forward.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLast)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          l10n.commonSkip,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: cards.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _OnboardingCard(
                    content: cards[i],
                  ),
                ),
              ),

              // Dot indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cards.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? context.colors.primary
                            : context.colors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Bottom CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: KolabingButton(
                  label: isLast
                      ? l10n.communityOnboardingCardsPostFirstKolab
                      : l10n.commonNext,
                  onPressed: _next,
                  variant: KolabingButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContent {
  const _CardContent({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.content});

  final _CardContent content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.lg,
      vertical: KolabingSpacing.md,
    ),
    child: Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.hairline),
          boxShadow: [KolabingShadows.card],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                content.icon,
                size: 28,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              content.title,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              content.body,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 14,
                color: context.colors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pushes [CommunityOnboardingCardsScreen] on the current (non-go_router)
/// [Navigator] stack — used by the [CommunityHubScreen] entry path, which
/// lives inside a tab shell rather than its own [GoRoute].
///
/// On "Post your first kolab", pops this screen (back to the hub) and then
/// pushes the unified kolab-creation entry (`/kolab/new`) via go_router, so
/// the kolab flow's own back button has somewhere to return to.
Future<void> pushCommunityOnboardingCards(BuildContext context) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CommunityOnboardingCardsScreen(
          onPostFirstKolab: () {
            Navigator.of(context).pop();
            context.push(KolabingRoutes.kolabNew);
          },
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Deferred (explicit, out of scope for this pass — see PR description):
// - ES/CA copy: strings below are English-only; app_es.arb / app_ca.arb fall
//   back to the English template per l10n.yaml (nullable-getter: false has
//   no `--fatal` flag set), so the build is not broken, but translation is
//   pending as a follow-up.
// - video_player: not a dependency of this app; this screen is static cards
//   only, no video asset.
// - Direction C (live-rank slider / `/me/community-rank`): that endpoint
//   does not exist yet (separate leaderboards backend task). This screen is
//   Direction A only.
// ---------------------------------------------------------------------------
