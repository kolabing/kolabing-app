import 'dart:convert';
import 'dart:typed_data';

enum OnboardingPhotoSource { upload, googleImported, hosted }

class OnboardingPhotoAttribution {
  const OnboardingPhotoAttribution({
    required this.displayName,
    this.uri,
    this.photoUri,
  });

  factory OnboardingPhotoAttribution.fromJson(Map<String, dynamic> json) =>
      OnboardingPhotoAttribution(
        displayName: json['display_name']?.toString() ?? 'Unknown source',
        uri: json['uri']?.toString(),
        photoUri: json['photo_uri']?.toString(),
      );

  final String displayName;
  final String? uri;
  final String? photoUri;

  Map<String, dynamic> toJson() => {
    'display_name': displayName,
    if (uri != null) 'uri': uri,
    if (photoUri != null) 'photo_uri': photoUri,
  };
}

/// A venue photo collected during onboarding.
///
/// The final payload preserves ordering and sends one of:
/// - Google imported `resource_name`
/// - Uploaded local image as `data:image/...;base64,...`
/// - Existing hosted image URL
class OnboardingPhoto {
  const OnboardingPhoto({
    required String base64,
    required String fileName,
    required String mimeType,
  }) : this._(
         id: fileName,
         source: OnboardingPhotoSource.upload,
         base64: base64,
         fileName: fileName,
         mimeType: mimeType,
       );

  const OnboardingPhoto._({
    required this.id,
    required this.source,
    this.base64,
    this.fileName,
    this.mimeType,
    this.resourceName,
    this.previewUrl,
    this.remoteUrl,
    this.width,
    this.height,
    this.authorAttributions = const [],
  });

  factory OnboardingPhoto.upload({
    required String id,
    required String base64,
    required String fileName,
    required String mimeType,
  }) => OnboardingPhoto._(
    id: id,
    source: OnboardingPhotoSource.upload,
    base64: base64,
    fileName: fileName,
    mimeType: mimeType,
  );

  factory OnboardingPhoto.googleImported({
    required String resourceName,
    required String previewUrl,
    int? width,
    int? height,
    List<OnboardingPhotoAttribution> authorAttributions = const [],
  }) => OnboardingPhoto._(
    id: resourceName,
    source: OnboardingPhotoSource.googleImported,
    resourceName: resourceName,
    previewUrl: previewUrl,
    width: width,
    height: height,
    authorAttributions: authorAttributions,
  );

  factory OnboardingPhoto.hosted({required String remoteUrl}) =>
      OnboardingPhoto._(
        id: remoteUrl,
        source: OnboardingPhotoSource.hosted,
        remoteUrl: remoteUrl,
        previewUrl: remoteUrl,
      );

  final String id;
  final OnboardingPhotoSource source;
  final String? base64;
  final String? fileName;
  final String? mimeType;
  final String? resourceName;
  final String? previewUrl;
  final String? remoteUrl;
  final int? width;
  final int? height;
  final List<OnboardingPhotoAttribution> authorAttributions;

  bool get isUploaded => source == OnboardingPhotoSource.upload;
  bool get isGoogleImported => source == OnboardingPhotoSource.googleImported;
  bool get isHosted => source == OnboardingPhotoSource.hosted;

  String get dataUri => 'data:${mimeType ?? 'image/jpeg'};base64,$base64';

  String get payloadValue {
    switch (source) {
      case OnboardingPhotoSource.upload:
        return dataUri;
      case OnboardingPhotoSource.googleImported:
        return resourceName ?? '';
      case OnboardingPhotoSource.hosted:
        return remoteUrl ?? '';
    }
  }

  Uint8List? get memoryBytes {
    if (base64 == null) return null;
    return base64Decode(base64!);
  }

  OnboardingPhoto copyWith({
    String? id,
    OnboardingPhotoSource? source,
    String? base64,
    String? fileName,
    String? mimeType,
    String? resourceName,
    String? previewUrl,
    String? remoteUrl,
    int? width,
    int? height,
    List<OnboardingPhotoAttribution>? authorAttributions,
  }) => OnboardingPhoto._(
    id: id ?? this.id,
    source: source ?? this.source,
    base64: base64 ?? this.base64,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    resourceName: resourceName ?? this.resourceName,
    previewUrl: previewUrl ?? this.previewUrl,
    remoteUrl: remoteUrl ?? this.remoteUrl,
    width: width ?? this.width,
    height: height ?? this.height,
    authorAttributions: authorAttributions ?? this.authorAttributions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.name,
    if (base64 != null) 'base64': base64,
    if (fileName != null) 'file_name': fileName,
    if (mimeType != null) 'mime_type': mimeType,
    if (resourceName != null) 'resource_name': resourceName,
    if (previewUrl != null) 'preview_url': previewUrl,
    if (remoteUrl != null) 'remote_url': remoteUrl,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (authorAttributions.isNotEmpty)
      'author_attributions': authorAttributions
          .map((item) => item.toJson())
          .toList(),
  };
}
