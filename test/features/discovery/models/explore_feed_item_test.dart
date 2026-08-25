import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';

Map<String, dynamic> _ordinaryJson({String id = 'kolab-1'}) =>
    <String, dynamic>{
      'id': id,
      'creator_type': 'community',
      'intent_type': 'seeking_sponsor',
      'title': 'Saturday Run',
      'description': 'desc',
      'preferred_city': 'Barcelona',
      'availability': <String, dynamic>{
        'mode': 'one_time',
        'start': '2026-07-01',
        'end': '2026-12-31',
      },
      'creator_profile': <String, dynamic>{
        'id': 'creator-1',
        'display_name': 'Barcelona Creators',
      },
    };

/// The exact `multi_kolab_role` shape documented in §13 of the Multi-Kolab
/// API contract (`MultiKolabRoleExploreResource`).
Map<String, dynamic> _roleJson({
  String id = 'role-1',
  String eligible = 'community',
  String? status,
  int needed = 1,
  int filled = 0,
  int? remaining,
  Object? partnerType,
  String? rsvpUrl = 'https://lu.ma/kolabing-launch',
}) => <String, dynamic>{
  'item_type': 'multi_kolab_role',
  'id': id,
  'multi_kolab_event_id': 'event-1',
  'role_title': 'Run Club Partner',
  'looking_for': <String, dynamic>{
    'eligible_account_type': eligible,
    'required': true,
    if (partnerType != null) 'partner_type': partnerType,
  },
  'event_title': 'Kolabing Launch Weekend',
  'city': 'Barcelona',
  'target_date': <String, dynamic>{
    'mode': 'exact',
    'date': '2026-09-12',
    'range_start': null,
    'range_end': null,
  },
  'compensation': <String, dynamic>{
    'type': 'value_exchange',
    'need': 'A running route + 20-30 participants',
    'receive': 'Free venue, post-run brunch, social tagging',
    'value_summary': 'Free entry, venue + brand partners wanted',
  },
  'positions_needed': needed,
  'positions_filled': filled,
  'positions_remaining': remaining ?? (needed - filled),
  'match_score': 82,
  'image_url': 'https://example.com/organizer-avatar.jpg',
  'creator_profile': <String, dynamic>{
    'id': 'organizer-1',
    'display_name': 'Kolabing',
    'avatar_url': 'https://example.com/organizer-avatar.jpg',
  },
  'rsvp': <String, dynamic>{'url': rsvpUrl},
  'published_at': '2026-08-12T09:00:00Z',
  if (status != null) 'status': status,
};

