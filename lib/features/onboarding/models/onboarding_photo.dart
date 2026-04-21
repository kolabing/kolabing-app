/// A photo collected during onboarding, stored as base64 until registration.
class OnboardingPhoto {
  const OnboardingPhoto({
    required this.base64,
    required this.fileName,
    required this.mimeType,
  });

  final String base64;
  final String fileName;
  final String mimeType;

  String get dataUri => 'data:$mimeType;base64,$base64';

  Map<String, dynamic> toJson() => {
        'base64': base64,
        'file_name': fileName,
        'mime_type': mimeType,
      };

  OnboardingPhoto copyWith({
    String? base64,
    String? fileName,
    String? mimeType,
  }) =>
      OnboardingPhoto(
        base64: base64 ?? this.base64,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
      );
}
