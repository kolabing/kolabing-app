import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/challenge.dart';

/// The camera step of a challenge (#183).
///
/// This is the piece that stops the app being a receipt printer. The challenge
/// happens in the room either way; what changes is that the app is now *in* the
/// moment rather than recording that it occurred afterwards.
///
/// Deliberately built on `image_picker`, which opens the OS camera, rather than
/// the `camera` package and a custom viewfinder. A bespoke shutter would grow
/// the App Review surface, the code and the device-specific bug count to buy
/// chrome — and the hook is the photo existing and landing somewhere, not the
/// chrome around taking it.
///
/// Pops with the captured file path, or `null` if the user backed out. Backing
/// out is always available: a challenge must never trap someone whose camera
/// permission is off or whose hardware is misbehaving.
class ChallengeCameraScreen extends StatefulWidget {
  const ChallengeCameraScreen({super.key, required this.challenge});

  final Challenge challenge;

  /// Opens the step and resolves to the captured path, or null when abandoned.
  static Future<String?> open(BuildContext context, Challenge challenge) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChallengeCameraScreen(challenge: challenge),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ChallengeCameraScreen> createState() => _ChallengeCameraScreenState();
}

class _ChallengeCameraScreenState extends State<ChallengeCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _capturedPath;
  bool _busy = false;

  /// Set when the OS refused the camera, so the screen can offer Settings
  /// instead of a button that will silently do nothing again.
  bool _permissionDenied = false;
  bool _failed = false;

  Future<void> _capture() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
      _permissionDenied = false;
    });
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        // Compressed here rather than on the server: these are uploaded over
        // venue wifi, and a 12MP original is the difference between a photo
        // that lands and one that sits in the retry queue all night.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (shot != null) _capturedPath = shot.path;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _permissionDenied = e.code == 'camera_access_denied';
        _failed = !_permissionDenied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  void _retake() => setState(() => _capturedPath = null);

  void _use() => Navigator.of(context).pop(_capturedPath);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final captured = _capturedPath;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.challenge.name,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: captured == null
              ? _Prompt(
                  challenge: widget.challenge,
                  busy: _busy,
                  permissionDenied: _permissionDenied,
                  failed: _failed,
                  onCapture: _capture,
                  onOpenSettings: openAppSettings,
                )
              : _Preview(
                  path: captured,
                  onRetake: _retake,
                  onUse: _use,
                  l10n: l10n,
                ),
        ),
      ),
    );
  }
}

/// Before the shot: what to photograph, and the one button that does it.
class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.challenge,
    required this.busy,
    required this.permissionDenied,
    required this.failed,
    required this.onCapture,
    required this.onOpenSettings,
  });

  final Challenge challenge;
  final bool busy;
  final bool permissionDenied;
  final bool failed;
  final VoidCallback onCapture;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The hint is server copy naming the actual task ("find something yellow").
    // Without it the screen asks for a photo and never says of what.
    final hint = challenge.captureHint ?? challenge.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.camera,
            size: 44,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          challenge.isSolo
              ? l10n.challengeCameraSoloTitle
              : l10n.challengeCameraPairTitle,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.displaySmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        if (hint != null && hint.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        if (permissionDenied) ...[
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            l10n.challengeCameraPermissionBody,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        if (failed) ...[
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            l10n.challengeCameraFailed,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        const Spacer(),
        if (permissionDenied)
          KolabingButton(
            label: l10n.challengeCameraOpenSettings,
            onPressed: () => onOpenSettings(),
            variant: KolabingButtonVariant.primary,
          )
        else
          KolabingButton(
            label: l10n.challengeCameraOpen,
            onPressed: busy ? null : onCapture,
            isLoading: busy,
            variant: KolabingButtonVariant.primary,
          ),
        const SizedBox(height: KolabingSpacing.sm),
        // Always reachable. A challenge that cannot be abandoned is a trap.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

/// After the shot: look at it, keep it or take it again.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.path,
    required this.onRetake,
    required this.onUse,
    required this.l10n,
  });

  final String path;
  final VoidCallback onRetake;
  final VoidCallback onUse;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              width: double.infinity,
              // A file that vanished between capture and build must not throw
              // a red screen over someone's evening.
              errorBuilder: (context, error, stack) => ColoredBox(
                color: context.colors.surfaceVariant,
                child: Center(
                  child: Text(
                    l10n.challengeCameraFailed,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        KolabingButton(
          label: l10n.challengeCameraUse,
          onPressed: onUse,
          variant: KolabingButtonVariant.primary,
        ),
        const SizedBox(height: KolabingSpacing.sm),
        KolabingButton(
          label: l10n.challengeCameraRetake,
          onPressed: onRetake,
          variant: KolabingButtonVariant.secondary,
        ),
      ],
    );
  }
}
