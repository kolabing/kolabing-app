import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Warm sheet tokens
// ---------------------------------------------------------------------------

const Color _kYellow = Color(0xFFFFE28C);
const Color _kCream = Color(0xFFF6F1E7);
const Color _kInk = Color(0xFF19150F);
const Color _kMuted = Color(0xFF8C8474);

// ---------------------------------------------------------------------------
// WelcomeScreen — Warm sheet direction
// ---------------------------------------------------------------------------

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
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
    final screenWidth = size.width;
    final heroHeight = size.height * 0.40;
    final waveHeight = 130.0 * screenWidth / 402.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _kCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kYellow,
        body: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            children: [
              // Cream sheet background (bottom portion)
              Positioned(
                top: heroHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(color: _kCream),
              ),

              // Wave transition — cream flowing up over yellow hero boundary
              Positioned(
                top: heroHeight - waveHeight + 12,
                left: 0,
                right: 0,
                height: waveHeight,
                child: CustomPaint(
                  painter: _WavePainter(color: _kCream),
                ),
              ),

              // Main layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Yellow hero — logo shifted above centre
                  SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: heroHeight,
                      child: const Align(
                        alignment: Alignment(0, -0.4),
                        child: KolabingLogo(
                          width: 158,
                          variant: KolabingLogoVariant.onYellow,
                        ),
                      ),
                    ),
                  ),

                  // Cream sheet content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(30, 50, 30, 40),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeHeadline(),
                            const SizedBox(height: 28),
                            const _TaglineRow(),
                            const SizedBox(height: 32),
                            _PrimaryCta(onPressed: _onPrimaryCta),
                            const SizedBox(height: 18),
                            Center(
                              child: GestureDetector(
                                onTap: _onLogin,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: _kMuted,
                                      ),
                                      children: const [
                                        TextSpan(text: 'Already in? '),
                                        TextSpan(
                                          text: 'Log in',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kInk,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline — "where / businesses & communities / grow together"
// ---------------------------------------------------------------------------

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: _kInk,
      height: 1.14,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('where', style: style),
        Text('businesses & communities', style: style),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('grow ', style: style),
            _YellowUnderlineText(text: 'together', style: style),
          ],
        ),
      ],
    );
  }
}

/// Renders text with a yellow swash underline behind the baseline.
class _YellowUnderlineText extends StatelessWidget {
  const _YellowUnderlineText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomLeft,
    children: [
      // Yellow swash behind the text
      Positioned(
        bottom: 1,
        left: 0,
        right: 0,
        child: Container(
          height: 9,
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
    final baseStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 3.4,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('MATCH', style: baseStyle.copyWith(color: _kMuted)),
        const SizedBox(width: 6),
        Text('·', style: baseStyle.copyWith(color: Color(0xFFB5914A))),
        const SizedBox(width: 6),
        Text('KOLAB', style: baseStyle.copyWith(color: _kInk)),
        const SizedBox(width: 6),
        Text('·', style: baseStyle.copyWith(color: Color(0xFFB5914A))),
        const SizedBox(width: 6),
        Text('GROW', style: baseStyle.copyWith(color: _kMuted)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Primary CTA — pill, yellow, ink text, arrow
// ---------------------------------------------------------------------------

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Start kolabing',
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: _kYellow,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF141210).withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start kolabing',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, size: 18, color: _kInk),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Wave painter — cream sheet with organic wavy top edge
// ---------------------------------------------------------------------------

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final sx = size.width / 402.0;
    final sy = size.height / 130.0;

    final path = Path()
      ..moveTo(0, 130 * sy)
      ..lineTo(0, 66 * sy)
      ..cubicTo(
        72 * sx, 22 * sy,
        150 * sx, 52 * sy,
        230 * sx, 60 * sy,
      )
      ..cubicTo(
        300 * sx, 67 * sy,
        352 * sx, 34 * sy,
        402 * sx, 50 * sy,
      )
      ..lineTo(402 * sx, 130 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
