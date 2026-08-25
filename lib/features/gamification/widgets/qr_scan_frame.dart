import 'package:flutter/material.dart';

import '../../../config/theme/color_tokens.dart';

/// The four bracket corners drawn over the camera preview.
///
/// Extracted from the scanner screen so the scanner file stays about the scan
/// flow rather than about painting.
class QrScanFrame extends StatelessWidget {
  const QrScanFrame({super.key, this.active = false, this.inset = 10});

  /// Tints the frame with the success colour while a scan is being processed.
  final bool active;

  final double inset;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.colors.success : context.colors.primary;

    return Stack(
      children: [
        for (final position in _CornerPosition.values)
          Positioned(
            top: position.isTop ? inset : null,
            bottom: position.isTop ? null : inset,
            left: position.isLeft ? inset : null,
            right: position.isLeft ? null : inset,
            child: _Corner(color: color, position: position),
          ),
      ],
    );
  }
}

enum _CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get isTop =>
      this == _CornerPosition.topLeft || this == _CornerPosition.topRight;

  bool get isLeft =>
      this == _CornerPosition.topLeft || this == _CornerPosition.bottomLeft;
}

class _Corner extends StatelessWidget {
  const _Corner({required this.color, required this.position});

  static const double _size = 30;
  static const double _thickness = 4;

  final Color color;
  final _CornerPosition position;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, position: position),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color, required this.position});

  final Color color;
  final _CornerPosition position;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _Corner._thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    switch (position) {
      case _CornerPosition.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case _CornerPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case _CornerPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case _CornerPosition.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.position != position;
}
