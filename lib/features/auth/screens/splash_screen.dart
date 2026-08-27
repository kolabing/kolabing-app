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

/// The floor on how long the mark stays up — one full sweep of the bar. The
/// screen leaves as soon as initialisation finishes past this point.
const Duration _minHold = Duration(milliseconds: 1100);

/// Exit fade.
const Duration _fadeOutDuration = Duration(milliseconds: 300);

/// The mark's rendered width. Roughly a third of a 393pt phone: big enough to
/// be the subject, small enough that the bar reads as attached to it.
const double _markWidth = 132;

/// Pure black, deliberately not `KolabingColors.ink` (#19150F). It has to match
/// the icon asset's own ground and the native launch screen exactly, or the
/// hand-off shows a seam.
const Color _splashBlack = Color(0xFF000000);

/// Splash screen states
enum _SplashPhase {
  /// Initial state, elements fading in
  entering,

  /// Elements fully visible, work in flight
  holding,

  /// Transitioning to the destination
  exiting,
}

/// The opening screen: the K mark on black, and a bar that says work is
/// happening (#181).
///
/// It used to show the cloud lockup on yellow and hold for a flat **2000 ms**
/// whatever the app was doing — so a fast start waited for nothing, a slow one
/// looked frozen, and the mark had nothing to do with the icon you had just
/// tapped. Now:
///
/// * the ground is the icon's own **pure black**, continuing the tile straight
///   into the app — the native launch screen paints the same black, so there is
///   no white flash and no colour jump on the way in;
/// * the mark is the new K;
/// * a slim indeterminate bar sweeps underneath, which is the "loading" part;
/// * the hold ends when initialisation ends, floored at [_minHold] so a fast
///   start does not flash the brand and vanish.
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

  /// Opacity animation for entry
  late final Animation<double> _opacityAnimation;

  /// Scale animation for entry (0.92 -> 1.0)
  late final Animation<double> _scaleAnimation;

  /// Exit opacity animation
  late final Animation<double> _exitOpacityAnimation;

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
                Image.asset(
                  'assets/brand/kolabing-k-mark.png',
                  width: _markWidth,
                  fit: BoxFit.contain,
                  // The mark carries the brand; the label above says what this
                  // screen is, so the image itself is decoration to a reader.
                  excludeFromSemantics: true,
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
                const SizedBox(height: 40),
                const _LoadingSweep(width: _markWidth),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A slim bar with a segment sweeping back and forth.
///
/// The point of it is honesty: the screen is waiting on real work (token read,
/// profile fetch, route decision), and a still logo cannot say that. It sweeps
/// rather than wrapping around, so there is no seam where the segment jumps.
class _LoadingSweep extends StatefulWidget {
  const _LoadingSweep({required this.width});

  final double width;

  @override
  State<_LoadingSweep> createState() => _LoadingSweepState();
}

class _LoadingSweepState extends State<_LoadingSweep>
    with SingleTickerProviderStateMixin {
  static const Duration _sweep = Duration(milliseconds: 1100);
  static const double _height = 3;
  static const double _segmentFraction = 0.4;

  late final AnimationController _controller = AnimationController(
    duration: _sweep,
    vsync: this,
  );

  late final Animation<double> _position = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_height);

    return SizedBox(
      width: widget.width,
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // A track, so the bar reads as a bar even at the ends of the sweep.
          color: KolabingColors.primary.withValues(alpha: 0.18),
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AnimatedBuilder(
            animation: _position,
            builder: (context, _) => Align(
              // -1 = hard left, 1 = hard right.
              alignment: Alignment(_position.value * 2 - 1, 0),
              child: FractionallySizedBox(
                widthFactor: _segmentFraction,
                // heightFactor matters: without it the height constraint
                // arrives loose, a childless DecoratedBox takes the smallest
                // size it can, and the segment renders 0px tall — the track
                // showed and nothing moved along it.
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: KolabingColors.primary,
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
