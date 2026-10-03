import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_brand_hero.dart';
import '../widgets/auth_fade_slide.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

const Color _kYellow = KolabingColors.primary;
const Color _kYellowDeep = KolabingColors.primaryDark;
const Color _kCream = kAuthSheetCream;
const Color _kInk = KolabingColors.ink;
const Color _kMuted = KolabingColors.muted;
const Color _kTaglineDot = Color(0xFFB5914A);

const double _kRiseDistance = 18;

// ---------------------------------------------------------------------------
// WelcomeScreen — the K on black, as on the splash and login
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) _entry.duration = const Duration(milliseconds: 150);
    if (!_entry.isAnimating && _entry.status == AnimationStatus.dismissed) {
      _entry.forward();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _onPrimaryCta() {
    HapticFeedback.lightImpact();
    context.push(KolabingRoutes.userTypeSelection);
  }

  void _onLogin() {
    HapticFeedback.selectionClick();
    context.push(KolabingRoutes.login);
  }

  /// One staggered slice of the entry animation, [start]..[end] of 0..1.
  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entry,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  /// Fades a row in while it rises [_kRiseDistance] into place.
  Widget _rise(double start, Widget child) {
    final t = _stagger(start, math.min(start + 0.45, 1));
    return AuthFadeSlide(
      opacity: t,
      offset: Tween<Offset>(
        begin: const Offset(0, _kRiseDistance),
        end: Offset.zero,
      ).animate(t),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    // Just under half the screen, but never so short the mark feels cramped.
    final heroHeight = math.max(
      size.height * 0.46,
      topInset + AuthBrandHero.navHeight + 190 + AuthBrandHero.sheetRadius,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kAuthHeroOverlayStyle,
      child: Scaffold(
        backgroundColor: _kCream,
        // Black above the middle, cream below, so an iOS overscroll at either
        // end shows the colour of the section it pulls away from.
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kAuthHeroNight, kAuthHeroNight, _kCream, _kCream],
              stops: [0, 0.5, 0.5, 1],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AuthBrandHero(
                  height: heroHeight,
                  markHeight: 104,
                  reveal: _stagger(0, 0.55),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: ColoredBox(
                  color: _kCream,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _rise(0.2, const _WelcomeHeadline()),
                          const SizedBox(height: 22),
                          _rise(0.3, const _TaglineRow()),
                          // Pushes the actions to the thumb zone on tall
                          // screens; collapses when space is short.
                          const Spacer(),
                          const SizedBox(height: 32),
                          _rise(
                            0.4,
                            _PrimaryCta(
                              label: l10n.welcomeStartKolabing,
                              onPressed: _onPrimaryCta,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _rise(
                            0.5,
                            _LoginLink(
                              prompt: l10n.welcomeAlreadyIn,
                              action: l10n.welcomeLogIn,
                              onTap: _onLogin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline — "Where businesses / and communities / grow together"
// ---------------------------------------------------------------------------

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: _kInk,
      height: 1.15,
      letterSpacing: -0.6,
    );

    return Column(
      children: [
        Text(
          '${l10n.welcomeHeroWhere} ${l10n.welcomeHeroBusinesses}',
          style: style,
          textAlign: TextAlign.center,
        ),
        Text(
          '${l10n.welcomeHeroAnd} ${l10n.welcomeHeroCommunities}',
          style: style,
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('${l10n.welcomeHeroGrow} ', style: style),
            _YellowSwashText(text: l10n.welcomeHeroTogether, style: style),
          ],
        ),
      ],
    );
  }
}

/// Text with a yellow swash behind its baseline.
class _YellowSwashText extends StatelessWidget {
  const _YellowSwashText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomLeft,
    children: [
      Positioned(
        bottom: 3,
        left: -2,
        right: -2,
        child: Container(
          height: 11,
          decoration: BoxDecoration(
            color: _kYellow,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      Text(text, style: style),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tagline — MATCH · KOLAB · GROW
// ---------------------------------------------------------------------------

class _TaglineRow extends StatelessWidget {
  const _TaglineRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 3.4,
    );
    final dot = Text(
      l10n.welcomeTaglineDot,
      style: base.copyWith(color: _kTaglineDot),
    );

    // Scales down rather than overflowing on narrow, large-text screens.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.welcomeTaglineMatch, style: base.copyWith(color: _kMuted)),
          const SizedBox(width: 6),
          dot,
          const SizedBox(width: 6),
          Text(l10n.welcomeTaglineKolab, style: base.copyWith(color: _kInk)),
          const SizedBox(width: 6),
          dot,
          const SizedBox(width: 6),
          Text(l10n.welcomeTaglineGrow, style: base.copyWith(color: _kMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA — ink pill, yellow label, as on login
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      key: const Key('welcome-start'),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: _kInk,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: _kInk.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // Scales down rather than overflowing for long translations or
          // large text.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kYellow,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: _kYellow,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// "Already in? Log in" — the whole row is the button
// ---------------------------------------------------------------------------

class _LoginLink extends StatelessWidget {
  const _LoginLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('welcome-login'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    prompt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                    decoration: TextDecoration.underline,
                    decorationColor: _kYellowDeep,
                    decorationThickness: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
