import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/application/models/application.dart';
import 'package:kolabing_app/features/application/providers/application_provider.dart';
import 'package:kolabing_app/features/application/screens/chat_screen.dart';
import 'package:kolabing_app/features/application/services/application_service.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart'
    hide PaginatedResponse;
import 'package:kolabing_app/widgets/blurred_identity.dart';

/// These tests lock the chat HEADER avatar behaviour:
///   1. When the counterparty has a real photo URL, the header renders the live
///      image (initial circle is only a fallback).
///   2. When the counterparty has NO photo URL, the header shows the initial.
///   3. The header photo is blurred ONLY for a re-gated (lapsed) business
///      (docs/ROLES-AND-PERMISSIONS.md §2.8); never for a community viewer.
void main() {
  Future<void> pumpChat(
    WidgetTester tester, {
    required Application application,
    required UserModel viewer,
  }) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(status: AuthStatus.authenticated, user: viewer),
            ),
          ),
          applicationServiceProvider.overrideWithValue(
            _FakeApplicationService(application),
          ),
        ],
        child: const MaterialApp(home: ChatScreen(applicationId: 'app-1')),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  // Finds the header Image whose provider is a NetworkImage pointing at [url].
  Finder headerNetworkImage(String url) => find.byWidgetPredicate((widget) {
    if (widget is! Image) return false;
    final provider = widget.image;
    return provider is NetworkImage && provider.url == url;
  });

  testWidgets(
    'renders the counterparty photo in the header when a URL exists',
    (tester) async {
      final application = _application(
        applicantId: 'me-applicant',
        applicantAvatar: 'https://cdn.example.com/community.png',
        creatorAvatar: 'https://cdn.example.com/business.png',
      );

      // Viewer IS the applicant, so the counterparty is the creator (business).
      await pumpChat(
        tester,
        application: application,
        viewer: _businessUser(id: 'me-applicant'),
      );

      expect(
        headerNetworkImage('https://cdn.example.com/business.png'),
        findsOneWidget,
      );
    },
  );

  testWidgets('falls back to the initial when the counterparty has no photo', (
    tester,
  ) async {
    final application = _application(
      applicantId: 'me-applicant',
      applicantAvatar: 'https://cdn.example.com/community.png',
      creatorAvatar: null,
    );

    await pumpChat(
      tester,
      application: application,
      viewer: _businessUser(id: 'me-applicant'),
    );

    // No header network image (creator has no avatar)...
    expect(
      headerNetworkImage('https://cdn.example.com/business.png'),
      findsNothing,
    );
    // ...and the creator's initial ("V" for "Venue Co") is shown instead.
    expect(find.text('V'), findsWidgets);
  });

  testWidgets('blurs the header photo for a lapsed (re-gated) business', (
    tester,
  ) async {
    final application = _application(
      applicantId: 'me-applicant',
      applicantAvatar: 'https://cdn.example.com/community.png',
      creatorAvatar: 'https://cdn.example.com/business.png',
      viewerMustResubscribe: true,
    );

    await pumpChat(
      tester,
      application: application,
      viewer: _businessUser(id: 'me-applicant'),
    );

    // At least one enabled BlurredIdentity exists (header avatar + conversation).
    final enabledBlurs = tester
        .widgetList<BlurredIdentity>(find.byType(BlurredIdentity))
        .where((b) => b.enabled);
    expect(enabledBlurs, isNotEmpty);
  });

  testWidgets('never blurs the header for a community viewer', (tester) async {
    // viewerMustResubscribe is always false for a community per the API, so the
    // header avatar must render unblurred even on a shared lapsed collaboration.
    final application = _application(
      applicantId: 'community-me',
      applicantAvatar: 'https://cdn.example.com/community.png',
      creatorAvatar: 'https://cdn.example.com/business.png',
    );

    await pumpChat(
      tester,
      application: application,
      viewer: _communityUser(id: 'community-me'),
    );

    final enabledBlurs = tester
        .widgetList<BlurredIdentity>(find.byType(BlurredIdentity))
        .where((b) => b.enabled);
    expect(enabledBlurs, isEmpty);
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeApplicationService extends ApplicationService {
  _FakeApplicationService(this.application);

  final Application application;

  @override
  Future<Application> getApplication(String id) async => application;

  @override
  Future<int> markAsRead(String applicationId) async => 0;

  @override
  Future<PaginatedResponse<ChatMessage>> getMessages({
    required String applicationId,
    int page = 1,
    int perPage = 50,
  }) async => const PaginatedResponse<ChatMessage>(
    data: <ChatMessage>[],
    currentPage: 1,
    lastPage: 1,
    total: 0,
  );
}

Application _application({
  required String applicantId,
  String? applicantAvatar,
  String? creatorAvatar,
  bool viewerMustResubscribe = false,
}) => Application(
  id: 'app-1',
  opportunityId: 'opp-1',
  message: 'Hi',
  availability: '2026-06-01',
  status: ApplicationStatus.accepted,
  createdAt: DateTime(2026, 5, 1),
  applicantProfile: ApplicantProfile(
    id: applicantId,
    displayName: 'Run Club',
    avatarUrl: applicantAvatar,
  ),
  opportunity: Opportunity(
    id: 'opp-1',
    title: 'Brunch collab',
    description: 'desc',
    businessOffer: const BusinessOffer(venue: true),
    communityDeliverables: const CommunityDeliverables(
      socialMediaContent: true,
    ),
    categories: const ['Food'],
    availabilityMode: AvailabilityMode.oneTime,
    availabilityStart: DateTime(2026, 6, 1),
    availabilityEnd: DateTime(2026, 6, 1),
    venueMode: VenueMode.businessVenue,
    preferredCity: 'Barcelona',
    status: OpportunityStatus.published,
    creatorProfile: CreatorProfile(
      id: 'creator-business',
      userType: 'business',
      displayNameValue: 'Venue Co',
      avatarUrl: creatorAvatar,
    ),
  ),
  viewerMustResubscribe: viewerMustResubscribe,
);

UserModel _businessUser({required String id}) => UserModel(
  id: id,
  email: 'business@example.com',
  userType: UserType.business,
);

UserModel _communityUser({required String id}) => UserModel(
  id: id,
  email: 'community@example.com',
  userType: UserType.community,
);
