import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_state_provider.dart';

/// Entry fade + scale.
const Duration _fadeInDuration = Duration(milliseconds: 240);

/// One fill of the mark, bottom to top.
const Duration _fillDuration = Duration(milliseconds: 1200);

/// How long the waterline takes to travel one wavelength. Deliberately not a
/// multiple of [_fillDuration]: if the two lined up, the wave would freeze at
/// the same shape every time the fill turned around.
const Duration _waveDuration = Duration(milliseconds: 2300);

/// Topping the mark up to full before leaving, so the last thing on screen is a
/// finished K rather than a half-drained one.
const Duration _topUpDuration = Duration(milliseconds: 260);

/// The floor on how long the mark stays up — one full fill. The screen leaves as
/// soon as initialisation finishes past this point.
const Duration _minHold = _fillDuration;

/// Exit fade.
const Duration _fadeOutDuration = Duration(milliseconds: 300);

/// The mark's rendered width. Roughly a third of a 393pt phone.
const double _markWidth = 132;

/// Pure black, deliberately not `KolabingColors.ink` (#19150F). It has to match
/// the icon asset's own ground and the native launch screen exactly, or the
/// hand-off shows a seam.
const Color _splashBlack = Color(0xFF000000);

/// The unfilled part of the mark. Present enough to read as the letter, dim
/// enough that the fill line is the thing you watch.
const double _emptyOpacity = 0.22;

/// Splash screen states
enum _SplashPhase {
  /// Initial state, elements fading in
  entering,

  /// Elements fully visible, work in flight
  holding,

  /// Transitioning to the destination
  exiting,
}

