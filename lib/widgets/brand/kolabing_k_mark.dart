import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../l10n/app_localizations.dart';

/// The K mark's asset. One PNG for every use: the fill can never disagree with
/// the letter's shape, and every surface tints the same alpha.
const String _kMarkAsset = 'assets/brand/kolabing-k-mark.png';

/// One fill of the mark, bottom to top, when the mark drives itself.
///
/// Shorter than the splash's 1200ms: on the splash the fill IS the loading
/// indicator and has to last, here it is an entrance and has to get out of the
/// way.
const Duration _entranceFillDuration = Duration(milliseconds: 900);

/// How long the waterline takes to travel one wavelength. Deliberately not a
/// multiple of the fill: if the two lined up, the wave would freeze at the same
/// shape on every play.
const Duration _waveDuration = Duration(milliseconds: 2300);

/// The unfilled part of the mark. Present enough to read as the letter, dim
/// enough that the fill line is the thing you watch.
const double _defaultEmptyOpacity = 0.22;

/// The Kolabing K, drawn twice: dim for the part still empty, full-strength for
/// the part the fill has reached.
///
/// The bright copy is clipped to a wavy waterline that rises with [fill], which
/// is what makes it read as filling rather than as a wipe.
///
/// This is the *painted* mark — it holds no controller and animates nothing on
/// its own. Feed it a [fill] and a [phase] from whatever already knows how far
/// along the work is (the splash drives it from real initialisation progress);
/// for a mark that just plays its entrance and settles, use
/// [AnimatedKolabingKMark].
class KolabingKMark extends StatelessWidget {
  const KolabingKMark({
    super.key,
    required this.width,
    required this.fill,
    required this.phase,
    this.color,
    this.emptyOpacity = _defaultEmptyOpacity,
  });

  /// The mark's rendered width; the height follows the asset (it is all but
  /// square).
  final double width;

  /// 0 = empty, 1 = full.
  final double fill;

  /// 0..1, one full wavelength of the waterline's travel.
  final double phase;

  /// Ink for the whole mark. Null keeps the asset's own yellow — right on
  /// black, wrong on the yellow app bar, where the K has to be dark to exist
  /// at all.
  final Color? color;

  /// Opacity of the not-yet-filled part.
  final double emptyOpacity;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? KolabingColors.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        // The empty vessel.
        Image.asset(
          _kMarkAsset,
          width: width,
          fit: BoxFit.contain,
          color: tint.withValues(alpha: emptyOpacity),
          // srcIn, so the tint replaces the mark's own yellow inside its alpha
          // rather than painting a rectangle over it.
          colorBlendMode: BlendMode.srcIn,
          excludeFromSemantics: true,
        ),
        // The filled part.
        ClipPath(
          clipper: _WaterlineClipper(fill: fill, phase: phase),
          child: Image.asset(
            _kMarkAsset,
            width: width,
            fit: BoxFit.contain,
            color: color,
            colorBlendMode: color == null ? null : BlendMode.srcIn,
            excludeFromSemantics: true,
          ),
        ),
      ],
    );
  }
}

/// The K mark that fills itself once, then holds.
///
/// This is the brand's stand-in for a logo image everywhere outside the splash:
/// the app bar and the auth screens. It plays the same waterline fill the
/// splash does — once, on the way in — and then stops ticking entirely, so a
/// logo that sits on screen all session costs nothing to keep there.
///
/// Honours the platform's "reduce motion" setting by starting full.
class AnimatedKolabingKMark extends StatefulWidget {
  const AnimatedKolabingKMark({
    super.key,
    required this.width,
    this.color,
    this.duration = _entranceFillDuration,
  });

  /// The mark's rendered width.
  final double width;

  /// Ink for the mark; null keeps the asset's own yellow.
  final Color? color;

  /// How long one fill takes.
  final Duration duration;

  @override
  State<AnimatedKolabingKMark> createState() => _AnimatedKolabingKMarkState();
}

class _AnimatedKolabingKMarkState extends State<AnimatedKolabingKMark>
    with TickerProviderStateMixin {
  late final AnimationController _fillController = AnimationController(
    duration: widget.duration,
    vsync: this,
  );

  /// The waterline's travel, independent of the fill. Runs only while the mark
  /// is filling — a finished mark has a flat waterline, so there is nothing for
  /// it to move.
  late final AnimationController _waveController = AnimationController(
    duration: _waveDuration,
    vsync: this,
  );

  /// Eased fill, so the level slows as it reaches the top.
  late final Animation<double> _fill = CurvedAnimation(
    parent: _fillController,
    curve: Curves.easeInOutCubic,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is only readable from here down, and the answer decides
    // whether there is an entrance at all.
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fillController.value = 1;
      return;
    }
    _waveController.repeat();
    _fillController.forward().whenCompleteOrCancel(() {
      // Stop the ticker rather than leave it repeating behind a full mark: no
      // more frames, no more repaints, for the rest of the session.
      if (mounted) _waveController.stop();
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).kolabingLogoSemanticLabel,
    image: true,
    child: AnimatedBuilder(
      animation: Listenable.merge([_fill, _waveController]),
      builder: (context, _) => KolabingKMark(
        width: widget.width,
        fill: _fill.value,
        phase: _waveController.value,
        color: widget.color,
      ),
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

  /// Peak-to-trough is twice this. Small on purpose: a tall wave would read as
  /// a wobble in the letter itself.
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
