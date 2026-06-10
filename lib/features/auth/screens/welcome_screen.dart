import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Local tokens
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF0A0A0A);
const Color _kTextMuted = Color(0xFFAAAAAA);
const Color _kYellow = Color(0xFFFFE28C);
const Color _kTextCream = Color(0xFFEEEEEE);

// ---------------------------------------------------------------------------
// WelcomeScreen
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoSlideY;
  late final Animation<double> _statementOpacity;
  late final Animation<double> _statementSlideY;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _ctaOpacity;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    Animation<double> fade(double a, double b) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entry,
            curve: Interval(a, b, curve: Curves.easeOutCubic),
          ),
        );

    Animation<double> slideY(double a, double b, {double from = 20.0}) =>
        Tween<double>(begin: from, end: 0.0).animate(
          CurvedAnimation(
            parent: _entry,
            curve: Interval(a, b, curve: Curves.easeOutCubic),
          ),
        );

    _logoOpacity = fade(0.00, 0.30);
    _logoSlideY = slideY(0.00, 0.30, from: -16);
    _statementOpacity = fade(0.25, 0.60);
    _statementSlideY = slideY(0.25, 0.60);
    _taglineOpacity = fade(0.45, 0.72);
    _ctaOpacity = fade(0.65, 0.92);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              28,
              compact ? 24 : 40,
              28,
              compact ? 20 : 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // ── Logo ──────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _entry,
                  builder: (context, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _logoSlideY.value),
                      child: child,
                    ),
                  ),
                  child: KolabingLogo(
                    width: compact ? 172.0 : 200.0,
                    variant: KolabingLogoVariant.yellowTransparent,
                  ),
                ),

                const Spacer(),

                // ── Brand statement ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _entry,
                  builder: (context, child) => Opacity(
                    opacity: _statementOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _statementSlideY.value),
                      child: child,
                    ),
                  ),
                  child: Opacity(
                    opacity: 0.82,
                    child: _BrandHeroText(compact: compact),
                  ),
                ),

                SizedBox(height: compact ? 24 : 32),

                // ── MATCH · KOLAB · GROW ──────────────────────────────────
                AnimatedBuilder(
                  animation: _taglineOpacity,
                  builder: (context, child) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: child,
                  ),
                  child: _Tagline(l10n: l10n),
                ),

                const Spacer(),

                // ── CTA ───────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _ctaOpacity,
                  builder: (context, child) => Opacity(
                    opacity: _ctaOpacity.value,
                    child: child,
                  ),
                  child: _PrimaryCta(onPressed: _onPrimaryCta, l10n: l10n),
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: _ctaOpacity,
                  builder: (context, child) => Opacity(
                    opacity: _ctaOpacity.value,
                    child: child,
                  ),
                  child: TextButton(
                    onPressed: _onLogin,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(88, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      l10n.welcomeLogIn,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: _kTextMuted,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
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

// ---------------------------------------------------------------------------
// Brand statement — staggered typographic layout
// ---------------------------------------------------------------------------

class _BrandHeroText extends StatelessWidget {
  const _BrandHeroText({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bigSize = compact ? 32.0 : 36.0;

    final bigStyle = GoogleFonts.archivoBlack(
      fontSize: bigSize,
      color: _kTextCream,
      height: 0.95,
      letterSpacing: -1.2,
    );
    final smallStyle = GoogleFonts.rubik(
      fontSize: compact ? 13.0 : 15.0,
      fontWeight: FontWeight.w600,
      color: _kTextCream,
      height: 1.2,
    );
    final ampStyle = GoogleFonts.rubik(
      fontSize: compact ? 20.0 : 24.0,
      fontWeight: FontWeight.w700,
      color: _kTextCream,
      height: 1,
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text('where', style: smallStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text('businesses', style: bigStyle, overflow: TextOverflow.visible, softWrap: false),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 5),
                child: Text('&', style: ampStyle),
              ),
              Text('communities', style: bigStyle, overflow: TextOverflow.visible, softWrap: false),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 28, right: 6),
                  child: Text('grow', style: smallStyle.copyWith(fontSize: compact ? 15.0 : 17.0)),
                ),
                Text('together', style: bigStyle, overflow: TextOverflow.visible, softWrap: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tagline
// ---------------------------------------------------------------------------

class _Tagline extends StatelessWidget {
  const _Tagline({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    TextStyle muted() => GoogleFonts.rubik(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.0,
          color: const Color(0xFF666666),
          height: 1.0,
        );

    TextStyle yellow() => GoogleFonts.rubik(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 3.0,
          color: _kYellow,
          height: 1.0,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(l10n.welcomeTaglineMatch, style: muted()),
        const SizedBox(width: 10),
        Text(l10n.welcomeTaglineDot, style: muted()),
        const SizedBox(width: 10),
        Text(l10n.welcomeTaglineKolab, style: yellow()),
        const SizedBox(width: 10),
        Text(l10n.welcomeTaglineDot, style: muted()),
        const SizedBox(width: 10),
        Text(l10n.welcomeTaglineGrow, style: muted()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onPressed, required this.l10n});

  final VoidCallback onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: l10n.welcomeStartKolabing,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.welcomeStartKolabing,
                    maxLines: 1,
                    softWrap: false,
                    style: KolabingTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(LucideIcons.arrowRight, size: 18),
            ],
          ),
        ),
      );
}
