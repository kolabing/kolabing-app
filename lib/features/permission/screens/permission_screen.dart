import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../services/permission_service.dart';

/// Permission request screen shown once after registration/login.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({
    super.key,
    required this.destination,
  });

  final String destination;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final _service = PermissionService.instance;

  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _isRequestingLocation = false;
  bool _isRequestingNotification = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _checkExistingPermissions();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _checkExistingPermissions() async {
    final locationStatus = await _service.checkLocationPermission();
    final notificationStatus = await _service.checkNotificationPermission();
    if (!mounted) return;
    setState(() {
      _locationGranted = locationStatus.isGranted;
      _notificationGranted = notificationStatus.isGranted;
    });
  }

  Future<void> _requestLocation() async {
    setState(() => _isRequestingLocation = true);
    final status = await _service.requestLocationPermission();
    if (!mounted) return;
    setState(() {
      _locationGranted = status.isGranted;
      _isRequestingLocation = false;
    });
    if (status.isPermanentlyDenied) _showSettingsDialog('Location');
  }

  Future<void> _requestNotification() async {
    setState(() => _isRequestingNotification = true);
    final status = await _service.requestNotificationPermission();
    if (!mounted) return;
    setState(() {
      _notificationGranted = status.isGranted;
      _isRequestingNotification = false;
    });
    if (status.isPermanentlyDenied) _showSettingsDialog('Notification');
  }

  void _showSettingsDialog(String permissionName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$permissionName Permission',
          style: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(
          '$permissionName access was denied. You can enable it from your device settings.',
          style: GoogleFonts.openSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.openSettings();
            },
            child: Text('Open Settings',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    await _service.markPermissionScreenShown();
    if (!mounted) return;
    context.go(widget.destination);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.lg),
            children: [
              const SizedBox(height: 60),

              // Shield icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD861).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    size: 40,
                    color: Color(0xFFFFD861),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Title
              Text(
                'ENABLE PERMISSIONS',
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF232323),
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                ),
                child: Text(
                  'To get the best experience, Kolabing needs a few permissions.',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xl),

              // Location Permission Card
              _buildPermissionCard(
                icon: LucideIcons.mapPin,
                iconColor: const Color(0xFF4CAF50),
                title: 'Location',
                description:
                    'Find nearby collaboration opportunities and connect with local businesses and communities.',
                isGranted: _locationGranted,
                isLoading: _isRequestingLocation,
                onRequest: _requestLocation,
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Notification Permission Card
              _buildPermissionCard(
                icon: LucideIcons.bell,
                iconColor: const Color(0xFFFF9800),
                title: 'Notifications',
                description:
                    'Get notified about new applications, messages, and collaboration updates.',
                isGranted: _notificationGranted,
                isLoading: _isRequestingNotification,
                onRequest: _requestNotification,
              ),
              const SizedBox(height: 48),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Help text
              Text(
                'You can change these later in your device settings.',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
    required bool isLoading,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Action button / check
          if (isGranted)
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 18, color: Colors.white),
            )
          else if (isLoading)
            const SizedBox(
              width: 36,
              height: 36,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD861)),
                ),
              ),
            )
          else
            SizedBox(
              width: 72,
              height: 36,
              child: ElevatedButton(
                onPressed: onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD861),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Allow',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
