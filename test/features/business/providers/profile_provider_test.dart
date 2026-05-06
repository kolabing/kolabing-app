import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/models/subscription.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'loadProfile keeps the loaded profile when notification preferences fail',
    () async {
      final container = ProviderContainer(
        overrides: [
          profileServiceProvider.overrideWith(
            (ref) => _FakeProfileService(
              profile: _communityUser,
              notificationPreferencesError: const NetworkException(
                'Notification preferences unavailable',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(profileProvider.notifier);

      await notifier.loadProfile();

      final state = container.read(profileProvider);
      expect(state.profile?.id, _communityUser.id);
      expect(state.profile?.isCommunity, isTrue);
      expect(state.notificationPrefs, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isInitialized, isTrue);
    },
  );

  test(
    'loadProfile keeps the loaded business profile when subscription fetch fails',
    () async {
      final container = ProviderContainer(
        overrides: [
          profileServiceProvider.overrideWith(
            (ref) => _FakeProfileService(
              profile: _businessUser,
              notificationPreferences: const NotificationPreferences(),
              subscriptionError: const NetworkException(
                'Subscription endpoint unavailable',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(profileProvider.notifier);

      await notifier.loadProfile();

      final state = container.read(profileProvider);
      expect(state.profile?.id, _businessUser.id);
      expect(state.profile?.isBusiness, isTrue);
      expect(state.notificationPrefs, isNotNull);
      expect(state.subscription, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isInitialized, isTrue);
    },
  );

  test(
    'loadProfile clears stale subscription when refresh shows unsubscribed profile and subscription fetch fails',
    () async {
      final service = _ScriptedProfileService(
        profiles: <UserModel>[
          _businessUserWithActiveFlag,
          _businessUserWithoutSubscription,
        ],
        notificationResults: <Object>[
          const NotificationPreferences(),
          const NotificationPreferences(),
        ],
        subscriptionResults: <Object>[
          const Subscription(
            id: 'sub-1',
            status: SubscriptionStatus.active,
            isActive: true,
          ),
          const NetworkException('Subscription endpoint unavailable'),
        ],
      );

      final container = ProviderContainer(
        overrides: [profileServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(profileProvider.notifier);

      await notifier.loadProfile();
      expect(container.read(profileProvider).isSubscribed, isTrue);

      await notifier.loadProfile();

      final state = container.read(profileProvider);
      expect(state.profile?.id, _businessUserWithoutSubscription.id);
      expect(state.profile?.hasActiveSubscription, isFalse);
      expect(state.subscription, isNull);
      expect(state.isSubscribed, isFalse);
    },
  );
}

const UserModel _communityUser = UserModel(
  id: 'community-1',
  email: 'community@example.com',
  userType: UserType.community,
  communityProfile: CommunityProfile(
    id: 'cp-1',
    name: 'Barcelona Creators Club',
  ),
);

const UserModel _businessUser = UserModel(
  id: 'business-1',
  email: 'business@example.com',
  userType: UserType.business,
  businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
);

const UserModel _businessUserWithActiveFlag = UserModel(
  id: 'business-1',
  email: 'business@example.com',
  userType: UserType.business,
  hasActiveSubscription: true,
  businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
);

const UserModel _businessUserWithoutSubscription = UserModel(
  id: 'business-1',
  email: 'business@example.com',
  userType: UserType.business,
  hasActiveSubscription: false,
  businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
);

class _FakeProfileService extends ProfileService {
  _FakeProfileService({
    required this.profile,
    this.notificationPreferences,
    this.notificationPreferencesError,
    this.subscriptionError,
  });

  final UserModel profile;
  final NotificationPreferences? notificationPreferences;
  final Exception? notificationPreferencesError;
  final Exception? subscriptionError;

  @override
  Future<UserModel> getProfile() async => profile;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    if (notificationPreferencesError != null) {
      throw notificationPreferencesError!;
    }
    return notificationPreferences ?? const NotificationPreferences();
  }

  @override
  Future<Subscription> getSubscription() async {
    if (subscriptionError != null) {
      throw subscriptionError!;
    }
    return const Subscription(
      id: 'sub-1',
      status: SubscriptionStatus.active,
      isActive: true,
    );
  }
}

class _ScriptedProfileService extends ProfileService {
  _ScriptedProfileService({
    required List<UserModel> profiles,
    List<Object>? notificationResults,
    List<Object>? subscriptionResults,
  }) : _profiles = List<UserModel>.from(profiles),
       _notificationResults = List<Object>.from(
         notificationResults ?? <Object>[const NotificationPreferences()],
       ),
       _subscriptionResults = List<Object>.from(
         subscriptionResults ??
             <Object>[
               const Subscription(
                 id: 'sub-1',
                 status: SubscriptionStatus.active,
                 isActive: true,
               ),
             ],
       );

  final List<UserModel> _profiles;
  final List<Object> _notificationResults;
  final List<Object> _subscriptionResults;
  int _profileIndex = 0;
  int _notificationIndex = 0;
  int _subscriptionIndex = 0;

  @override
  Future<UserModel> getProfile() async {
    final index = _profileIndex < _profiles.length
        ? _profileIndex++
        : _profiles.length - 1;
    return _profiles[index];
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    final index = _notificationIndex < _notificationResults.length
        ? _notificationIndex++
        : _notificationResults.length - 1;
    return _resolve<NotificationPreferences>(_notificationResults[index]);
  }

  @override
  Future<Subscription> getSubscription() async {
    final index = _subscriptionIndex < _subscriptionResults.length
        ? _subscriptionIndex++
        : _subscriptionResults.length - 1;
    return _resolve<Subscription>(_subscriptionResults[index]);
  }

  Future<T> _resolve<T>(Object value) async {
    if (value is Exception) {
      throw value;
    }
    if (value is T) {
      return value as T;
    }
    throw StateError('Unexpected scripted value: $value');
  }
}
