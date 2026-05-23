import '../../../config/constants/api.dart';
import 'onboarding_photo.dart';
import 'place_suggestion.dart';

class PlaceDetailsImport {
  const PlaceDetailsImport({
    required this.name,
    required this.categories,
    required this.primaryVenue,
    this.about,
    this.businessType,
    this.cityId,
    this.cityName,
    this.phoneNumber,
    this.website,
  });

  factory PlaceDetailsImport.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return PlaceDetailsImport(
      name: data['name']?.toString() ?? '',
      about: data['about']?.toString(),
      businessType: data['business_type']?.toString(),
      categories: (data['categories'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      cityId: data['city_id']?.toString(),
      cityName: data['city_name']?.toString(),
      phoneNumber: data['phone_number']?.toString(),
      website: data['website']?.toString(),
      primaryVenue: ImportedPrimaryVenue.fromJson(
        data['primary_venue'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String name;
  final String? about;
  final String? businessType;
  final List<String> categories;
  final String? cityId;
  final String? cityName;
  final String? phoneNumber;
  final String? website;
  final ImportedPrimaryVenue primaryVenue;

  List<String> get allCategorySlugs {
    final slugs = <String>[
      if (businessType != null && businessType!.trim().isNotEmpty)
        businessType!.trim(),
      ...categories.map((item) => item.trim()),
    ];
    return slugs.toSet().toList(growable: false);
  }

  PlaceSuggestion toPlaceSuggestion() => PlaceSuggestion(
    placeId: primaryVenue.placeId,
    title: primaryVenue.name,
    subtitle: primaryVenue.formattedAddress,
    formattedAddress: primaryVenue.formattedAddress,
    city: primaryVenue.city,
    country: primaryVenue.country,
    latitude: primaryVenue.latitude,
    longitude: primaryVenue.longitude,
    cityId: cityId,
  );
}

class ImportedPrimaryVenue {
  const ImportedPrimaryVenue({
    required this.name,
    required this.placeId,
    required this.formattedAddress,
    required this.city,
    this.venueType,
    this.capacity,
    this.country,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.website,
    this.openingHours = const [],
    this.description,
    this.priceLevel,
    this.rating,
    this.userRatingsTotal,
    this.googlePlaceTypes = const [],
    this.photos = const [],
  });

  factory ImportedPrimaryVenue.fromJson(Map<String, dynamic> json) =>
      ImportedPrimaryVenue(
        name: json['name']?.toString() ?? '',
        venueType: json['venue_type']?.toString(),
        capacity: _parseInt(json['capacity']),
        placeId: json['place_id']?.toString() ?? '',
        formattedAddress: json['formatted_address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        country: json['country']?.toString(),
        latitude: PlaceSuggestion.tryParseDouble(json['latitude']),
        longitude: PlaceSuggestion.tryParseDouble(json['longitude']),
        phoneNumber: json['phone_number']?.toString(),
        website: json['website']?.toString(),
        openingHours: (json['opening_hours'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList(),
        description: json['description']?.toString(),
        priceLevel: json['price_level']?.toString(),
        rating: PlaceSuggestion.tryParseDouble(json['rating']),
        userRatingsTotal: _parseInt(json['user_ratings_total']),
        googlePlaceTypes:
            (json['google_place_types'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList(),
        photos: (json['photos'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  ImportedGooglePhoto.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  final String name;
  final String? venueType;
  final int? capacity;
  final String placeId;
  final String formattedAddress;
  final String city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? website;
  final List<String> openingHours;
  final String? description;
  final String? priceLevel;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> googlePlaceTypes;
  final List<ImportedGooglePhoto> photos;
}

class ImportedGooglePhoto {
  const ImportedGooglePhoto({
    required this.resourceName,
    required this.previewUrl,
    this.width,
    this.height,
    this.authorAttributions = const [],
  });

  factory ImportedGooglePhoto.fromJson(Map<String, dynamic> json) =>
      ImportedGooglePhoto(
        resourceName: json['resource_name']?.toString() ?? '',
        previewUrl: _normalizePreviewUrl(json['preview_url']?.toString()),
        width: _parseInt(json['width']),
        height: _parseInt(json['height']),
        authorAttributions:
            (json['author_attributions'] as List<dynamic>? ?? const [])
                .map(
                  (item) => OnboardingPhotoAttribution.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );

  final String resourceName;
  final String previewUrl;
  final int? width;
  final int? height;
  final List<OnboardingPhotoAttribution> authorAttributions;
}

String _normalizePreviewUrl(String? previewUrl) {
  final raw = previewUrl?.trim() ?? '';
  if (raw.isEmpty) return '';

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    return raw;
  }

  final apiBaseUri = Uri.parse('${ApiConfig.baseUrl}/');
  return apiBaseUri.resolve(raw).toString();
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
