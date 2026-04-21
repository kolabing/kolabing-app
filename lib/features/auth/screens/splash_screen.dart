import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../providers/auth_state_provider.dart';

/// Animation durations as per UX spec
const Duration _fadeInDuration = Duration(milliseconds: 200);
const Duration _holdDuration = Duration(milliseconds: 2000);
const Duration _fadeOutDuration = Duration(milliseconds: 300);

/// Splash screen states
enum _SplashPhase {
  /// Initial state, elements fading in
  entering,

  /// Elements fully visible, holding
  holding,

  /// Transitioning to welcome screen
  exiting,
}

/// Splash screen widget
///
/// Displays yellow background with centered black "K" logo
/// and "Kolabing" text below. Navigates to Welcome screen after 2.5 seconds.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Animation controller for fade in (logo + text)
  late final AnimationController _entryController;

  /// Animation controller for exit fade
  late final AnimationController _exitController;

  /// Opacity animation for entry
  late final Animation<double> _opacityAnimation;

  /// Scale animation for entry (0.9 -> 1.0)
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

  void _configureSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.primary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _initializeAnimations() {
    // Entry animation controller (fade in + scale)
    _entryController = AnimationController(
      duration: _fadeInDuration,
      vsync: this,
    );

    // Exit animation controller
    _exitController = AnimationController(
      duration: _fadeOutDuration,
      vsync: this,
    );

    // Opacity animation (0 -> 1)
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Scale animation (0.9 -> 1.0)
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Exit fade animation (1 -> 0)
    _exitOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Future<void> _startSplashSequence() async {
    final initializationFuture = ref
        .read(splashStateProvider.notifier)
        .initialize();

    // Phase 1: Entry animation (0-200ms)
    await _entryController.forward();

    if (!mounted) return;
    setState(() => _phase = _SplashPhase.holding);

    // Phase 2: Hold (200-2200ms)
    await Future<void>.delayed(_holdDuration);

    if (!mounted) return;
    setState(() => _phase = _SplashPhase.exiting);

    // Phase 3: Exit animation (2200-2500ms)
    await _exitController.forward();

    if (!mounted) return;

    final route = await initializationFuture;
    if (!mounted) return;
    context.go(route);
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
      backgroundColor: KolabingColors.primary,
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
          label: 'Kolabing - Loading application',
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Black "K" logo
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: Text(
                      'K',
                      style: GoogleFonts.rubik(
                        fontSize: 80,
                        fontWeight: FontWeight.w800,
                        color: KolabingColors.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // "Kolabing" text
                Text(
                  'Kolabing',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: KolabingColors.onPrimary,
                    letterSpacing: 1.0,
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
