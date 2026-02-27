/// Event reward model for spin-the-wheel prizes
class EventReward {
  const EventReward({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.totalQuantity,
    required this.remainingQuantity,
    required this.probability,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventReward.fromJson(Map<String, dynamic> json) {
    return EventReward(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      totalQuantity: json['total_quantity'] as int,
      remainingQuantity: json['remaining_quantity'] as int,
      probability: (json['probability'] as num).toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String eventId;
  final String name;
  final String? description;
  final int totalQuantity;
  final int remainingQuantity;
  final double probability;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Check if reward is expired
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Check if reward is in stock
  bool get isInStock => remainingQuantity > 0;

  /// Check if reward is available (in stock and not expired)
  bool get isAvailable => isInStock && !isExpired;

  /// Get probability as percentage string
  String get probabilityPercent => '${(probability * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'name': name,
        if (description != null) 'description': description,
        'total_quantity': totalQuantity,
        'remaining_quantity': remainingQuantity,
        'probability': probability,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  EventReward copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    int? totalQuantity,
    int? remainingQuantity,
    double? probability,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      EventReward(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        description: description ?? this.description,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        remainingQuantity: remainingQuantity ?? this.remainingQuantity,
        probability: probability ?? this.probability,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
