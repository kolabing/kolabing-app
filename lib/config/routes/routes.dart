import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/notification_service.dart';

import '../../features/application/screens/application_review_screen.dart';
import '../../features/application/screens/chat_screen.dart';
import '../../features/auth/screens/attendee_register_screen.dart';
import '../../features/collaboration/screens/collaboration_detail_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/event/screens/event_detail_screen.dart';
import '../../features/gamification/gamification.dart';
import '../../features/opportunity/models/opportunity.dart';
import '../../features/business/screens/business_main_screen.dart';
import '../../features/business/screens/community_offer_detail_screen.dart';
import '../../features/community/screens/community_main_screen.dart';
import '../../features/business/screens/create_collab_request_screen.dart';
import '../../features/community/screens/create_opportunity_screen.dart';
import '../../features/kolab/screens/intent_selection_screen.dart';
import '../../features/kolab/screens/kolab_flow_screen.dart';
import '../../features/kolab/models/kolab.dart';
import '../../features/rewards/screens/referral_screen.dart';
import '../../features/rewards/screens/wallet_screen.dart';
import '../../features/rewards/screens/withdrawal_request_screen.dart';
import '../../features/notification/screens/notifications_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../features/onboarding/screens/business/business_final_screen.dart';
import '../../features/onboarding/screens/business/business_step2_screen.dart';
import '../../features/onboarding/screens/business/business_step3_screen.dart';
import '../../features/onboarding/screens/business/business_step4_screen.dart';
import '../../features/onboarding/screens/community/community_final_screen.dart';
import '../../features/onboarding/screens/community/community_step1_screen.dart';
import '../../features/onboarding/screens/community/community_step2_screen.dart';
import '../../features/onboarding/screens/community/community_step3_screen.dart';
import '../../features/onboarding/screens/community/community_step4_screen.dart';
import '../../features/permission/screens/permission_screen.dart';

/// Kolabing route definitions
///
/// All route paths used in the application.
abstract final class KolabingRoutes {
  // ---------------------------------------------------------------------------
  // Auth Routes
  // ---------------------------------------------------------------------------

  /// Splash screen
  static const String splash = '/';

  /// Welcome screen (after splash)
  static const String welcome = '/auth/welcome';

  /// User type selection screen
  static const String userTypeSelection = '/auth/user-type';

  /// Login screen (for existing users)
  static const String login = '/auth/login';

  /// Onboarding screens
  static const String onboarding = '/onboarding';

  /// Business onboarding routes
  static const String businessOnboardingStep1 = '/onboarding/business/step1';
  static const String businessOnboardingStep2 = '/onboarding/business/step2';
  static const String businessOnboardingStep3 = '/onboarding/business/step3';
  static const String businessOnboardingStep4 = '/onboarding/business/step4';
  static const String businessOnboardingFinal = '/onboarding/business/final';

  /// Community onboarding routes
  static const String communityOnboardingStep1 = '/onboarding/community/step1';
  static const String communityOnboardingStep2 = '/onboarding/community/step2';
  static const String communityOnboardingStep3 = '/onboarding/community/step3';
  static const String communityOnboardingStep4 = '/onboarding/community/step4';
  static const String communityOnboardingFinal = '/onboarding/community/final';

  /// Attendee registration (no onboarding)
  static const String attendeeRegister = '/auth/register/attendee';

  /// Legacy sign in (redirect to login)
  static const String signIn = '/auth/sign-in';

  /// Legacy sign up (redirect to user type selection)
  static const String signUp = '/auth/sign-up';

  /// Forgot password screen
  static const String forgotPassword = '/auth/forgot-password';

  /// Reset password screen (deep link)
  static const String resetPassword = '/auth/reset-password';

  // ---------------------------------------------------------------------------
  // Business Routes
  // ---------------------------------------------------------------------------

  /// Business dashboard (home)
  static const String businessDashboard = '/business';

  /// Business browse communities
  static const String businessBrowse = '/business/browse';

