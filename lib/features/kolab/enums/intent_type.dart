import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The user's intent when creating a new Kolab.
enum IntentType {
  communitySeeking,
  venuePromotion,
  productPromotion;

  String get displayName {
    switch (this) {
      case IntentType.communitySeeking:
        return 'Community Seeking';
      case IntentType.venuePromotion:
        return 'Venue Promotion';
      case IntentType.productPromotion:
        return 'Product Promotion';
    }
  }

  String toApiValue() {
    switch (this) {
      case IntentType.communitySeeking:
        return 'community_seeking';
      case IntentType.venuePromotion:
        return 'venue_promotion';
      case IntentType.productPromotion:
        return 'product_promotion';
    }
  }

  IconData get icon {
    switch (this) {
      case IntentType.communitySeeking:
        return LucideIcons.search;
      case IntentType.venuePromotion:
        return LucideIcons.building2;
      case IntentType.productPromotion:
        // ignore: deprecated_member_use
        return LucideIcons.package;
    }
  }

  /// Total number of steps in the creation flow for this intent type.
  int get totalSteps {
    switch (this) {
      case IntentType.communitySeeking:
        return 6;
      case IntentType.venuePromotion:
        return 7;
      case IntentType.productPromotion:
        return 7;
    }
  }

  static IntentType fromString(String value) {
    switch (value) {
      case 'community_seeking':
        return IntentType.communitySeeking;
      case 'venue_promotion':
        return IntentType.venuePromotion;
      case 'product_promotion':
        return IntentType.productPromotion;
      default:
        return IntentType.communitySeeking;
    }
  }
}
