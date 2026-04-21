import 'city.dart';

/// Search result for the business location autocomplete.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.formattedAddress,
    required this.city,
    this.subtitle,
    this.country,
    this.latitude,
    this.longitude,
    this.cityId,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      PlaceSuggestion(
        placeId: json['place_id']?.toString() ?? '',
        title: json['title']?.toString() ??
            json['main_text']?.toString() ??
            json['formatted_address']?.toString() ??
            '',
        subtitle: json['subtitle']?.toString() ?? json['secondary_text']?.toString(),
        formattedAddress: json['formatted_address']?.toString() ??
            json['description']?.toString() ??
            '',
        city: json['city']?.toString() ?? '',
        country: json['country']?.toString(),
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        cityId: json['city_id']?.toString(),
      );

  factory PlaceSuggestion.fromCity(OnboardingCity city) => PlaceSuggestion(
        placeId: 'city:${city.id}',
        title: city.name,
        subtitle: city.country,
        formattedAddress: city.country == null ? city.name : '${city.name}, ${city.country}',
        city: city.name,
        country: city.country,
        cityId: city.id,
      );

  final String placeId;
  final String title;
  final String? subtitle;
  final String formattedAddress;
  final String city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? cityId;

  String get displaySubtitle {
    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      return subtitle!;
    }
    if (country != null && country!.trim().isNotEmpty && country != city) {
      return country!;
    }
    return formattedAddress;
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'formatted_address': formattedAddress,
        'city': city,
        if (country != null) 'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (cityId != null) 'city_id': cityId,
      };

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