  /// Business my kollabs list
  static const String businessOffers = '/business/offers';

  /// Create new business offer
  static const String businessOffersNew = '/business/offers/new';

  /// New Kolab creation (unified entry)
  static const String kolabNew = '/kolab/new';

  /// Kolab creation flow (step-based)
  static const String kolabFlow = '/kolab/flow';

  /// Edit business offer
  static const String businessOffersEdit = '/business/offers/:id/edit';

  /// Business applications received
  static const String businessApplications = '/business/applications';

  /// Business my applications sent
  static const String businessMyApplications = '/business/my-applications';

  /// Business collaborations
  static const String businessCollaborations = '/business/collaborations';

  /// Business profile
  static const String businessProfile = '/business/profile';

  /// Business subscription plans
  static const String businessPlans = '/business/plans';

  /// Community offer detail (from business explore)
  static const String communityOfferDetail = '/business/explore/offer/:id';

  /// Business offer detail (from community explore)
  static const String businessOfferDetail = '/community/explore/offer/:id';

  // ---------------------------------------------------------------------------
  // Community Routes
  // ---------------------------------------------------------------------------

  /// Community dashboard (home)
  static const String communityDashboard = '/community';

  /// Community browse business offers
  static const String communityOffers = '/community/offers';

  /// Community my opportunities list
  static const String communityMyOpportunities = '/community/my-opportunities';

  /// Create new community opportunity
  static const String communityOpportunitiesNew =
      '/community/opportunities/new';

  /// Edit community opportunity
  static const String communityOpportunitiesEdit =
      '/community/opportunities/:id/edit';

  /// Community applications sent
  static const String communityApplications = '/community/applications';

  /// Community my applications received
  static const String communityMyApplications = '/community/my-applications';

  /// Community collaborations
  static const String communityCollaborations = '/community/collaborations';

  /// Community profile
  static const String communityProfile = '/community/profile';

  /// Community referrals
  static const String communityReferrals = '/community/referrals';

  /// Community wallet (rewards)
  static const String communityWallet = '/community/wallet';

  /// Community withdrawal request
  static const String communityWalletWithdraw = '/community/wallet/withdraw';

  /// Business referrals
  static const String businessReferrals = '/business/referrals';

  // ---------------------------------------------------------------------------
  // Shared Routes
  // ---------------------------------------------------------------------------

  /// Opportunity detail screen
  static const String opportunityDetails = '/opportunity/:id';

  /// Collaboration detail screen
  static const String collaborationDetails = '/collaboration/:id';

  /// Application detail screen
  static const String applicationDetails = '/application/:id';

  /// Application chat screen
  static const String applicationChat = '/application/:id/chat';

  /// Notifications screen
  static const String notifications = '/notifications';

  /// Public profile preview
  static const String publicProfile = '/profile/:id';

  /// Event detail screen
  static const String eventDetail = '/event/:id';

  // ---------------------------------------------------------------------------
  // Attendee (Gamification) Routes
  // ---------------------------------------------------------------------------

  /// Attendee dashboard (home)
  static const String attendeeDashboard = '/attendee';

  /// Attendee profile
  static const String attendeeProfile = '/attendee/profile';

  /// Event QR code display (for organizers)
  static const String eventQRCode = '/attendee/events/:eventId/qr';

  /// Event check-ins list (for organizers)
  static const String eventCheckins = '/attendee/events/:eventId/checkins';

  /// Event challenges list
  static const String eventChallenges = '/attendee/events/:eventId/challenges';

  /// Create challenge (for organizers)
  static const String createChallenge =
      '/attendee/events/:eventId/challenges/create';

  /// Edit challenge (for organizers)
  static const String editChallenge =
      '/attendee/events/:eventId/challenges/:challengeId/edit';

  /// Initiate challenge
  static const String initiateChallenge =
      '/attendee/events/:eventId/challenges/:challengeId/initiate';

  // ---------------------------------------------------------------------------
  // Profile Completion
  // ---------------------------------------------------------------------------

