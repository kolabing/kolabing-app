import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Local theme tokens — landing page aesthetic (pure black + neon yellow).
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF000000);
const Color _kAccentYellow = Color(0xFFFFD861);
const Color _kCardSurface = Color(0xFFFCFAF5);
const Color _kInk = Color(0xFF0D0D0D);
const Color _kMutedWhite = Color(0xCCFFFFFF); // ~80% white

// Hero photos cycle through these in order. All sit in assets/images/.
const List<String> _kHeroImages = <String>[
  'assets/images/welcome_hero.png', // rooftop cheers, Sagrada at sunset
  'assets/images/welcome_hero_coffee.png', // runners circle with coffee cups
  'assets/images/welcome_hero_yoga.png', // yoga silhouettes at sunset
  'assets/images/welcome_hero_bike.png', // cyclists on mountain road
];

// ---------------------------------------------------------------------------
// WelcomeScreen — v6, landing-page parity.
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
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _line1Opacity;
  late final Animation<Offset> _line1Slide;
  late final Animation<double> _line2Opacity;
  late final Animation<Offset> _line2Slide;
  late final Animation<double> _line3Opacity;
  late final Animation<Offset> _line3Slide;
  late final Animation<double> _line3Pulse;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _notif1Opacity;
  late final Animation<Offset> _notif1Slide;
  late final Animation<double> _notif2Opacity;
  late final Animation<Offset> _notif2Slide;
  late final Animation<double> _notif3Opacity;
  late final Animation<Offset> _notif3Slide;
  late final Animation<double> _ctaOpacity;
  late final Animation<Offset> _ctaSlide;
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
      Offset from = const Offset(0, 18),
    }) => Tween<Offset>(begin: from, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entry,
        curve: Interval(a, b, curve: Curves.easeOutCubic),
      ),
    );

    _heroFade = fade(0.00, 0.30);
    _logoOpacity = fade(0.10, 0.35);
    _logoSlide = slide(0.10, 0.35, from: const Offset(0, -8));
    _line1Opacity = fade(0.20, 0.45);
    _line1Slide = slide(0.20, 0.45);
    _line2Opacity = fade(0.30, 0.55);
    _line2Slide = slide(0.30, 0.55);
    _line3Opacity = fade(0.40, 0.65);
    _line3Slide = slide(0.40, 0.65);
    _line3Pulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
    ]).animate(_entry);
    _taglineOpacity = fade(0.55, 0.78);
    _taglineSlide = slide(0.55, 0.78, from: const Offset(0, 8));
    _notif1Opacity = fade(0.58, 0.82);
    _notif1Slide = slide(0.58, 0.82, from: const Offset(40, 20));
    _notif2Opacity = fade(0.66, 0.90);
    _notif2Slide = slide(0.66, 0.90, from: const Offset(-32, 24));
    _notif3Opacity = fade(0.74, 0.96);
    _notif3Slide = slide(0.74, 0.96, from: const Offset(28, 28));
    _ctaOpacity = fade(0.80, 1.00);
    _ctaSlide = slide(0.80, 1.00, from: const Offset(0, 12));
    _loginOpacity = fade(0.90, 1.00);
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
            // Hero photo + heavy gradient overlay.
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
                    // Top bar — small wordmark.
                    _FadeSlide(
                      opacity: _logoOpacity,
                      offset: _logoSlide,
                      child: const _TopBar(),
                    ),

                    SizedBox(height: compact ? 26 : 40),

                    // Headline — 3 stacked lines.
                    _Headline(
                      compact: compact,
                      line1Opacity: _line1Opacity,
                      line1Slide: _line1Slide,
                      line2Opacity: _line2Opacity,
                      line2Slide: _line2Slide,
                      line3Opacity: _line3Opacity,
                      line3Slide: _line3Slide,
                      line3Pulse: _line3Pulse,
                    ),

                    SizedBox(height: compact ? 16 : 22),

                    // Tagline + signature.
                    _FadeSlide(
                      opacity: _taglineOpacity,
                      offset: _taglineSlide,
                      child: const _Tagline(),
                    ),

                    // Notification stack absorbs the remaining space.
                    Expanded(
                      child: _NotificationStack(
                        notif1Opacity: _notif1Opacity,
                        notif1Slide: _notif1Slide,
                        notif2Opacity: _notif2Opacity,
                        notif2Slide: _notif2Slide,
                        notif3Opacity: _notif3Opacity,
                        notif3Slide: _notif3Slide,
                      ),
                    ),

                    // CTA.
                    _FadeSlide(
                      opacity: _ctaOpacity,
                      offset: _ctaSlide,
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
                            'LOGIN',
                            style: GoogleFonts.darkerGrotesque(
                              color: _kMutedWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
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
  Widget build(BuildContext context) {
    return ExcludeSemantics(
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
                      _kAccentYellow.withValues(alpha: 0.12),
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
}

// ---------------------------------------------------------------------------
// Top bar — tiny Kolabing wordmark, left-aligned.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          label: 'Kolabing',
          child: const KolabingLogo(
            width: 128,
            variant: KolabingLogoVariant.yellowTransparent,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Headline — three stacked lines.
// ---------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline({
    required this.compact,
    required this.line1Opacity,
    required this.line1Slide,
    required this.line2Opacity,
    required this.line2Slide,
    required this.line3Opacity,
    required this.line3Slide,
    required this.line3Pulse,
  });

  final bool compact;
  final Animation<double> line1Opacity;
  final Animation<Offset> line1Slide;
  final Animation<double> line2Opacity;
  final Animation<Offset> line2Slide;
  final Animation<double> line3Opacity;
  final Animation<Offset> line3Slide;
  final Animation<double> line3Pulse;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 46.0;
    final style = GoogleFonts.rubik(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.6,
      height: 0.96,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _FadeSlide(
          opacity: line1Opacity,
          offset: line1Slide,
          child: _FitLine(
            'REAL PEOPLE',
            style: style.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 2),
        _FadeSlide(
          opacity: line2Opacity,
          offset: line2Slide,
          child: _FitLine(
            'REAL EXPERIENCES',
            style: style.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 2),
        _FadeSlide(
          opacity: line3Opacity,
          offset: line3Slide,
          child: ScaleTransition(
            scale: line3Pulse,
            alignment: Alignment.centerLeft,
            child: _FitLine(
              'REAL GROWTH.',
              style: style.copyWith(color: _kAccentYellow),
            ),
          ),
        ),
      ],
    );
  }
}

class _FitLine extends StatelessWidget {
  const _FitLine(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: style,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tagline — "not ads. not influencers. people."
// ---------------------------------------------------------------------------

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 22,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.40),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: GoogleFonts.openSans(
                color: _kMutedWhite,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              children: <InlineSpan>[
                const TextSpan(text: 'not ads. not influencers. '),
                TextSpan(
                  text: 'people.',
                  style: GoogleFonts.openSans(
                    color: _kAccentYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notification stack — two floating cards in the lower middle.
// ---------------------------------------------------------------------------

class _NotificationStack extends StatelessWidget {
  const _NotificationStack({
    required this.notif1Opacity,
    required this.notif1Slide,
    required this.notif2Opacity,
    required this.notif2Slide,
    required this.notif3Opacity,
    required this.notif3Slide,
  });

  final Animation<double> notif1Opacity;
  final Animation<Offset> notif1Slide;
  final Animation<double> notif2Opacity;
  final Animation<Offset> notif2Slide;
  final Animation<double> notif3Opacity;
  final Animation<Offset> notif3Slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Card width adapts so it never clips on smaller screens.
        // Range: 196dp (small) to 240dp (regular).
        final cardWidth = math.min(240.0, math.max(196.0, w * 0.74));

        // Three cards: collab (top-right), sponsorship (mid-left),
        // event activity (bottom-right). Vertical spacing flexes with
        // available height.
        final topY = math.max(0.0, h * 0.02);
        final midY = math.max(0.0, h * 0.36);
        final botY = math.max(0.0, h * 0.68);

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // 1. Collab match — community ↔ business.
            Positioned(
              right: 0,
              top: topY,
              child: _AnimatedTilt(
                opacity: notif1Opacity,
                offset: notif1Slide,
                angleDeg: -3,
                child: _NotifCard(
                  width: cardWidth,
                  iconBg: const Color(0xFF8B7BFF),
                  icon: LucideIcons.heart,
                  title: 'New Kolab match',
                  body: 'Café Mira wants to collab',
                ),
              ),
            ),

            // 2. Sponsorship approved — business → community.
            Positioned(
              left: 0,
              top: midY,
              child: _AnimatedTilt(
                opacity: notif2Opacity,
                offset: notif2Slide,
                angleDeg: 2,
                child: _NotifCard(
                  width: cardWidth,
                  iconBg: const Color(0xFF22C55E),
                  icon: LucideIcons.badgeCheck,
                  title: 'Sponsorship approved',
                  body: 'Mahou backed your event · €1,200',
                ),
              ),
            ),

            // 3. Live event traction — community ↔ attendee.
            Positioned(
              right: 4,
              top: botY,
              child: _AnimatedTilt(
                opacity: notif3Opacity,
                offset: notif3Slide,
                angleDeg: -2,
                child: _NotifCard(
                  width: cardWidth,
                  iconBg: _kAccentYellow,
                  iconColor: _kInk,
                  icon: LucideIcons.users,
                  title: '+30 runners joined',
                  body: 'Tuesday morning run · 08:00',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedTilt extends StatelessWidget {
  const _AnimatedTilt({
    required this.opacity,
    required this.offset,
    required this.angleDeg,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> offset;
  final double angleDeg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final angle = angleDeg * math.pi / 180;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[opacity, offset]),
      builder: (context, c) {
        final o = offset.value;
        return Transform.translate(
          offset: o,
          child: Opacity(
            opacity: opacity.value.clamp(0.0, 1.0),
            child: Transform.rotate(angle: angle, child: c),
          ),
        );
      },
      child: child,
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.width,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor = Colors.white,
  });

  final double width;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $body',
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _kCardSurface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: _kInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF5A5A55),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ],
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
// Primary CTA — full-width yellow GET STARTED button.
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Get started',
    child: Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _kAccentYellow.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kAccentYellow,
          foregroundColor: _kInk,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Flexible + FittedBox lets the label shrink instead of
            // overflowing on narrow screens at large text scales (e.g.
            // 320dp width @ 1.25x previously overflowed the Row by 27px).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'GET STARTED',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.darkerGrotesque(
                    color: _kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(LucideIcons.arrowRight, size: 18, color: _kInk),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// FadeSlide combinator.
// ---------------------------------------------------------------------------

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.opacity,
    required this.offset,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> offset;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[opacity, offset]),
    builder: (context, c) => Opacity(
      opacity: opacity.value.clamp(0.0, 1.0),
      child: Transform.translate(offset: offset.value, child: c),
    ),
    child: child,
  );
}
