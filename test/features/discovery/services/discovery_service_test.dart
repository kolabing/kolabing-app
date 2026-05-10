import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/services/discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test(
    'DiscoveryItem parses business offer and community request payloads',
    () {
      const businessFixture = <String, dynamic>{
        'id': 'kolab-business-1',
        'creator_type': 'business',
        'intent_type': 'venue_promotion',
        'title': 'Sunset rooftop collab',
        'description': 'Host your creator event on our rooftop',
        'preferred_city': 'Barcelona',
        'cover_photo_url': 'https://cdn.example.com/cover.jpg',
        'published_at': '2026-05-09T12:00:00Z',
        'availability': <String, dynamic>{
          'mode': 'one_time',
          'start': '2026-05-20',
          'end': '2026-05-20',
          'selected_time': '19:00',
          'recurring_days': <int>[],
        },
        'creator_profile': <String, dynamic>{
          'id': 'creator-business-1',
          'display_name': 'Casa Sol',
          'avatar_url': 'https://cdn.example.com/avatar.jpg',
        },
        'business_offer': <String, dynamic>{
          'offer_types': <String>['venue', 'food_drink', 'social_media'],
          'venue_type': 'rooftop',
          'product_type': null,
          'seeking_communities': <Map<String, dynamic>>[
            <String, dynamic>{'key': 'travel', 'label': 'Travel'},
          ],
          'min_community_size': 100,
          'expected_deliverables': <String>['social_media', 'community_reach'],
        },
        'community_request': null,
        'match': <String, dynamic>{
          'feed': 'recommended',
          'score': 92,
          'tier': 'high',
          'reasons': <String>['city_match', 'community_type_match'],
        },
      };
      final businessItem = DiscoveryItem.fromJson(businessFixture);

      expect(businessItem.isBusinessOffer, isTrue);
      expect(businessItem.businessOffer, isNotNull);
      expect(businessItem.businessOffer!.offerTypes, <String>[
        'venue',
        'food_drink',
        'social_media',
      ]);
      expect(businessItem.businessOffer!.venueType, 'rooftop');
      expect(businessItem.businessOffer!.expectedDeliverables, <String>[
        'social_media',
        'community_reach',
      ]);
      expect(businessItem.match?.score, 92);
      expect(businessItem.match?.reasons, <String>[
        'city_match',
        'community_type_match',
      ]);

      const communityFixture = <String, dynamic>{
        'id': 'kolab-community-1',
        'creator_type': 'community',
        'intent_type': 'community_seeking',
        'title': 'Wellness meetup',
        'description': 'We need a cafe partner for our next meetup.',
        'preferred_city': 'Madrid',
        'published_at': '2026-05-08T08:00:00Z',
        'availability': <String, dynamic>{
          'mode': 'recurring',
          'start': '2026-05-21',
          'end': '2026-05-30',
          'selected_time': null,
          'recurring_days': <int>[2, 4],
        },
        'creator_profile': <String, dynamic>{
          'id': 'creator-community-1',
          'display_name': 'Move Club',
          'avatar_url': null,
        },
        'business_offer': null,
        'community_request': <String, dynamic>{
          'need_types': <String>['food_drink', 'sponsor'],
          'community_types': <Map<String, dynamic>>[
            <String, dynamic>{'key': 'wellness', 'label': 'Wellness'},
          ],
          'community_size': 1200,
          'typical_attendance': 250,
          'offers_in_return': <String>['social_media', 'event_activation'],
          'venue_preference': 'business_provides',
        },
        'match': <String, dynamic>{
          'feed': 'recommended',
          'score': 88,
          'tier': 'high',
          'reasons': <String>['need_offer_overlap'],
        },
      };
      final communityItem = DiscoveryItem.fromJson(communityFixture);

      expect(communityItem.isCommunityRequest, isTrue);
      expect(communityItem.communityRequest?.needTypes, <String>[
        'food_drink',
        'sponsor',
      ]);
      expect(
        communityItem.communityRequest?.communityTypes.single.key,
        'wellness',
      );
      expect(
        communityItem.communityRequest?.communityTypes.single.label,
        'Wellness',
      );
      expect(communityItem.communityRequest?.communitySize, 1200);
    },
  );

  test(
    'getOpportunities sends feed, filters, pagination, and auth header',
    () async {
      final service = DiscoveryService(
        authService: AuthService(secureStorage: const FlutterSecureStorage()),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/discovery/opportunities');
          expect(request.headers['Authorization'], 'Bearer token-123');
          expect(request.url.queryParameters['feed'], 'recommended');
          expect(request.url.queryParameters['page'], '1');
          expect(request.url.queryParameters['per_page'], '15');
          expect(request.url.queryParameters['search'], 'rooftop');
          expect(request.url.queryParameters['city'], 'Barcelona');
          expect(request.url.queryParameters['availability_mode'], 'one_time');
          expect(request.url.queryParametersAll['intent_types[]'], <String>[
            'venue_promotion',
          ]);
          expect(request.url.queryParametersAll['offer_types[]'], <String>[
            'venue',
            'food_drink',
          ]);
          expect(
            request.url.queryParametersAll['expected_deliverables[]'],
            <String>['social_media'],
          );

          const responseFixture = <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'data': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'kolab-business-1',
                  'creator_type': 'business',
                  'intent_type': 'venue_promotion',
                  'title': 'Sunset rooftop collab',
                  'description': 'Host your creator event on our rooftop',
                  'preferred_city': 'Barcelona',
                  'cover_photo_url': 'https://cdn.example.com/cover.jpg',
                  'published_at': '2026-05-09T12:00:00Z',
                  'availability': <String, dynamic>{
                    'mode': 'one_time',
                    'start': '2026-05-20',
                    'end': '2026-05-20',
                    'selected_time': '19:00',
                    'recurring_days': <int>[],
                  },
                  'creator_profile': <String, dynamic>{
                    'id': 'creator-business-1',
                    'display_name': 'Casa Sol',
                    'avatar_url': 'https://cdn.example.com/avatar.jpg',
                  },
                  'business_offer': <String, dynamic>{
                    'offer_types': <String>['venue', 'food_drink'],
                    'venue_type': 'rooftop',
                    'product_type': null,
                    'seeking_communities': <List<dynamic>>[],
                    'min_community_size': 100,
                    'expected_deliverables': <String>['social_media'],
                  },
                  'community_request': null,
                  'match': <String, dynamic>{
                    'feed': 'recommended',
                    'score': 92,
                    'tier': 'high',
                    'reasons': <String>['city_match'],
                  },
                },
              ],
              'meta': <String, dynamic>{
                'current_page': 1,
                'last_page': 1,
                'total': 1,
              },
            },
          };

          return http.Response(jsonEncode(responseFixture), 200);
        }),
      );

      final result = await service.getOpportunities(
        filters: const DiscoveryFilters(
          searchQuery: 'rooftop',
          city: 'Barcelona',
          availabilityMode: 'one_time',
          intentTypes: <String>['venue_promotion'],
          offerTypes: <String>['venue', 'food_drink'],
          expectedDeliverables: <String>['social_media'],
        ),
      );

      expect(result.total, 1);
      expect(result.data.single.id, 'kolab-business-1');
      expect(result.data.single.match?.score, 92);
    },
  );
}