  /// Profile completion flow
  static const String profileCompletion = '/profile/complete';

  /// Permission request screen
  static const String permissions = '/permissions';
}

/// Navigator key for programmatic navigation (e.g. from push notifications)
final GlobalKey<NavigatorState> kolabingNavigatorKey =
    GlobalKey<NavigatorState>();

/// Connect push notification taps to GoRouter.
///
/// Call once in main() after the app widget is running.
/// Maps FCM `type` → app route and navigates accordingly.
void connectNotificationRouter() {
  NotificationService.instance.connectRouter((String type, String? id) {
    switch (type) {
      case 'new_message':
        if (id != null) kolabingRouter.push('/application/$id/chat');

      case 'application_received':
      case 'application_accepted':
      case 'application_declined':
        if (id != null) kolabingRouter.push('/application/$id');

      case 'badge_awarded':
      // No badge screen yet — navigate to attendee dashboard

      case 'challenge_verified':
      case 'reward_won':
      // No rewards screen yet — navigate to attendee dashboard

      default:
        debugPrint('[FCM] Unknown notification type: $type');
    }
  });
}

/// Kolabing router configuration
///
/// GoRouter setup with all application routes.
final GoRouter kolabingRouter = GoRouter(
  navigatorKey: kolabingNavigatorKey,
  initialLocation: KolabingRoutes.splash,
  debugLogDiagnostics: true,

  // Handle deep link: kolabing://reset-password?token=TOKEN&email=EMAIL
  //
  // GoRouter parses this custom-scheme URI as path='/' with the query params,
  // because `reset-password` is the URI host, not the path. We detect the
  // presence of both token+email params on the root and redirect to the
  // reset-password screen.
  redirect: (BuildContext context, GoRouterState state) {
    if (state.matchedLocation == '/') {
      final token = state.uri.queryParameters['token'];
      final email = state.uri.queryParameters['email'];
      if (token != null && email != null) {
        return '/auth/reset-password'
            '?token=${Uri.encodeComponent(token)}'
            '&email=${Uri.encodeComponent(email)}';
      }
    }
    return null;
  },

  routes: [
    // -------------------------------------------------------------------------
    // Auth Routes
    // -------------------------------------------------------------------------

    // Splash
    GoRoute(
      path: KolabingRoutes.splash,
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),

    // Welcome (after splash)
    GoRoute(
      path: KolabingRoutes.welcome,
      name: 'welcome',
      builder: (BuildContext context, GoRouterState state) =>
          const WelcomeScreen(),
    ),

    // User Type Selection
    GoRoute(
      path: KolabingRoutes.userTypeSelection,
      name: 'userTypeSelection',
      builder: (BuildContext context, GoRouterState state) =>
          const UserTypeSelectionScreen(),
    ),

    // Login (existing users)
    GoRoute(
      path: KolabingRoutes.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),

    // Attendee registration (no onboarding steps)
    GoRoute(
      path: KolabingRoutes.attendeeRegister,
      name: 'attendeeRegister',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeRegisterScreen(),
    ),

    // -------------------------------------------------------------------------
    // Onboarding Routes
    // -------------------------------------------------------------------------
    GoRoute(
      path: KolabingRoutes.onboarding,
      name: 'onboarding',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.userTypeSelection,
    ),

    // Business Onboarding
    // Step 1 (location) was removed — redirect any leftover deeplinks to step 2.
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep1,
      name: 'businessOnboardingStep1',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.businessOnboardingStep2,
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep2,
      name: 'businessOnboardingStep2',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessStep2Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep3,
      name: 'businessOnboardingStep3',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessStep3Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep4,
      name: 'businessOnboardingStep4',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessStep4Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingFinal,
      name: 'businessOnboardingFinal',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessFinalScreen(),
    ),

    // Community Onboarding
    GoRoute(
      path: KolabingRoutes.communityOnboardingStep1,
      name: 'communityOnboardingStep1',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityStep1Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOnboardingStep2,
      name: 'communityOnboardingStep2',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityStep2Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOnboardingStep3,
      name: 'communityOnboardingStep3',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityStep3Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOnboardingStep4,
      name: 'communityOnboardingStep4',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityStep4Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOnboardingFinal,
      name: 'communityOnboardingFinal',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityFinalScreen(),
    ),

    // Legacy routes - redirect to new routes
    GoRoute(
      path: KolabingRoutes.signIn,
      name: 'signIn',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.login,
    ),
    GoRoute(
      path: KolabingRoutes.signUp,
      name: 'signUp',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.userTypeSelection,
    ),

    GoRoute(
      path: KolabingRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (BuildContext context, GoRouterState state) =>
          const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.resetPassword,
      name: 'resetPassword',
      builder: (BuildContext context, GoRouterState state) =>
          const ResetPasswordScreen(),
    ),

    // Profile completion
    GoRoute(
      path: KolabingRoutes.profileCompletion,
      name: 'profileCompletion',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Complete Profile'),
    ),

    // Permission request screen
    GoRoute(
      path: KolabingRoutes.permissions,
      name: 'permissions',
      builder: (BuildContext context, GoRouterState state) {
        final destination =
            state.uri.queryParameters['destination'] ?? '/business';
        return PermissionScreen(destination: destination);
      },
    ),

    // -------------------------------------------------------------------------
    // Business Routes
    // -------------------------------------------------------------------------
    GoRoute(
      path: KolabingRoutes.businessDashboard,
      name: 'businessDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessMainScreen(),
    ),

    // Kolab creation flow (new unified flow)
    GoRoute(
      path: KolabingRoutes.kolabNew,
      name: 'kolabNew',
      builder: (BuildContext context, GoRouterState state) =>
          const IntentSelectionScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.kolabFlow,
      name: 'kolabFlow',
      builder: (BuildContext context, GoRouterState state) {
        final kolab = state.extra is Kolab ? state.extra! as Kolab : null;
        return KolabFlowScreen(editKolab: kolab);
      },
    ),

    // Business sub-routes (pushed on top of main screen)
    GoRoute(
      path: KolabingRoutes.businessOffersNew,
      name: 'businessOffersNew',
      builder: (BuildContext context, GoRouterState state) {
        final opportunity = state.extra as Opportunity?;
        return CreateCollabRequestScreen(editOpportunity: opportunity);
      },
    ),
    GoRoute(
      path: KolabingRoutes.businessOffersEdit,
      name: 'businessOffersEdit',
      builder: (BuildContext context, GoRouterState state) {
        final opportunity = state.extra as Opportunity?;
        return CreateCollabRequestScreen(editOpportunity: opportunity);
      },
    ),
    GoRoute(
      path: KolabingRoutes.businessPlans,
      name: 'businessPlans',
      builder: (BuildContext context, GoRouterState state) =>
          const SubscriptionScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOfferDetail,
      name: 'communityOfferDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final offer = state.extra as Opportunity?;
        return CommunityOfferDetailScreen(offerId: id, offer: offer);
      },
    ),

    // -------------------------------------------------------------------------
    // Community Routes
    // -------------------------------------------------------------------------
    GoRoute(
      path: KolabingRoutes.communityDashboard,
      name: 'communityDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityMainScreen(),
    ),

    // Community sub-routes (pushed on top of main screen)
    GoRoute(
      path: KolabingRoutes.businessOfferDetail,
      name: 'businessOfferDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final offer = state.extra as Opportunity?;
        return CommunityOfferDetailScreen(offerId: id, offer: offer);
      },
    ),
    GoRoute(
      path: KolabingRoutes.communityOpportunitiesNew,
      name: 'communityOpportunitiesNew',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateOpportunityScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityOpportunitiesEdit,
      name: 'communityOpportunitiesEdit',
      builder: (BuildContext context, GoRouterState state) {
        final opportunity = state.extra as Opportunity?;
        return CreateOpportunityScreen(editOpportunity: opportunity);
      },
    ),
    GoRoute(
      path: KolabingRoutes.communityReferrals,
      name: 'communityReferrals',
      builder: (BuildContext context, GoRouterState state) =>
          const ReferralScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityWallet,
      name: 'communityWallet',
      builder: (BuildContext context, GoRouterState state) =>
          const WalletScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.communityWalletWithdraw,
      name: 'communityWalletWithdraw',
      builder: (BuildContext context, GoRouterState state) =>
          const WithdrawalRequestScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessReferrals,
      name: 'businessReferrals',
      builder: (BuildContext context, GoRouterState state) =>
          const ReferralScreen(),
    ),

    // -------------------------------------------------------------------------
    // Shared Detail Routes
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/opportunity/:id',
      name: 'opportunityDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final offer = state.extra as Opportunity?;
        return CommunityOfferDetailScreen(offerId: id, offer: offer);
      },
    ),
    GoRoute(
      path: '/collaboration/:id',
      name: 'collaborationDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return CollaborationDetailScreen(collaborationId: id);
      },
    ),
    GoRoute(
      path: '/application/:id',
      name: 'applicationDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return ApplicationReviewScreen(applicationId: id);
      },
    ),
    GoRoute(
      path: '/application/:id/chat',
      name: 'applicationChat',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return ChatScreen(applicationId: id);
      },
    ),
    GoRoute(
      path: KolabingRoutes.notifications,
      name: 'notifications',
      builder: (BuildContext context, GoRouterState state) =>
          const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile/:id',
      name: 'publicProfile',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final creatorProfile = state.extra as CreatorProfile?;
        return PublicProfileScreen(
          profileId: id,
          creatorProfile: creatorProfile,
        );
      },
    ),
    GoRoute(
      path: '/event/:id',
      name: 'eventDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return EventDetailScreen(eventId: id);
      },
    ),

    // -------------------------------------------------------------------------
    // Attendee (Gamification) Routes
    // -------------------------------------------------------------------------
    GoRoute(
      path: KolabingRoutes.attendeeDashboard,
      name: 'attendeeDashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeMainScreen(),
    ),

    GoRoute(
      path: KolabingRoutes.eventQRCode,
      name: 'eventQRCode',
      builder: (BuildContext context, GoRouterState state) {
        final eventId = state.pathParameters['eventId'] ?? '';
        final eventName = state.uri.queryParameters['name'];
        return EventQRCodeScreen(eventId: eventId, eventName: eventName);
      },
    ),

    GoRoute(
      path: KolabingRoutes.eventChallenges,
      name: 'eventChallenges',
      builder: (BuildContext context, GoRouterState state) {
        final eventId = state.pathParameters['eventId'] ?? '';
        final eventName = state.uri.queryParameters['name'];
        final isOrganizer = state.uri.queryParameters['organizer'] == 'true';
        return EventChallengesScreen(
          eventId: eventId,
          eventName: eventName,
          isOrganizer: isOrganizer,
        );
      },
    ),

    GoRoute(
      path: KolabingRoutes.createChallenge,
      name: 'createChallenge',
      builder: (BuildContext context, GoRouterState state) {
        final eventId = state.pathParameters['eventId'] ?? '';
        return CreateChallengeScreen(eventId: eventId);
      },
    ),

    GoRoute(
      path: KolabingRoutes.initiateChallenge,
      name: 'initiateChallenge',
      builder: (BuildContext context, GoRouterState state) {
        final eventId = state.pathParameters['eventId'] ?? '';
        final challengeId = state.pathParameters['challengeId'] ?? '';
        final challenge = state.extra as Challenge?;
        return InitiateChallengeScreen(
          eventId: eventId,
          challengeId: challengeId,
          challenge: challenge,
        );
      },
    ),
  ],

  // Error page
  errorBuilder: (BuildContext context, GoRouterState state) =>
      _PlaceholderScreen(
        title: 'Page Not Found',
        subtitle: state.uri.toString(),
      ),
);

/// Placeholder screen for routes that are not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Screen not yet implemented',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );
}
