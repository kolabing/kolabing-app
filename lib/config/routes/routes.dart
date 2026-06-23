import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/application/screens/application_review_screen.dart';
import '../../features/application/screens/chat_screen.dart';
import '../../features/chat/screens/chats_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/attendee_register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/utils/auth_navigation.dart';
import '../../features/business/screens/business_main_screen.dart';
import '../../features/business/screens/community_offer_detail_screen.dart';
import '../../features/collaboration/screens/collaboration_detail_screen.dart';
import '../../features/community/screens/attendee_community_profile_screen.dart';
import '../../features/community/screens/community_main_screen.dart';
import '../../features/community/screens/create_opportunity_screen.dart';
import '../../features/community/screens/discover_communities_screen.dart';
import '../../features/event/screens/event_detail_screen.dart';
import '../../features/friends/screens/add_friend_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/gamification/gamification.dart';
import '../../features/kolab/models/kolab.dart';
import '../../features/missions/screens/missions_screen.dart';
import '../../features/kolab/screens/intent_selection_screen.dart';
import '../../features/kolab/screens/kolab_flow_screen.dart';
import '../../features/notification/screens/notifications_screen.dart';
import '../../features/notification/utils/notification_navigation.dart';
import '../../features/onboarding/screens/attendee/attendee_step1_screen.dart';
import '../../features/onboarding/screens/attendee/attendee_step2_screen.dart';
import '../../features/onboarding/screens/attendee/attendee_step3_screen.dart';
import '../../features/onboarding/screens/attendee/attendee_step4_screen.dart';
import '../../features/onboarding/screens/business/business_final_screen.dart';
import '../../features/onboarding/screens/business/business_goal_screen.dart';
import '../../features/onboarding/screens/business/business_product_about_screen.dart';
import '../../features/onboarding/screens/business/business_product_cities_screen.dart';
import '../../features/onboarding/screens/business/business_product_identity_screen.dart';
import '../../features/onboarding/screens/business/business_step2_screen.dart';
import '../../features/onboarding/screens/business/business_step5_screen.dart';
import '../../features/onboarding/screens/community/community_final_screen.dart';
import '../../features/onboarding/screens/community/community_step1_screen.dart';
import '../../features/onboarding/screens/community/community_step2_screen.dart';
import '../../features/onboarding/screens/community/community_step3_screen.dart';
import '../../features/onboarding/screens/community/community_step4_screen.dart';
import '../../features/opportunity/models/opportunity.dart';
import '../../features/opportunity/providers/opportunity_provider.dart';
import '../../features/permission/screens/permission_screen.dart';
import '../../features/profile/screens/profile_reviews_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/rewards/screens/referral_screen.dart';
import '../../features/rewards/screens/wallet_screen.dart';
import '../../features/rewards/screens/withdrawal_request_screen.dart';
import '../../features/settings/screens/language_selector_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../services/notification_service.dart';
import '../../services/one_signal_service.dart';

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
  /// Entry point: the goal step (venue vs product). The venue path reuses the
  /// existing step5/step2/final screens; the product path uses the dedicated
  /// product/* screens below.
  static const String businessOnboardingGoal = '/onboarding/business/goal';
  static const String businessOnboardingStep1 = '/onboarding/business/step1';
  static const String businessOnboardingStep2 = '/onboarding/business/step2';
  static const String businessOnboardingStep3 = '/onboarding/business/step3';
  static const String businessOnboardingStep4 = '/onboarding/business/step4';
  static const String businessOnboardingStep5 = '/onboarding/business/step5';
  static const String businessOnboardingFinal = '/onboarding/business/final';

  /// Business product path (goal = "promote a product/service", no venue).
  static const String businessOnboardingProductIdentity =
      '/onboarding/business/product/identity';
  static const String businessOnboardingProductCities =
      '/onboarding/business/product/cities';
  static const String businessOnboardingProductAbout =
      '/onboarding/business/product/about';

  /// Community onboarding routes
  static const String communityOnboardingStep1 = '/onboarding/community/step1';
  static const String communityOnboardingStep2 = '/onboarding/community/step2';
  static const String communityOnboardingStep3 = '/onboarding/community/step3';
  static const String communityOnboardingStep4 = '/onboarding/community/step4';
  static const String communityOnboardingFinal = '/onboarding/community/final';

  /// Attendee registration (no onboarding)
  static const String attendeeRegister = '/auth/register/attendee';

  /// Attendee onboarding routes (You · City · Interests · Join)
  static const String attendeeOnboardingStep1 = '/onboarding/attendee/step1';
  static const String attendeeOnboardingStep2 = '/onboarding/attendee/step2';
  static const String attendeeOnboardingStep3 = '/onboarding/attendee/step3';
  static const String attendeeOnboardingStep4 = '/onboarding/attendee/step4';

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

  static String buildCommunityOpportunityEditPath(String id) =>
      '/community/opportunities/$id/edit';

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

  /// Discover joinable communities (attendee discovery surface)
  static const String discoverCommunities = '/communities/discover';

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

  /// Standalone chats list (e.g. opened from a community/group chat notification).
  static const String chats = '/chats';

  /// Notifications screen
  static const String notifications = '/notifications';

  /// Language selection (app localization: en, es, ca)
  static const String language = '/settings/language';

  /// Notification preferences (message/application/collaboration/marketing)
  static const String notificationSettings = '/settings/notifications';

  /// Personal Rewards Screen (P3) — global XP "Redeem your XP" surface +
  /// per-community points & redeemable rewards. Fed by /me/rewards-overview.
  static const String rewards = '/rewards';

  /// Gamification missions — the signed-in user's missions + progress.
  /// Fed by GET /me/missions (role-scoped + filtered server-side).
  static const String missions = '/missions';

  /// Friends list (self) — NF-17 friend graph
  static const String friends = '/me/friends';

  /// Add a friend by email or @handle (identity contract §5)
  static const String addFriend = '/me/friends/add';

  /// Public profile preview
  static const String publicProfile = '/profile/:id';

  /// Attendee-facing community profile, keyed by COMMUNITY id (events + join).
  /// Distinct from [publicProfile] which is profile-id-keyed (business view).
  static const String communityProfileById = '/community/:id/profile';

  /// Build the community-profile route for a given community id.
  static String buildCommunityProfilePath(String communityId) =>
      '/community/$communityId/profile';

  /// Public profile reviews list
  static const String publicProfileReviews = '/profile/:id/reviews';

  /// Event detail screen
  static const String eventDetail = '/event/:id';

  /// Build an event detail route with explicit access mode.
  static String buildEventDetailPath(
    String eventId, {
    bool isReadOnly = true,
  }) => Uri(
    path: '/event/$eventId',
    queryParameters: <String, String>{
      'readonly': isReadOnly ? 'true' : 'false',
    },
  ).toString();

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
  void navigateFromPush(String? type, String? id, String? deeplink) {
    final route = resolveNotificationRoute(
      type: type,
      id: id,
      deeplink: deeplink,
    );
    kolabingRouter.push(route);
  }

  NotificationService.instance.registerNotificationTapHandler(navigateFromPush);
  OneSignalService.instance.connectRouter(navigateFromPush);
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
    // Entry point is now the goal step (venue vs product).
    GoRoute(
      path: KolabingRoutes.businessOnboardingGoal,
      name: 'businessOnboardingGoal',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessGoalScreen(),
    ),
    // Legacy step 1 deep links land on the goal step.
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep1,
      name: 'businessOnboardingStep1',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.businessOnboardingGoal,
    ),
    // Product path (goal = "promote a product/service").
    GoRoute(
      path: KolabingRoutes.businessOnboardingProductIdentity,
      name: 'businessOnboardingProductIdentity',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessProductIdentityScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingProductCities,
      name: 'businessOnboardingProductCities',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessProductCitiesScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingProductAbout,
      name: 'businessOnboardingProductAbout',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessProductAboutScreen(),
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
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.businessOnboardingStep2,
    ),
    // Step 4 (legacy business profile screen) was merged into step 2 — keep
    // the route as a redirect so any stale deep links land on the merged form.
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep4,
      name: 'businessOnboardingStep4',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.businessOnboardingStep2,
    ),
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep5,
      name: 'businessOnboardingStep5',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessStep5Screen(),
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

    // Attendee Onboarding (You · City · Interests · Join)
    GoRoute(
      path: KolabingRoutes.attendeeOnboardingStep1,
      name: 'attendeeOnboardingStep1',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeStep1Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.attendeeOnboardingStep2,
      name: 'attendeeOnboardingStep2',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeStep2Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.attendeeOnboardingStep3,
      name: 'attendeeOnboardingStep3',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeStep3Screen(),
    ),
    GoRoute(
      path: KolabingRoutes.attendeeOnboardingStep4,
      name: 'attendeeOnboardingStep4',
      builder: (BuildContext context, GoRouterState state) =>
          const AttendeeStep4Screen(),
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
    GoRoute(
      path: KolabingRoutes.businessApplications,
      name: 'businessApplications',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessMainScreen(initialTab: 3),
    ),

    // Kolab creation flow (new unified flow)
    GoRoute(
      path: KolabingRoutes.kolabNew,
      name: 'kolabNew',
      builder: (BuildContext context, GoRouterState state) {
        // C9: Send-Kolab CTA on a community profile passes the community id
        // so the form can scope the publish payload to that recipient.
        final recipientId = state.uri.queryParameters['recipient_community_id'];
        return IntentSelectionScreen(
          recipientCommunityId: recipientId == null || recipientId.isEmpty
              ? null
              : recipientId,
        );
      },
    ),
    GoRoute(
      path: KolabingRoutes.kolabFlow,
      name: 'kolabFlow',
      builder: (BuildContext context, GoRouterState state) {
        final kolab = state.extra is Kolab ? state.extra! as Kolab : null;
        return KolabFlowScreen(editKolab: kolab);
      },
    ),

    // Business legacy create/edit routes (System A, collab_opportunities).
    // B1 (2026-05-22): the legacy single-page CreateCollabRequestScreen was
    // retired. ALL new business creation now goes through the unified
    // /kolab/flow via /kolab/new. These paths hard-redirect so any stale deep
    // links or cached navigations land on the new flow. No data migration:
    // existing collab_opportunities remain readable/closable via their list
    // and detail screens; only the create entry changed.
    GoRoute(
      path: KolabingRoutes.businessOffersNew,
      name: 'businessOffersNew',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.kolabNew,
    ),
    GoRoute(
      path: KolabingRoutes.businessOffersEdit,
      name: 'businessOffersEdit',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.kolabNew,
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
        final canApply = state.uri.queryParameters['canApply'] != 'false';
        return CommunityOfferDetailScreen(
          offerId: id,
          offer: offer,
          canApply: canApply,
        );
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
    GoRoute(
      path: KolabingRoutes.communityApplications,
      name: 'communityApplications',
      builder: (BuildContext context, GoRouterState state) =>
          const CommunityMainScreen(initialTab: 3),
    ),

    // Community sub-routes (pushed on top of main screen)
    GoRoute(
      path: KolabingRoutes.businessOfferDetail,
      name: 'businessOfferDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final offer = state.extra as Opportunity?;
        final canApply = state.uri.queryParameters['canApply'] != 'false';
        return CommunityOfferDetailScreen(
          offerId: id,
          offer: offer,
          canApply: canApply,
        );
      },
    ),
    // Community legacy create route (System A, collab_opportunities).
    // B1 (2026-05-22): NEW community creation now goes through the unified
    // /kolab/flow via /kolab/new (IntentSelectionScreen offers the FREE
    // communitySeeking option). This path hard-redirects so the legacy
    // single-page CreateOpportunityScreen is unreachable for NEW creation.
    GoRoute(
      path: KolabingRoutes.communityOpportunitiesNew,
      name: 'communityOpportunitiesNew',
      redirect: (BuildContext context, GoRouterState state) =>
          KolabingRoutes.kolabNew,
    ),
    // EDIT still points at the legacy CreateOpportunityScreen on purpose.
    // Existing rows are System-A `collab_opportunities` (Opportunity model);
    // the new /kolab/flow consumes the System-B `Kolab` model. There is no
    // clean Opportunity -> Kolab mapping, so per the B1 brief we keep editing
    // legacy opportunities on the legacy screen (no data migration). New
    // creation is fully on /kolab/flow. See report.
    GoRoute(
      path: KolabingRoutes.communityOpportunitiesEdit,
      name: 'communityOpportunitiesEdit',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final opportunity = state.extra as Opportunity?;
        if (opportunity != null) {
          return CreateOpportunityScreen(editOpportunity: opportunity);
        }

        return Consumer(
          builder: (context, ref, _) {
            final opportunityAsync = ref.watch(opportunityDetailProvider(id));
            return opportunityAsync.when(
              data: (opportunity) =>
                  CreateOpportunityScreen(editOpportunity: opportunity),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Scaffold(
                body: Center(child: Text('Could not load opportunity: $error')),
              ),
            );
          },
        );
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
        final canApply = state.uri.queryParameters['canApply'] != 'false';
        return CommunityOfferDetailScreen(
          offerId: id,
          offer: offer,
          canApply: canApply,
        );
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
      path: KolabingRoutes.chats,
      name: 'chats',
      builder: (BuildContext context, GoRouterState state) =>
          const ChatsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.notifications,
      name: 'notifications',
      builder: (BuildContext context, GoRouterState state) =>
          const NotificationsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.language,
      name: 'language',
      builder: (BuildContext context, GoRouterState state) =>
          const LanguageSelectorScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.notificationSettings,
      name: 'notificationSettings',
      builder: (BuildContext context, GoRouterState state) =>
          const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.publicProfileReviews,
      name: 'publicProfileReviews',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final profileName = state.extra as String?;
        return ProfileReviewsScreen(profileId: id, profileName: profileName);
      },
    ),
    GoRoute(
      path: KolabingRoutes.rewards,
      name: 'rewards',
      builder: (BuildContext context, GoRouterState state) =>
          const PersonalRewardsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.missions,
      name: 'missions',
      builder: (BuildContext context, GoRouterState state) =>
          const MissionsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.friends,
      name: 'friends',
      builder: (BuildContext context, GoRouterState state) =>
          const FriendsScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.addFriend,
      name: 'addFriend',
      builder: (BuildContext context, GoRouterState state) =>
          const AddFriendScreen(),
    ),
    GoRoute(
      path: KolabingRoutes.discoverCommunities,
      name: 'discoverCommunities',
      builder: (BuildContext context, GoRouterState state) =>
          const DiscoverCommunitiesScreen(),
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
      path: KolabingRoutes.communityProfileById,
      name: 'communityProfileById',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return AttendeeCommunityProfileScreen(communityId: id);
      },
    ),
    GoRoute(
      path: '/event/:id',
      name: 'eventDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        final isReadOnlyParam = state.uri.queryParameters['readonly'];
        final isReadOnly =
            isReadOnlyParam == null ||
            (isReadOnlyParam != 'false' && isReadOnlyParam != '0');
        return EventDetailScreen(eventId: id, isReadOnly: isReadOnly);
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

  // Error page — auth-aware, gives the user a recovery action so a failed
  // route doesn't leave them stranded (B2 "page not found" stranding).
  errorBuilder: (BuildContext context, GoRouterState state) =>
      _RouteNotFoundScreen(failedUrl: state.uri.toString()),
);

/// Auth-aware "route not found" page (B2). Logs the failed URL + current
/// auth state, then offers a recovery action depending on whether the user
/// is signed in.
class _RouteNotFoundScreen extends ConsumerWidget {
  const _RouteNotFoundScreen({required this.failedUrl});

  final String failedUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    debugPrint(
      '[B2] errorBuilder fired: url=$failedUrl '
      'authStatus=${auth.status} userType=${auth.user?.userType}',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                "We couldn't find that page",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                failedUrl,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (auth.isAuthenticated && auth.user != null) ...[
                FilledButton(
                  onPressed: () {
                    final destination = resolveAuthDestination(
                      auth.user!,
                      isNewUser: auth.isNewUser,
                    );
                    context.go(destination);
                  },
                  child: const Text('Go to dashboard'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go(KolabingRoutes.login);
                  },
                  child: const Text('Sign out'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: () => context.go(KolabingRoutes.login),
                  child: const Text('Back to login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
