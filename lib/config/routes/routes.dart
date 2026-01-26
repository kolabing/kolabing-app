import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/business/screens/business_main_screen.dart';
import '../../features/community/screens/community_main_screen.dart';
import '../../features/onboarding/screens/business/business_final_screen.dart';
import '../../features/onboarding/screens/business/business_step1_screen.dart';
import '../../features/onboarding/screens/business/business_step2_screen.dart';
import '../../features/onboarding/screens/business/business_step3_screen.dart';
import '../../features/onboarding/screens/business/business_step4_screen.dart';
import '../../features/onboarding/screens/community/community_final_screen.dart';
import '../../features/onboarding/screens/community/community_step1_screen.dart';
import '../../features/onboarding/screens/community/community_step2_screen.dart';
import '../../features/onboarding/screens/community/community_step3_screen.dart';
import '../../features/onboarding/screens/community/community_step4_screen.dart';

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

  /// Business my offers list
  static const String businessOffers = '/business/offers';

  /// Create new business offer
  static const String businessOffersNew = '/business/offers/new';

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

  // ---------------------------------------------------------------------------
  // Shared Routes
  // ---------------------------------------------------------------------------

  /// Opportunity detail screen
  static const String opportunityDetails = '/opportunity/:id';

  /// Collaboration detail screen
  static const String collaborationDetails = '/collaboration/:id';

  /// Application detail screen
  static const String applicationDetails = '/application/:id';

  // ---------------------------------------------------------------------------
  // Profile Completion
  // ---------------------------------------------------------------------------

  /// Profile completion flow
  static const String profileCompletion = '/profile/complete';
}

/// Kolabing router configuration
///
/// GoRouter setup with all application routes.
final GoRouter kolabingRouter = GoRouter(
  initialLocation: KolabingRoutes.splash,
  debugLogDiagnostics: true,
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

    // -------------------------------------------------------------------------
    // Onboarding Routes
    // -------------------------------------------------------------------------

    // Business Onboarding
    GoRoute(
      path: KolabingRoutes.businessOnboardingStep1,
      name: 'businessOnboardingStep1',
      builder: (BuildContext context, GoRouterState state) =>
          const BusinessStep1Screen(),
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
          const _PlaceholderScreen(title: 'Forgot Password'),
    ),
    GoRoute(
      path: KolabingRoutes.resetPassword,
      name: 'resetPassword',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Reset Password'),
    ),

    // Profile completion
    GoRoute(
      path: KolabingRoutes.profileCompletion,
      name: 'profileCompletion',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Complete Profile'),
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

    // Business sub-routes (pushed on top of main screen)
    GoRoute(
      path: KolabingRoutes.businessOffersNew,
      name: 'businessOffersNew',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Create Offer'),
    ),
    GoRoute(
      path: KolabingRoutes.businessOffersEdit,
      name: 'businessOffersEdit',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Edit Offer: $id');
      },
    ),
    GoRoute(
      path: KolabingRoutes.businessPlans,
      name: 'businessPlans',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Subscription Plans'),
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
      path: KolabingRoutes.communityOpportunitiesNew,
      name: 'communityOpportunitiesNew',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Create Opportunity'),
    ),
    GoRoute(
      path: KolabingRoutes.communityOpportunitiesEdit,
      name: 'communityOpportunitiesEdit',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Edit Opportunity: $id');
      },
    ),
    GoRoute(
      path: KolabingRoutes.communityReferrals,
      name: 'communityReferrals',
      builder: (BuildContext context, GoRouterState state) =>
          const _PlaceholderScreen(title: 'Referrals'),
    ),

    // -------------------------------------------------------------------------
    // Shared Detail Routes
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/opportunity/:id',
      name: 'opportunityDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Opportunity: $id');
      },
    ),
    GoRoute(
      path: '/collaboration/:id',
      name: 'collaborationDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Collaboration: $id');
      },
    ),
    GoRoute(
      path: '/application/:id',
      name: 'applicationDetails',
      builder: (BuildContext context, GoRouterState state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Application: $id');
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
  const _PlaceholderScreen({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
