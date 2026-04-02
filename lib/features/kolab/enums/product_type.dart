import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Type of product or service being promoted by a business.
enum ProductType {
  foodProduct,
  beverage,
  healthBeauty,
  sportsEquipment,
  fashion,
  techGadget,
  experienceService,
  other;

  String get displayName {
    switch (this) {
      case ProductType.foodProduct:
        return 'Food Product';
      case ProductType.beverage:
        return 'Beverage';
      case ProductType.healthBeauty:
        return 'Health & Beauty';
      case ProductType.sportsEquipment:
        return 'Sports Equipment';
      case ProductType.fashion:
        return 'Fashion';
      case ProductType.techGadget:
        return 'Tech Gadget';
      case ProductType.experienceService:
        return 'Experience / Service';
      case ProductType.other:
        return 'Other';
    }
  }

  String toApiValue() {
    switch (this) {
      case ProductType.foodProduct:
        return 'food_product';
      case ProductType.beverage:
        return 'beverage';
      case ProductType.healthBeauty:
        return 'health_beauty';
      case ProductType.sportsEquipment:
        return 'sports_equipment';
      case ProductType.fashion:
        return 'fashion';
      case ProductType.techGadget:
        return 'tech_gadget';
      case ProductType.experienceService:
        return 'experience_service';
      case ProductType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductType.foodProduct:
        return LucideIcons.apple;
      case ProductType.beverage:
        return LucideIcons.cupSoda;
      case ProductType.healthBeauty:
        return LucideIcons.heart;
      case ProductType.sportsEquipment:
        return LucideIcons.dumbbell;
      case ProductType.fashion:
        return LucideIcons.shirt;
      case ProductType.techGadget:
        return LucideIcons.smartphone;
      case ProductType.experienceService:
        return LucideIcons.sparkles;
      case ProductType.other:
        return LucideIcons.moreHorizontal;
    }
  }

  static ProductType fromString(String value) {
    switch (value) {
      case 'food_product':
        return ProductType.foodProduct;
      case 'beverage':
        return ProductType.beverage;
      case 'health_beauty':
        return ProductType.healthBeauty;
      case 'sports_equipment':
        return ProductType.sportsEquipment;
      case 'fashion':
        return ProductType.fashion;
      case 'tech_gadget':
        return ProductType.techGadget;
      case 'experience_service':
        return ProductType.experienceService;
      case 'other':
        return ProductType.other;
      default:
        return ProductType.other;
    }
  }
}