/// The opening screen: the K fills up while the app starts (#181).
///
/// It used to show the cloud lockup on yellow and hold for a flat **2000 ms**
/// whatever the app was doing — so a fast start waited for nothing, a slow one
/// looked frozen, and the mark had nothing to do with the icon you had just
/// tapped. Now:
///
/// * the ground is the icon's own **pure black**, continuing the tile straight
///   into the app — the native launch screen paints the same black, so there is
///   no white flash and no colour jump on the way in;
/// * the mark is the new K, and it **fills from the bottom** on a loop while the
///   work runs. The fill IS the loading indicator: a sweeping bar underneath did
///   the same job with less of the brand in it;
/// * the hold ends when initialisation ends, floored at [_minHold] so a fast
///   start does not flash the brand and vanish. On the way out the mark tops up
///   to full first, so it never leaves mid-drain.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Animation controller for fade in (mark + wordmark)
  late final AnimationController _entryController;

  /// Animation controller for exit fade
  late final AnimationController _exitController;

  /// The fill level, looping up and down until the app is ready.
  late final AnimationController _fillController;

  /// The waterline's travel, independent of the fill.
  late final AnimationController _waveController;

  /// Opacity animation for entry
  late final Animation<double> _opacityAnimation;

  /// Scale animation for entry (0.92 -> 1.0)
  late final Animation<double> _scaleAnimation;

  /// Exit opacity animation
  late final Animation<double> _exitOpacityAnimation;

  /// Eased fill, so the level slows at the top and bottom of its travel.
  late final Animation<double> _fill;

  /// Current splash phase
  _SplashPhase _phase = _SplashPhase.entering;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _startSplashSequence();
  }

  /// Light status-bar icons: the ground is black now, so the dark icons the
  /// yellow splash needed would be invisible.
  void _configureSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _splashBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: _fadeInDuration,
      vsync: this,
    );

    _exitController = AnimationController(
      duration: _fadeOutDuration,
      vsync: this,
    );

    _fillController = AnimationController(duration: _fillDuration, vsync: this);

    _waveController = AnimationController(duration: _waveDuration, vsync: this);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _exitOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _fill = CurvedAnimation(parent: _fillController, curve: Curves.easeInOut);

    // Reversing rather than restarting: a fill that snapped back to empty would
    // pop once per cycle, and the drain reads as one breath of the mark.
    _fillController.repeat(reverse: true);
    _waveController.repeat();
  }

  Future<void> _startSplashSequence() async {
    final initializationFuture = ref
        .read(splashStateProvider.notifier)
        .initialize();

    // Start the floor now, so it runs alongside the work rather than after it.
    final holdFloor = Future<void>.delayed(_minHold);

    await _entryController.forward();

    if (!mounted) return;
    setState(() => _phase = _SplashPhase.holding);

    // Leave when the work is done, not on a stopwatch. If it finished while the
    // entry animation played, `holdFloor` is what keeps the brand on screen
    // long enough to be seen.
    final route = await initializationFuture;
    await holdFloor;

    if (!mounted) return;
    setState(() => _phase = _SplashPhase.exiting);

    // Finish the letter before fading it: whatever the loop happened to be
    // doing, the mark ends full.
    _fillController.stop();
    await _fillController.animateTo(
      1,
      duration: _topUpDuration,
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    await _exitController.forward();

    if (!mounted) return;
    context.go(route);

    // A notification tap that cold-started the app was stashed while we were on
    // splash (this `go` would otherwise wipe it off the stack). Replay it now,
    // on top of the destination, so it opens its target screen. No-op when
    // there was no notification tap.
    markAppReadyForNotificationNav();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: _splashBlack,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entryController, _exitController]),
        builder: (context, child) => Opacity(
          opacity: _phase == _SplashPhase.exiting
              ? _exitOpacityAnimation.value
              : _opacityAnimation.value,
          child: Transform.scale(
            scale: _phase == _SplashPhase.entering
                ? _scaleAnimation.value
                : 1.0,
            child: child,
          ),
        ),
        child: Semantics(
          label: AppLocalizations.of(context).splashSemanticLabel,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FillingMark(
                  width: _markWidth,
                  fill: _fill,
                  wave: _waveController,
                ),
                const SizedBox(height: 28),
                // Brand name — exempt from i18n, like "Kolabing" everywhere.
                Text(
                  'KOLABING',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
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

/// The K, drawn twice: dim for the part still empty, full-strength for the part
/// the fill has reached.
///
/// Both layers are the same PNG, so the fill can never disagree with the mark's
/// shape. The bright copy is clipped to a wavy waterline that rises with [fill],
/// which is what makes it read as filling rather than as a wipe.
class _FillingMark extends StatelessWidget {
  const _FillingMark({
    required this.width,
    required this.fill,
    required this.wave,
  });

  final double width;

  /// 0 = empty, 1 = full.
  final Animation<double> fill;

  /// Drives the waterline's travel; only its value is used.
  final Animation<double> wave;

  static const String _asset = 'assets/brand/kolabing-k-mark.png';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([fill, wave]),
    builder: (context, _) => Stack(
      alignment: Alignment.center,
      children: [
        // The empty vessel.
        Image.asset(
          _asset,
          width: width,
          fit: BoxFit.contain,
          color: KolabingColors.primary.withValues(alpha: _emptyOpacity),
          // srcIn, so the tint replaces the mark's own yellow inside its alpha
          // rather than painting a rectangle over it.
          colorBlendMode: BlendMode.srcIn,
          excludeFromSemantics: true,
        ),
        // The filled part.
        ClipPath(
          clipper: _WaterlineClipper(fill: fill.value, phase: wave.value),
          child: Image.asset(
            _asset,
            width: width,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ],
    ),
  );
}

/// Everything below a gently moving waterline.
class _WaterlineClipper extends CustomClipper<Path> {
  const _WaterlineClipper({required this.fill, required this.phase});

  /// 0 = clip everything away, 1 = keep all of it.
  final double fill;

  /// 0..1, one full wavelength of travel.
  final double phase;

  /// Peak-to-trough is twice this. Small on purpose: the mark is 132pt wide and
  /// a tall wave would read as a wobble in the letter itself.
  static const double _amplitude = 3.5;

  /// Waves across the mark's width.
  static const double _cycles = 1.5;

  @override
  Path getClip(Size size) {
    // Overshoot top and bottom so a full or empty mark has no hairline of the
    // wrong layer showing at the extremes.
    final level = size.height * (1 - fill);
    // Flatten the wave as the level reaches either end, where a wave would
    // otherwise cut a notch out of the finished letter.
    final ends = math.sin(fill.clamp(0.0, 1.0) * math.pi);
    final amplitude = _amplitude * ends;

    final path = Path()..moveTo(0, level);
    for (double x = 0; x <= size.width; x += 2) {
      final t = x / size.width * _cycles * 2 * math.pi;
      path.lineTo(x, level + amplitude * math.sin(t + phase * 2 * math.pi));
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_WaterlineClipper oldClipper) =>
      oldClipper.fill != fill || oldClipper.phase != phase;
}
