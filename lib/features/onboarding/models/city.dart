/// City model from GET /cities
class OnboardingCity {
  const OnboardingCity({
    required this.id,
    required this.name,
    this.country,
  });

  factory OnboardingCity.fromJson(Map<String, dynamic> json) => OnboardingCity(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        country: json['country']?.toString(),
      );

  final String id;
  final String name;
  final String? country;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (country != null) 'country': country,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingCity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OnboardingCity(id: $id, name: $name, country: $country)';
}
