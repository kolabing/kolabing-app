import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_fade_slide.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Local theme tokens — dark edition.
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF0A0A0A);
const Color _kTextPrimary = Color(0xFF1C1C16);
const Color _kTextWhite = Color(0xFFFFFFFF);
const Color _kTextMuted = Color(0xFFAAAAAA);
const Color _kYellow = Color(0xFFFFD861);

// ---------------------------------------------------------------------------
// WelcomeScreen — clean white, editorial brand layout.
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _ctaOpacity;
  late final Animation<double> _loginOpacity;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _entry.duration = const Duration(milliseconds: 200);
    }
    if (!_entry.isAnimating && _entry.status == AnimationStatus.dismissed) {
      _entry.forward();
    }
  }

  void _initAnimations() {
    Animation<double> fade(double a, double b) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entry,
            curve: Interval(a, b, curve: Curves.easeOutCubic),
          ),
        );

    Animation<Offset> slide(
      double a,
      double b, {
      Offset from = const Offset(0, 16),
    }) => Tween<Offset>(begin: from, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entry,
        curve: Interval(a, b, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = fade(0.00, 0.28);
    _headlineOpacity = fade(0.18, 0.50);
    _headlineSlide = slide(0.18, 0.50);
    _subtitleOpacity = fade(0.38, 0.62);
    _subtitleSlide = slide(0.38, 0.62, from: const Offset(0, 8));
    _ctaOpacity = fade(0.65, 0.90);
    _loginOpacity = fade(0.75, 1.00);
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
            padding: EdgeInsets.fromLTRB(24, compact ? 12 : 20, 24, compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: compact ? 8 : 16),

                // Headline.
                AuthFadeSlide(
                  opacity: _headlineOpacity,
                  offset: _headlineSlide,
                  child: _Headline(compact: compact),
                ),

                SizedBox(height: compact ? 12 : 16),

                // Subtitle.
                AuthFadeSlide(
                  opacity: _subtitleOpacity,
                  offset: _subtitleSlide,
                  child: const _Subtitle(),
                ),

                const Spacer(),

                // Logo — centred between subtitle and CTA.
                AuthFadeOnly(
                  opacity: _logoOpacity,
                  child: Center(
                    child: KolabingLogo(
                      width: compact ? 160.0 : 190.0,
                      variant: KolabingLogoVariant.onDark,
                    ),
                  ),
                ),

                const Spacer(),

                // CTA button.
                AuthFadeOnly(
                  opacity: _ctaOpacity,
                  child: _PrimaryCta(onPressed: _onPrimaryCta),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _loginOpacity,
                  child: Center(
                    child: TextButton(
                      onPressed: _onLogin,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(88, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        AppLocalizations.of(context).welcomeLogIn,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: _kTextMuted,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
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
// Headline — Anton uppercase, black + yellow alternating words.
// ---------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 34.0 : 38.0;
    const lineHeight = 1.05;

    TextStyle base(Color color) => GoogleFonts.anton(
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: 0.0,
      color: color,
    );

    final black = base(_kTextWhite);
    final yellow = base(_kYellow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Line 1: MAKE KOLABS.
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(text: 'MAKE ', style: black),
              TextSpan(text: 'KOLABS.', style: yellow),
            ],
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        // Line 2: FILL YOUR BUSINESS.
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(text: 'FILL YOUR ', style: black),
              TextSpan(text: 'BUSINESS.', style: yellow),
            ],
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        // Line 3: REWARD YOUR COMMUNITY.
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(text: 'REWARD YOUR ', style: black),
              TextSpan(text: 'COMMUNITY.', style: yellow),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Subtitle — Inter, muted dark grey.
// ---------------------------------------------------------------------------

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) => Text(
    'Community-led partnerships for events, UGC, reviews and real-world growth.',
    style: KolabingTextStyles.bodySmall.copyWith(
      color: _kTextMuted,
      height: 1.6,
      fontSize: 15,
      letterSpacing: 0.1,
    ),
  );
}

// ---------------------------------------------------------------------------
// Primary CTA — full-width yellow "Get started" button.
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppLocalizations.of(context).welcomeGetStarted,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _kYellow,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context).welcomeGetStarted,
                maxLines: 1,
                softWrap: false,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.arrowRight, size: 18, color: _kTextPrimary),
        ],
      ),
    ),
  );
}
