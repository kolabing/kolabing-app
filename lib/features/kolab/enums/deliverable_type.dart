/// What a community can deliver in return for a collaboration.
///
/// Slugs/order mirror the backend `OfferOptionSeeder`'s `deliverable` kind
/// exactly (kolabing-v2). Closed enum (not a raw String) so call sites get
/// exhaustive switch-checking, same convention as VenueType/ProductType.
enum DeliverableType {
  socialMedia,
  eventActivation,
  productPlacement,
  communityReach,
  reviewFeedback,
  minimumAttendance,
  minimumSpend,
  taggedStories,
  instagramPostReel,
  ugcContent,
  reviews,
  productFeedback,
  communityPhotos,
  newsletterMention,
  longTermPartnership,
  openToIdeas;

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
      case DeliverableType.minimumAttendance:
        return 'Minimum Attendance';
      case DeliverableType.minimumSpend:
        return 'Minimum Revenue / Spend';
      case DeliverableType.taggedStories:
        return 'Tagged Stories';
      case DeliverableType.instagramPostReel:
        return 'Instagram Post or Reel';
      case DeliverableType.ugcContent:
        return 'UGC / Content';
      case DeliverableType.reviews:
        return 'Reviews';
      case DeliverableType.productFeedback:
        return 'Product Feedback';
      case DeliverableType.communityPhotos:
        return 'Community Photos';
      case DeliverableType.newsletterMention:
        return 'Newsletter Mention';
      case DeliverableType.longTermPartnership:
        return 'Long-Term Partnership';
      case DeliverableType.openToIdeas:
        return 'Open to Ideas';
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
      case DeliverableType.minimumAttendance:
        return 'A minimum number of attendees at the event';
      case DeliverableType.minimumSpend:
        return 'A minimum revenue or spend commitment';
      case DeliverableType.taggedStories:
        return 'Stories tagging your brand or venue';
      case DeliverableType.instagramPostReel:
        return 'A dedicated Instagram post or reel';
      case DeliverableType.ugcContent:
        return 'User-generated content featuring your brand';
      case DeliverableType.reviews:
        return 'Public reviews from attendees';
      case DeliverableType.productFeedback:
        return 'Structured feedback on your product';
      case DeliverableType.communityPhotos:
        return 'Photos from the community for your own use';
      case DeliverableType.newsletterMention:
        return 'A mention in the community newsletter';
      case DeliverableType.longTermPartnership:
        return 'Openness to an ongoing partnership';
      case DeliverableType.openToIdeas:
        return 'Open to other ideas the community proposes';
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
      case DeliverableType.minimumAttendance:
        return 'minimum_attendance';
      case DeliverableType.minimumSpend:
        return 'minimum_spend';
      case DeliverableType.taggedStories:
        return 'tagged_stories';
      case DeliverableType.instagramPostReel:
        return 'instagram_post_reel';
      case DeliverableType.ugcContent:
        return 'ugc_content';
      case DeliverableType.reviews:
        return 'reviews';
      case DeliverableType.productFeedback:
        return 'product_feedback';
      case DeliverableType.communityPhotos:
        return 'community_photos';
      case DeliverableType.newsletterMention:
        return 'newsletter_mention';
      case DeliverableType.longTermPartnership:
        return 'long_term_partnership';
      case DeliverableType.openToIdeas:
        return 'open_to_ideas';
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
      case 'minimum_attendance':
        return DeliverableType.minimumAttendance;
      case 'minimum_spend':
        return DeliverableType.minimumSpend;
      case 'tagged_stories':
        return DeliverableType.taggedStories;
      case 'instagram_post_reel':
        return DeliverableType.instagramPostReel;
      case 'ugc_content':
        return DeliverableType.ugcContent;
      case 'reviews':
        return DeliverableType.reviews;
      case 'product_feedback':
        return DeliverableType.productFeedback;
      case 'community_photos':
        return DeliverableType.communityPhotos;
      case 'newsletter_mention':
        return DeliverableType.newsletterMention;
      case 'long_term_partnership':
        return DeliverableType.longTermPartnership;
      case 'open_to_ideas':
        return DeliverableType.openToIdeas;
      default:
        return DeliverableType.socialMedia;
    }
  }
}
