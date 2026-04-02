import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Type of venue being promoted by a business.
enum VenueType {
  restaurant,
  cafe,
  barLounge,
  hotel,
  coworking,
  sportsFacility,
  eventSpace,
  rooftop,
  beachClub,
  retailStore,
  other;

  String get displayName {
    switch (this) {
      case VenueType.restaurant:
        return 'Restaurant';
      case VenueType.cafe:
        return 'Cafe';
      case VenueType.barLounge:
        return 'Bar & Lounge';
      case VenueType.hotel:
        return 'Hotel';
      case VenueType.coworking:
        return 'Coworking';
      case VenueType.sportsFacility:
        return 'Sports Facility';
      case VenueType.eventSpace:
        return 'Event Space';
      case VenueType.rooftop:
        return 'Rooftop';
      case VenueType.beachClub:
        return 'Beach Club';
      case VenueType.retailStore:
        return 'Retail Store';
      case VenueType.other:
        return 'Other';
    }
  }

  String toApiValue() {
    switch (this) {
      case VenueType.restaurant:
        return 'restaurant';
      case VenueType.cafe:
        return 'cafe';
      case VenueType.barLounge:
        return 'bar_lounge';
      case VenueType.hotel:
        return 'hotel';
      case VenueType.coworking:
        return 'coworking';
      case VenueType.sportsFacility:
        return 'sports_facility';
      case VenueType.eventSpace:
        return 'event_space';
      case VenueType.rooftop:
        return 'rooftop';
      case VenueType.beachClub:
        return 'beach_club';
      case VenueType.retailStore:
        return 'retail_store';
      case VenueType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case VenueType.restaurant:
        return LucideIcons.utensils;
      case VenueType.cafe:
        return LucideIcons.coffee;
      case VenueType.barLounge:
        return LucideIcons.wine;
      case VenueType.hotel:
        return LucideIcons.hotel;
      case VenueType.coworking:
        return LucideIcons.laptop;
      case VenueType.sportsFacility:
        return LucideIcons.dumbbell;
      case VenueType.eventSpace:
        return LucideIcons.partyPopper;
      case VenueType.rooftop:
        return LucideIcons.building;
      case VenueType.beachClub:
        return LucideIcons.palmtree;
      case VenueType.retailStore:
        return LucideIcons.store;
      case VenueType.other:
        return LucideIcons.moreHorizontal;
    }
  }

  static VenueType fromString(String value) {
    switch (value) {
      case 'restaurant':
        return VenueType.restaurant;
      case 'cafe':
        return VenueType.cafe;
      case 'bar_lounge':
        return VenueType.barLounge;
      case 'hotel':
        return VenueType.hotel;
      case 'coworking':
        return VenueType.coworking;
      case 'sports_facility':
        return VenueType.sportsFacility;
      case 'event_space':
        return VenueType.eventSpace;
      case 'rooftop':
        return VenueType.rooftop;
      case 'beach_club':
        return VenueType.beachClub;
      case 'retail_store':
        return VenueType.retailStore;
      case 'other':
        return VenueType.other;
      default:
        return VenueType.other;
    }
  }
}
