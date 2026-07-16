import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/dashboard/models/dashboard_model.dart';

void main() {
  group(
    'BusinessDashboard.fromJson — partner status / next action / monthly goal',
    () {
      test('parses all three new blocks when present', () {
        final dashboard = BusinessDashboard.fromJson(<String, dynamic>{
          'opportunities': <String, dynamic>{},
          'applications_received': <String, dynamic>{},
          'collaborations': <String, dynamic>{},
          'upcoming_collaborations': <dynamic>[],
          'partner_status': <String, dynamic>{
            'status': 'trusted_partner',
            'label': 'Trusted Partner',
            'icon': '✓',
            'breakdown': <String, dynamic>{
              'completed_kolabs': 3,
              'review_count': 3,
              'average_rating': 4.5,
              'repeat_partner_count': 1,
            },
          },
          'next_action': <String, dynamic>{
            'key': 'create_second_offer',
            'title': 'Ready for your next Kolab?',
            'body': 'Build on the momentum and create your next offer.',
          },
          'monthly_goal': <String, dynamic>{
            'completed': 1,
            'goal': 1,
            'met': true,
          },
        });

        expect(dashboard.partnerStatus?.status, 'trusted_partner');
        expect(dashboard.partnerStatus?.label, 'Trusted Partner');
        expect(dashboard.partnerStatus?.icon, '✓');
        expect(dashboard.partnerStatus?.breakdown.completedKolabs, 3);
        expect(dashboard.partnerStatus?.breakdown.averageRating, 4.5);

        expect(dashboard.nextAction?.key, 'create_second_offer');
        expect(dashboard.nextAction?.title, 'Ready for your next Kolab?');

        expect(dashboard.monthlyGoal?.completed, 1);
        expect(dashboard.monthlyGoal?.goal, 1);
        expect(dashboard.monthlyGoal?.met, isTrue);
      });

      test('all three blocks are null without throwing when absent', () {
        final dashboard = BusinessDashboard.fromJson(<String, dynamic>{
          'opportunities': <String, dynamic>{},
          'applications_received': <String, dynamic>{},
          'collaborations': <String, dynamic>{},
          'upcoming_collaborations': <dynamic>[],
        });

        expect(dashboard.partnerStatus, isNull);
        expect(dashboard.nextAction, isNull);
        expect(dashboard.monthlyGoal, isNull);
      });

      test(
        'next_action is null when the backend rule chain has nothing to suggest',
        () {
          final dashboard = BusinessDashboard.fromJson(<String, dynamic>{
            'opportunities': <String, dynamic>{},
            'applications_received': <String, dynamic>{},
            'collaborations': <String, dynamic>{},
            'upcoming_collaborations': <dynamic>[],
            'next_action': null,
          });

          expect(dashboard.nextAction, isNull);
        },
      );

      test(
        'partner status breakdown average_rating stays null with no reviews yet',
        () {
          final dashboard = BusinessDashboard.fromJson(<String, dynamic>{
            'opportunities': <String, dynamic>{},
            'applications_received': <String, dynamic>{},
            'collaborations': <String, dynamic>{},
            'upcoming_collaborations': <dynamic>[],
            'partner_status': <String, dynamic>{
              'status': 'new_partner',
              'label': 'New Partner',
              'icon': '',
              'breakdown': <String, dynamic>{
                'completed_kolabs': 0,
                'review_count': 0,
                'average_rating': null,
                'repeat_partner_count': 0,
              },
            },
          });

          expect(dashboard.partnerStatus?.breakdown.averageRating, isNull);
        },
      );
    },
  );
}
