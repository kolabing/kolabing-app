/// What a community can deliver in return for a collaboration.
enum DeliverableType {
  socialMedia,
  eventActivation,
  productPlacement,
  communityReach,
  reviewFeedback;

  String get displayName {
    switch (this) {
      case DeliverableType.socialMedia:
        return 'Social Media';
      case DeliverableType.eventActivation:
        return 'Event Activation';
      case DeliverableType.productPlacement:
        return 'Product Placement';
      case DeliverableType.communityReach:
        return 'Community Reach';
      case DeliverableType.reviewFeedback:
        return 'Review & Feedback';
    }
  }

  String get subtitle {
    switch (this) {
      case DeliverableType.socialMedia:
        return 'Posts, stories, reels featuring your brand';
      case DeliverableType.eventActivation:
        return 'Brand activations at community events';
      case DeliverableType.productPlacement:
        return 'Product showcases during activities';
      case DeliverableType.communityReach:
        return 'Access to engaged community audience';
      case DeliverableType.reviewFeedback:
        return 'Honest reviews and user feedback';
    }
  }

  String toApiValue() {
    switch (this) {
      case DeliverableType.socialMedia:
        return 'social_media';
      case DeliverableType.eventActivation:
        return 'event_activation';
      case DeliverableType.productPlacement:
        return 'product_placement';
      case DeliverableType.communityReach:
        return 'community_reach';
      case DeliverableType.reviewFeedback:
        return 'review_feedback';
    }
  }

  static DeliverableType fromString(String value) {
    switch (value) {
      case 'social_media':
        return DeliverableType.socialMedia;
      case 'event_activation':
        return DeliverableType.eventActivation;
      case 'product_placement':
        return DeliverableType.productPlacement;
      case 'community_reach':
        return DeliverableType.communityReach;
      case 'review_feedback':
        return DeliverableType.reviewFeedback;
      default:
        return DeliverableType.socialMedia;
    }
  }
}