void main() {
  group('ExploreFeedItem.fromJson', () {
    test('parses an entry without item_type as an ordinary offer', () {
      final item = ExploreFeedItem.fromJson(_ordinaryJson());

      expect(item, isA<ExploreOfferItem>());
      expect((item as ExploreOfferItem).offer.title, 'Saturday Run');
      expect(item.feedKey, 'offer:kolab-1');
      expect(item.creatorProfileId, 'creator-1');
    });

    test('parses item_type=multi_kolab_role into a role item', () {
      final item = ExploreFeedItem.fromJson(_roleJson());

      expect(item, isA<ExploreMultiKolabRoleItem>());
      final role = (item as ExploreMultiKolabRoleItem).role;
      expect(role.roleId, 'role-1');
      expect(role.eventId, 'event-1');
      expect(role.roleTitle, 'Run Club Partner');
      expect(role.eventTitle, 'Kolabing Launch Weekend');
      expect(role.city, 'Barcelona');
      expect(role.eventDate, DateTime(2026, 9, 12));
      expect(role.compensationType, MultiKolabCompensationType.valueExchange);
      expect(role.need, 'A running route + 20-30 participants');
      expect(role.receive, 'Free venue, post-run brunch, social tagging');
      expect(role.valueSummary, 'Free entry, venue + brand partners wanted');
      expect(role.matchScore, 82);
      expect(role.coverPhotoUrl, 'https://example.com/organizer-avatar.jpg');
      expect(role.organizerProfileId, 'organizer-1');
      expect(role.organizerDisplayName, 'Kolabing');
      expect(role.eligibleAccountType.name, 'community');
      expect(role.required_, isTrue);
      expect(role.safeRsvpUrl, 'https://lu.ma/kolabing-launch');
      expect(role.publishedAt, isNotNull);
      // §13 omits `status` because it only ever emits OPEN roles.
      expect(role.isOpen, isTrue);
      expect(item.feedKey, 'multi-kolab-role:role-1');
    });

    test('role and offer feed keys never collide on the same raw id', () {
      final offer = ExploreFeedItem.fromJson(_ordinaryJson(id: 'shared-id'));
      final role = ExploreFeedItem.fromJson(_roleJson(id: 'shared-id'));

      expect(offer.feedKey, isNot(role.feedKey));
    });
  });

  group('MultiKolabRoleOffer partner-type request', () {
    test('a structured looking_for map yields a specific partner type', () {
      final item =
          ExploreFeedItem.fromJson(
                _roleJson(
                  partnerType: <String, dynamic>{
                    'key': 'run_club',
                    'label': 'Run club',
                  },
                ),
              )
              as ExploreMultiKolabRoleItem;

      expect(item.role.isOpenEnded, isFalse);
      expect(item.role.lookingFor!.key, 'run_club');
      expect(item.role.lookingFor!.label, 'Run club');
    });

    test('a bare slug is title-cased rather than surfaced raw', () {
      final item =
          ExploreFeedItem.fromJson(_roleJson(partnerType: 'run_club'))
              as ExploreMultiKolabRoleItem;

      expect(item.role.lookingFor!.label, 'Run Club');
    });

    test("§13's looking_for carries eligibility, not a partner type, so a "
        'plain contract payload is open-ended', () {
      final item =
          ExploreFeedItem.fromJson(_roleJson()) as ExploreMultiKolabRoleItem;

      expect(item.role.isOpenEnded, isTrue);
      expect(item.role.lookingFor, isNull);
    });
  });

  group('MultiKolabRoleOffer.safeRsvpUrl', () {
    ({String? url, String? expected}) c(String? url, String? expected) =>
        (url: url, expected: expected);

    for (final scenario in [
      c('https://lu.ma/event', 'https://lu.ma/event'),
      c('http://lu.ma/event', null),
      c('javascript:alert(1)', null),
      c('lu.ma/event', null),
      c('', null),
      c(null, null),
    ]) {
      test('rsvp url ${scenario.url} -> ${scenario.expected}', () {
        final json = _roleJson(rsvpUrl: scenario.url);
        final item =
            ExploreFeedItem.fromJson(json) as ExploreMultiKolabRoleItem;

        expect(item.role.safeRsvpUrl, scenario.expected);
      });
    }
  });

  group('MultiKolabRoleOffer.isVisibleInExplore', () {
    ExploreMultiKolabRoleItem parse(Map<String, dynamic> json) =>
        ExploreFeedItem.fromJson(json) as ExploreMultiKolabRoleItem;

    test('a community role is visible only in the community feed', () {
      final role = parse(_roleJson(eligible: 'community')).role;

      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'viewer-1',
        ),
        isTrue,
      );
      expect(
        role.isVisibleInExplore(
          isCommunityViewer: false,
          viewerProfileId: 'viewer-1',
        ),
        isFalse,
      );
    });

    test('a business role is visible only in the business feed', () {
      final role = parse(_roleJson(eligible: 'business')).role;

      expect(
        role.isVisibleInExplore(
          isCommunityViewer: false,
          viewerProfileId: 'viewer-1',
        ),
        isTrue,
      );
      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'viewer-1',
        ),
        isFalse,
      );
    });

    test('an either role is visible in both feeds', () {
      final role = parse(_roleJson(eligible: 'either')).role;

      for (final isCommunity in [true, false]) {
        expect(
          role.isVisibleInExplore(
            isCommunityViewer: isCommunity,
            viewerProfileId: 'viewer-1',
          ),
          isTrue,
        );
      }
    });

    test('a filled role is never visible', () {
      final role = parse(
        _roleJson(status: 'filled', needed: 1, filled: 1, remaining: 0),
      ).role;

      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'viewer-1',
        ),
        isFalse,
      );
      expect(role.canApply, isFalse);
    });

    test('a role with no remaining position is never visible', () {
      final role = parse(_roleJson(needed: 2, filled: 2, remaining: 0)).role;

      expect(role.positionsRemaining, 0);
      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'viewer-1',
        ),
        isFalse,
      );
    });

    test("the organizer never sees their own event's role", () {
      final role = parse(_roleJson()).role;

      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'organizer-1',
        ),
        isFalse,
      );
    });

    test('a multi-position role stays visible and reports its remainder', () {
      final role = parse(_roleJson(needed: 4, filled: 1)).role;

      expect(role.positionsRemaining, 3);
      expect(
        role.isVisibleInExplore(
          isCommunityViewer: true,
          viewerProfileId: 'viewer-1',
        ),
        isTrue,
      );
    });
  });

  test('a role the viewer already applied to cannot be applied to again', () {
    final json = _roleJson()..['viewer_has_applied'] = true;
    final item = ExploreFeedItem.fromJson(json) as ExploreMultiKolabRoleItem;

    expect(item.role.viewerHasApplied, isTrue);
    expect(item.role.canApply, isFalse);
    // Still discoverable — the card shows an already-applied state rather
    // than silently vanishing from the feed.
    expect(
      item.role.isVisibleInExplore(
        isCommunityViewer: true,
        viewerProfileId: 'viewer-1',
      ),
      isTrue,
    );
  });
}
