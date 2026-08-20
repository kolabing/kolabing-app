import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/utils/auth_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const attendee = UserModel(
    id: 'a-1',
    email: 'a@example.com',
    userType: UserType.attendee,
  );
  const business = UserModel(
    id: 'b-1',
    email: 'b@example.com',
    userType: UserType.business,
  );

  test('new attendee routes into onboarding step 1', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: true),
      KolabingRoutes.attendeeOnboardingStep1,
    );
  });

  test('existing attendee routes to the attendee dashboard', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: false),
      KolabingRoutes.attendeeDashboard,
    );
  });

  test('new business still routes to business onboarding (regression)', () {
    expect(
      resolveAuthDestination(business, isNewUser: true),
      KolabingRoutes.businessOnboardingStep5,
    );
  });

  group('gateDestinationOnPermissions', () {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

    // PermissionStatus indices as encoded by permission_handler.
    const denied = 0;
    const granted = 1;

    void mockPermissionStatus(int status) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'checkPermissionStatus') {
              return status;
            }
            return null;
          });
    }

    const dashboards = <String>[
      KolabingRoutes.businessDashboard,
      KolabingRoutes.communityDashboard,
      KolabingRoutes.attendeeDashboard,
    ];

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('every dashboard is gated while consent is outstanding', () async {
      mockPermissionStatus(denied);

      for (final dashboard in dashboards) {
        expect(
          await gateDestinationOnPermissions(dashboard),
          '${KolabingRoutes.permissions}?destination='
          '${Uri.encodeComponent(dashboard)}',
          reason:
              '$dashboard must not be reachable before the consent prompt '
              '(Apple guideline 4.5.4)',
        );
      }
    });

    test('the attendee dashboard is gated as well', () async {
      // The 1.5 (36) rejection: only /business and /community were checked, so
      // an attendee signing in reached the app without ever being asked.
      mockPermissionStatus(denied);

      expect(
        await gateDestinationOnPermissions(KolabingRoutes.attendeeDashboard),
        startsWith(KolabingRoutes.permissions),
      );
    });

    test('dashboards pass through once consent is granted', () async {
      mockPermissionStatus(granted);

      for (final dashboard in dashboards) {
        expect(await gateDestinationOnPermissions(dashboard), dashboard);
      }
    });

    test('onboarding destinations are never diverted', () async {
      mockPermissionStatus(denied);

      for (final onboarding in <String>[
        KolabingRoutes.attendeeOnboardingStep1,
        KolabingRoutes.businessOnboardingStep5,
        KolabingRoutes.communityOnboardingStep1,
      ]) {
        expect(await gateDestinationOnPermissions(onboarding), onboarding);
      }
    });
  });
}
