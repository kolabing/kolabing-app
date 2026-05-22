import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/collaboration/models/collaboration.dart';

/// Regression: the backend `CollaborationResource` (list AND detail) returns
/// `creator_profile`/`applicant_profile` + `collab_opportunity`, NOT the legacy
/// `business_partner`/`community_partner`/`opportunity` keys. `fromJson` must
/// resolve partners from creator/applicant by `user_type` instead of throwing
/// (which surfaced as "Failed to load Kolab" on the detail screen).
void main() {
  group('Collaboration.fromJson (real backend CollaborationResource shape)', () {
    Map<String, dynamic> realResourcePayload({String status = 'active'}) => {
      'id': '019e518b-eff7-7165-9ac2-458d0e00824c',
      'status': status,
      'scheduled_date': '2026-05-22',
      'contact_methods': null,
      'event_id': null,
      'qr_code_url': null,
      'completed_at': null,
      'creator_profile': {
        'id': 'profile-community',
        'user_type': 'community',
        'display_name': 'Real Run Club',
        'avatar_url': 'https://cdn.example.com/community.jpg',
        'community_type': 'sports',
        'city': {'name': 'Barcelona'},
      },
      'applicant_profile': {
        'id': 'profile-business',
        'user_type': 'business',
        'display_name': 'Eixample 46',
        'avatar_url': 'https://cdn.example.com/business.jpg',
        'business_type': 'cafe',
        'city': {'name': 'Barcelona'},
      },
      'collab_opportunity': {
        'id': 'opp-1',
        'title': 'Sunday Run + Coffee',
        'description': 'Run then brunch',
        'status': 'published',
        'business_offer': {'venue': true},
        'community_deliverables': {'community_reach': true},
      },
      'created_at': '2026-05-20T10:00:00+00:00',
      'updated_at': '2026-05-21T10:00:00+00:00',
    };

    test('resolves partners from creator/applicant by user_type', () {
      final c = Collaboration.fromJson(realResourcePayload());

      expect(c.id, '019e518b-eff7-7165-9ac2-458d0e00824c');
      expect(c.status, CollaborationStatus.inProgress); // 'active' -> inProgress
      expect(c.businessPartner.name, 'Eixample 46');
      expect(c.businessPartner.isBusiness, isTrue);
      expect(c.businessPartner.profilePhoto, 'https://cdn.example.com/business.jpg');
      expect(c.communityPartner.name, 'Real Run Club');
      expect(c.communityPartner.isCommunity, isTrue);
    });

    test('sources opportunity + offers from collab_opportunity', () {
      final c = Collaboration.fromJson(realResourcePayload());

      expect(c.opportunity?.title, 'Sunday Run + Coffee');
      expect(c.businessOffer.venue, isTrue);
      expect(c.communityDeliverables.communityReach, isTrue);
    });

    test('does not throw and keeps null contact methods', () {
      final c = Collaboration.fromJson(realResourcePayload(status: 'completed'));
      expect(c.status, CollaborationStatus.completed);
      expect(c.contactMethods.hasAny, isFalse);
      expect(c.feedbackSubmittedAt, isNull); // review CTA stays available
    });

    test('still parses the legacy business_partner/community_partner shape', () {
      final c = Collaboration.fromJson({
        'id': 'legacy-1',
        'status': 'scheduled',
        'scheduled_date': '2026-06-15',
        'created_at': '2026-05-01T10:00:00+00:00',
        'business_partner': {
          'id': 'b1',
          'name': 'Legacy Cafe',
          'user_type': 'business',
          'profile_photo': 'https://cdn.example.com/legacy.jpg',
        },
        'community_partner': {
          'id': 'c1',
          'name': 'Legacy Club',
          'user_type': 'community',
        },
      });

      expect(c.businessPartner.name, 'Legacy Cafe');
      expect(c.communityPartner.name, 'Legacy Club');
      expect(c.status, CollaborationStatus.scheduled);
    });
  });
}
