import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../providers/checkin_provider.dart';

/// QR Scanner screen for attendees to check in to events
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrData = barcode.rawValue!;

    // Validate QR format (should be a check-in token)
    if (!_isValidCheckinToken(qrData)) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    // Stop scanning
    await _controller?.stop();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Process check-in
    await _processCheckIn(qrData);
  }

  bool _isValidCheckinToken(String data) {
    // Check if it's a valid UUID or token format
    // Accept any non-empty string for now, backend will validate
    return data.isNotEmpty && data.length >= 10;
  }

  Future<void> _processCheckIn(String token) async {
    final success = await ref.read(checkinProvider.notifier).checkIn(token);

    if (!mounted) return;

    if (success) {
      final checkinState = ref.read(checkinProvider);
      _showSuccessDialog(checkinState.checkin?.eventName ?? 'Event');
    } else {
      final error = ref.read(checkinProvider).error;
      _showErrorDialog(error ?? 'Failed to check in');
    }
  }

  void _showSuccessDialog(String eventName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 40,
                  color: KolabingColors.success,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                'Check-in Successful!',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'You have checked in to',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                eventName,
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close scanner
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 40,
                  color: KolabingColors.error,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                'Check-in Failed',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                error,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close scanner
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KolabingColors.textSecondary,
                        side: const BorderSide(color: KolabingColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _retryScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KolabingColors.primary,
                        foregroundColor: KolabingColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Try Again'),
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

  void _retryScanning() {
    Navigator.of(context).pop(); // Close error dialog
    setState(() {
      _isProcessing = false;
      _hasScanned = false;
    });
    ref.read(checkinProvider.notifier).reset();
    _controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: KolabingColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    LucideIcons.x,
                    color: KolabingColors.textOnDark,
                  ),
                ),
                Text(
                  'Scan QR Code',
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textOnDark,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Scanner
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera view
                    MobileScanner(
                      controller: _controller,
                      onDetect: _handleBarcode,
                    ),

                    // Scanning overlay
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isProcessing
                              ? KolabingColors.success
                              : KolabingColors.primary,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    // Corner markers
                    _buildCornerMarkers(),

                    // Processing indicator
                    if (checkinState.isLoading)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: KolabingColors.primary,
                              ),
                              const SizedBox(height: KolabingSpacing.md),
                              Text(
                                'Checking in...',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  color: KolabingColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Point your camera at the event QR code',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textOnDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  'The QR code will be displayed by the event organizer',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: KolabingColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildCornerMarkers() {
    const double size = 30;
    const double thickness = 4;
    const color = KolabingColors.primary;

    return Stack(
      children: [
        // Top left
        Positioned(
          top: 10,
          left: 10,
          child: _Corner(
            size: size,
            thickness: thickness,
            color: color,
            position: _CornerPosition.topLeft,
          ),
        ),
        // Top right
        Positioned(
          top: 10,
          right: 10,
          child: _Corner(
            size: size,
            thickness: thickness,
            color: color,
            position: _CornerPosition.topRight,
          ),
        ),
        // Bottom left
        Positioned(
          bottom: 10,
          left: 10,
          child: _Corner(
            size: size,
            thickness: thickness,
            color: color,
            position: _CornerPosition.bottomLeft,
          ),
        ),
        // Bottom right
        Positioned(
          bottom: 10,
          right: 10,
          child: _Corner(
            size: size,
            thickness: thickness,
            color: color,
            position: _CornerPosition.bottomRight,
          ),
        ),
      ],
    );
  }
}

enum _CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _Corner extends StatelessWidget {
  const _Corner({
    required this.size,
    required this.thickness,
    required this.color,
    required this.position,
  });

  final double size;
  final double thickness;
  final Color color;
  final _CornerPosition position;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          thickness: thickness,
          color: color,
          position: position,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.thickness,
    required this.color,
    required this.position,
  });

  final double thickness;
  final Color color;
  final _CornerPosition position;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
