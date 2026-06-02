import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_fade_slide.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Local theme tokens.
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF000000);
const Color _kMutedText = Color(0xCCFFFFFF); // ~80% white

// Hero photos cycle through these in order. All sit in assets/images/.
const List<String> _kHeroImages = <String>[
  'assets/images/welcome_hero.png',
  'assets/images/welcome_hero_coffee.png',
  'assets/images/welcome_hero_yoga.png',
  'assets/images/welcome_hero_bike.png',
];

// ---------------------------------------------------------------------------
// WelcomeScreen — minimal, community-first layout.
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;

  // Entrance animations.
  late final Animation<double> _heroFade;
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
      duration: const Duration(milliseconds: 1200),
    );
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _entry.duration = const Duration(milliseconds: 220);
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
    }) =>
        Tween<Offset>(begin: from, end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entry,
            curve: Interval(a, b, curve: Curves.easeOutCubic),
          ),
        );

    _heroFade = fade(0.00, 0.30);
    _logoOpacity = fade(0.10, 0.35);
    _headlineOpacity = fade(0.20, 0.50);
    _headlineSlide = slide(0.20, 0.50);
    _subtitleOpacity = fade(0.40, 0.65);
    _subtitleSlide = slide(0.40, 0.65, from: const Offset(0, 8));
    _ctaOpacity = fade(0.70, 0.95);
    _loginOpacity = fade(0.80, 1.00);
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
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Hero photo + gradient overlay.
            _HeroBackdrop(opacity: _heroFade),

            // Foreground content.
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  compact ? 12 : 18,
                  24,
                  compact ? 18 : 26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Top bar — wordmark.
                    AuthFadeOnly(
                      opacity: _logoOpacity,
                      child: const _TopBar(),
                    ),

                    SizedBox(height: compact ? 26 : 40),

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

                    // Hero fills remaining space.
                    const Expanded(child: SizedBox.shrink()),

                    // CTA.
                    AuthFadeOnly(
                      opacity: _ctaOpacity,
                      child: _PrimaryCta(onPressed: _onPrimaryCta),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _loginOpacity,
                      child: Center(
                        child: TextButton(
                          onPressed: _onLogin,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(88, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            AppLocalizations.of(context).welcomeLogIn,
                            style: KolabingTextStyles.bodySmall.copyWith(
                              color: _kMutedText,
                              fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero backdrop — full-bleed photo fading into pure black.
// ---------------------------------------------------------------------------

class _HeroBackdrop extends StatefulWidget {
  const _HeroBackdrop({required this.opacity});
  final Animation<double> opacity;

  @override
  State<_HeroBackdrop> createState() => _HeroBackdropState();
}

class _HeroBackdropState extends State<_HeroBackdrop> {
  int _index = 0;
  Timer? _timer;
  bool _precached = false;

  static const Duration _interval = Duration(milliseconds: 5200);
  static const Duration _fade = Duration(milliseconds: 1400);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final path in _kHeroImages) {
        precacheImage(AssetImage(path), context);
      }
    }
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduce && _timer == null) {
      _timer = Timer.periodic(_interval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % _kHeroImages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: _kBg),
            FadeTransition(
              opacity: widget.opacity,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xCCFFFFFF),
                    Color(0x80FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: <double>[0.0, 0.45, 0.85],
                ).createShader(rect),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    for (int i = 0; i < _kHeroImages.length; i++)
                      AnimatedOpacity(
                        duration: _fade,
                        curve: Curves.easeInOut,
                        opacity: i == _index ? 1.0 : 0.0,
                        child: Image.asset(
                          _kHeroImages[i],
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          gaplessPlayback: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Soft warm bloom top.
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              height: 320,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 0.9,
                    colors: <Color>[
                      KolabingColors.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom vignette for legibility.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, _kBg],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

// ---------------------------------------------------------------------------
// Top bar — tiny Kolabing wordmark, left-aligned.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Kolabing',
    child: const KolabingLogo(
      width: 128,
      variant: KolabingLogoVariant.yellowTransparent,
    ),
  );
}

// ---------------------------------------------------------------------------
// Headline — two lines, Anton font.
// ---------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 38.0 : 42.0;
    final style = KolabingTextStyles.displayLarge.copyWith(
      fontSize: fontSize,
      letterSpacing: -0.5,
      height: 1.02,
      color: KolabingColors.textOnDark,
    );
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(l10n.welcomeHeadlineLine1, style: style),
        Text(l10n.welcomeHeadlineLine2, style: style),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Subtitle — Inter, muted white.
// ---------------------------------------------------------------------------

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).welcomeSubtitle,
    style: KolabingTextStyles.captionSecondary.copyWith(
      color: _kMutedText,
      height: 1.45,
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
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.arrowRight, size: 18, color: KolabingColors.onPrimary),
        ],
      ),
    ),
  );
}
