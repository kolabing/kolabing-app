import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/constants/api.dart';
import '../services/gallery_service.dart';

// =============================================================================
// Gallery Photo Model
// =============================================================================

@immutable
class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    required this.url,
    this.caption,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    final url = _resolveUrl(json);
    return GalleryPhoto(
      id: json['id']?.toString() ?? '',
      url: url,
      caption: json['caption'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  factory GalleryPhoto.fromUrl({
    required String id,
    required String rawUrl,
    String? caption,
    int sortOrder = 0,
  }) => GalleryPhoto(
    id: id,
    url: _normalizeUrl(rawUrl),
    caption: caption,
    sortOrder: sortOrder,
  );

  final String id;
  final String url;
  final String? caption;
  final int sortOrder;
  final DateTime? createdAt;

  static String _resolveUrl(Map<String, dynamic> json) {
    final rawUrl =
        json['url'] as String? ??
        json['photo_url'] as String? ??
        json['file_url'] as String? ??
        json['image_url'] as String? ??
        json['path'] as String? ??
        (json['photo'] is Map<String, dynamic>
            ? (json['photo'] as Map<String, dynamic>)['url'] as String?
            : null) ??
        (json['media'] is Map<String, dynamic>
            ? (json['media'] as Map<String, dynamic>)['url'] as String?
            : null) ??
        '';

    final normalizedUrl = _normalizeUrl(rawUrl);
    debugPrint(
      'GalleryPhoto.fromJson: id=${json['id']}, url=$normalizedUrl, keys=${json.keys.toList()}',
    );
    return normalizedUrl;
  }

  static String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('data:')) return trimmed;

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final origin = Uri.parse(ApiConfig.baseUrl).replace(path: '/');
    return origin.resolve(trimmed).toString();
  }
}

// =============================================================================
// Gallery State
// =============================================================================

@immutable
class GalleryState {
  const GalleryState({
    this.photos = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isDeleting = false,
    this.error,
  });

  final List<GalleryPhoto> photos;
  final bool isLoading;
  final bool isUploading;
  final bool isDeleting;
  final String? error;

  static const int maxPhotos = 10;

  bool get isEmpty => photos.isEmpty;
  bool get canAddMore => photos.length < maxPhotos;

  GalleryState copyWith({
    List<GalleryPhoto>? photos,
    bool? isLoading,
    bool? isUploading,
    bool? isDeleting,
    String? error,
    bool clearError = false,
  }) => GalleryState(
    photos: photos ?? this.photos,
    isLoading: isLoading ?? this.isLoading,
    isUploading: isUploading ?? this.isUploading,
    isDeleting: isDeleting ?? this.isDeleting,
    error: clearError ? null : (error ?? this.error),
  );
}

// =============================================================================
// Gallery Notifier
// =============================================================================

class GalleryNotifier extends Notifier<GalleryState> {
  final ImagePicker _imagePicker = ImagePicker();
  final GalleryService _galleryService = GalleryService();

  @override
  GalleryState build() {
    return const GalleryState();
  }

  /// Load gallery photos from the API
  Future<void> loadGallery() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final photos = await _galleryService.getMyGallery();
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      debugPrint('Gallery load error: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load gallery');
    }
  }

  /// Pick and upload a photo from the given source
  Future<bool> addPhoto(ImageSource source) async {
    if (!state.canAddMore) {
      state = state.copyWith(
        error: 'Maximum ${GalleryState.maxPhotos} photos allowed',
      );
      return false;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return false;

      // Verify file exists
      final file = File(pickedFile.path);
      if (!file.existsSync()) return false;

      state = state.copyWith(isUploading: true, clearError: true);

      await _galleryService.uploadPhoto(filePath: pickedFile.path);

      // Reload the full gallery from API to get correct URLs
      final photos = await _galleryService.getMyGallery();
      state = state.copyWith(photos: photos, isUploading: false);
      return true;
    } catch (e) {
      debugPrint('Gallery add photo error: $e');
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload photo',
      );
      return false;
    }
  }

  /// Remove a photo by ID via the API
  Future<void> removePhoto(String id) async {
    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      await _galleryService.deletePhoto(id);
      state = state.copyWith(
        photos: state.photos.where((p) => p.id != id).toList(),
        isDeleting: false,
      );
    } catch (e) {
      debugPrint('Gallery delete photo error: $e');
      state = state.copyWith(
        isDeleting: false,
        error: 'Failed to delete photo',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// Provider
// =============================================================================

final galleryProvider = NotifierProvider<GalleryNotifier, GalleryState>(
  GalleryNotifier.new,
);
