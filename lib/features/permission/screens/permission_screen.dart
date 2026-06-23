import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/kolabing_button.dart';
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
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.appBackground,
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
      backgroundColor: context.colors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Small icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 20,
                  color: context.colors.amber,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Allow Kolabing to work better',
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Location helps us show nearby kolabs.\nNotifications keep you updated.',
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  color: context.colors.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Permission rows
              _buildPermissionRow(
                icon: LucideIcons.mapPin,
                title: 'Location',
                subtitle: 'Nearby kolabs',
                isGranted: _locationGranted,
                isLoading: _isRequestingLocation,
                onRequest: _requestLocation,
              ),
              Container(height: 1, color: context.colors.hairline),
              _buildPermissionRow(
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: 'Messages & updates',
                isGranted: _notificationGranted,
                isLoading: _isRequestingNotification,
                onRequest: _requestNotification,
              ),

              const Spacer(flex: 3),

              // Continue button
              KolabingButton(
                label: 'Continue',
                onPressed: _continue,
                variant: KolabingButtonVariant.primary,
                size: KolabingButtonSize.compact,
              ),
              const SizedBox(height: 14),

              // Helper text
              Text(
                'You can change this later in settings.',
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.muted,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isLoading,
    required VoidCallback onRequest,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        // Icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.colors.hairline,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: context.colors.ink),
        ),
        const SizedBox(width: 14),

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
                  color: context.colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.muted,
                ),
              ),
            ],
          ),
        ),

        // Action
        if (isGranted)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.colors.xpGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 15, color: Colors.white),
          )
        else if (isLoading)
          SizedBox(
            width: 28,
            height: 28,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
              ),
            ),
          )
        else
          GestureDetector(
            onTap: onRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: KolabingColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Allow',
                style: KolabingTextStyles.button.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.1,
                  color: KolabingColors.onPrimary,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
