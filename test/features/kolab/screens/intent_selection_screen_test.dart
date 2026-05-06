import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/kolab/screens/intent_selection_screen.dart';

void main() {
  testWidgets(
    'keeps intent selection in a loading state while the profile type is unresolved',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(const ProfileState()),
            ),
          ],
          child: const MaterialApp(home: IntentSelectionScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('What would you like to promote?'), findsNothing);
      expect(find.text('Promote my Venue'), findsNothing);
      expect(find.text('Promote a Product or Service'), findsNothing);
    },
  );

  testWidgets(
    'shows community-specific options once a community profile is resolved',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(
                const ProfileState(
                  profile: UserModel(
                    id: 'community-1',
                    email: 'community@example.com',
                    userType: UserType.community,
                    communityProfile: CommunityProfile(
                      id: 'profile-1',
                      name: 'Barcelona Creators',
                    ),
                  ),
                  isLoading: false,
                  isInitialized: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: IntentSelectionScreen()),
        ),
      );

      expect(find.text('What would you like to do?'), findsOneWidget);
      expect(find.text('Find a Venue or Sponsor'), findsOneWidget);
      expect(find.text('Promote a Venue, Product or Service'), findsNothing);
      expect(find.text('Promote my Venue'), findsNothing);
      expect(find.text('Promote a Product or Service'), findsNothing);
    },
  );

  testWidgets(
    'shows an unavailable state with retry when profile loading finished without a user type',
    (tester) async {
      final notifier = _FakeProfileNotifier(
        const ProfileState(
          isLoading: false,
          isInitialized: true,
          error: 'Unable to load profile',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith(() => notifier)],
          child: const MaterialApp(home: IntentSelectionScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Unable to load profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Promote my Venue'), findsNothing);
      expect(find.text('Promote a Product or Service'), findsNothing);

      await tester.tap(find.text('Retry'));

      expect(notifier.loadProfileCalls, 1);
    },
  );
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;
  int loadProfileCalls = 0;

  @override
  ProfileState build() => _initialState;

  @override
  Future<void> loadProfile() async {
    loadProfileCalls += 1;
  }
}
