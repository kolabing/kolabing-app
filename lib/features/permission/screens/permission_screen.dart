import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../services/permission_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Permission request screen shown once after registration/login.
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({required this.destination, super.key});

  final String destination;

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
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
      SystemUiOverlayStyle(
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
    if (status.isPermanentlyDenied || status.isDenied) {
      _showSettingsDialog('Location');
    }
  }

  Future<void> _requestNotification() async {
    setState(() => _isRequestingNotification = true);
    final status = await _service.requestNotificationPermission();
    if (status.isGranted) {
      await ref.read(authProvider.notifier).syncPushPermissionGrant();
    }
    if (!mounted) return;
    setState(() {
      _notificationGranted = status.isGranted;
      _isRequestingNotification = false;
    });
    if (status.isPermanentlyDenied || status.isDenied) {
      _showSettingsDialog('Notification');
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$permissionName Permission',
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '$permissionName access was denied. You can enable it from your device settings.',
          style: KolabingTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: KolabingTextStyles.button.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.openSettings();
            },
            child: Text(
              'Open Settings',
              style: KolabingTextStyles.button.copyWith(
                color: context.colors.primary,
              ),
            ),
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
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: context.colors.background,
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
                  color: const Color(0xFFFFD861).withValues(alpha: 0.15),
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
              style: KolabingTextStyles.bodyLarge.copyWith(
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
                style: KolabingTextStyles.bodySmall.copyWith(
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
                  'Find nearby kolab opportunities and connect with local businesses and communities.',
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
                  'Get notified about new applications, messages, and kolab updates.',
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
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: KolabingTextStyles.button.copyWith(
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),

            // Help text
            Text(
              'You can change these later in your device settings.',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
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

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
    required bool isLoading,
    required VoidCallback onRequest,
  }) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isGranted
            ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
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
            color: iconColor.withValues(alpha: 0.12),
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
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
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
                style: KolabingTextStyles.button.copyWith(fontSize: 13),
              ),
            ),
          ),
      ],
    ),
  );
}
