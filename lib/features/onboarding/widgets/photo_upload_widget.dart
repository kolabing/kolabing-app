import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';

/// Photo upload widget for profile picture
class PhotoUploadWidget extends StatefulWidget {
  const PhotoUploadWidget({
    required this.onPhotoSelected,
    super.key,
    this.photoBase64,
    this.onPhotoRemoved,
  });

  /// Current photo as base64 string
  final String? photoBase64;

  /// Callback when photo is selected
  final void Function(File file) onPhotoSelected;

  /// Callback when photo is removed
  final VoidCallback? onPhotoRemoved;

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        // Check file size (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image must be less than 5MB'),
                backgroundColor: KolabingColors.error,
              ),
            );
          }
          return;
        }

        widget.onPhotoSelected(file);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select image'),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
    }
  }

  void _showOptions() {
    if (widget.photoBase64 == null) {
      _pickImage();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Change Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: KolabingColors.error),
              title: const Text(
                'Remove Photo',
                style: TextStyle(color: KolabingColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onPhotoRemoved?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTap: _showOptions,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KolabingColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KolabingColors.border,
                style: widget.photoBase64 == null
                    ? BorderStyle.none
                    : BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                // Photo circle or placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.photoBase64 != null
                        ? Colors.transparent
                        : KolabingColors.surface,
                    border: Border.all(
                      color: widget.photoBase64 != null
                          ? KolabingColors.primary
                          : KolabingColors.border,
                      width: 2,
                      style: widget.photoBase64 != null
                          ? BorderStyle.solid
                          : BorderStyle.none,
                    ),
                    image: widget.photoBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(widget.photoBase64!),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.photoBase64 == null
                      ? const Icon(
                          LucideIcons.camera,
                          size: 32,
                          color: KolabingColors.textTertiary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Label
                Text(
                  widget.photoBase64 == null ? 'Add photo (optional)' : 'Tap to change',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
