import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// What a community is looking for in a collaboration.
enum NeedType {
  venue,
  foodDrink,
  sponsor,
  products,
  discount,
  other;

  String get displayName {
    switch (this) {
      case NeedType.venue:
        return 'Venue';
      case NeedType.foodDrink:
        return 'Food & Drink';
      case NeedType.sponsor:
        return 'Sponsor';
      case NeedType.products:
        return 'Products';
      case NeedType.discount:
        return 'Discount';
      case NeedType.other:
        return 'Other';
    }
  }

  String toApiValue() {
    switch (this) {
      case NeedType.venue:
        return 'venue';
      case NeedType.foodDrink:
        return 'food_drink';
      case NeedType.sponsor:
        return 'sponsor';
      case NeedType.products:
        return 'products';
      case NeedType.discount:
        return 'discount';
      case NeedType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case NeedType.venue:
        return LucideIcons.building2;
      case NeedType.foodDrink:
        return LucideIcons.utensils;
      case NeedType.sponsor:
        return LucideIcons.coins;
      case NeedType.products:
        return LucideIcons.gift;
      case NeedType.discount:
        return LucideIcons.percent;
      case NeedType.other:
        return LucideIcons.moreHorizontal;
    }
  }

  static NeedType fromString(String value) {
    switch (value) {
      case 'venue':
        return NeedType.venue;
      case 'food_drink':
        return NeedType.foodDrink;
      case 'sponsor':
        return NeedType.sponsor;
      case 'products':
        return NeedType.products;
      case 'discount':
        return NeedType.discount;
      case 'other':
        return NeedType.other;
      default:
        return NeedType.other;
    }
  }
}
