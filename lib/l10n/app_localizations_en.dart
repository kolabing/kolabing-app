// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kolabing';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get welcomeHeadlineLine1 => 'Where local brands';

  @override
  String get welcomeHeadlineLine2 => 'meet real communities.';

  @override
  String get welcomeSubtitle =>
      'Community-led partnerships for events, UGC, reviews and real-world growth.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeStartKolabing => 'Start kolabing';

  @override
  String get welcomeHeroWhere => 'Where';

  @override
  String get welcomeHeroBusinesses => 'businesses';

  @override
  String get welcomeHeroAnd => 'and';

  @override
  String get welcomeHeroCommunities => 'communities';

  @override
  String get welcomeHeroGrow => 'grow';

  @override
  String get welcomeHeroTogether => 'together';

  @override
  String get welcomeTaglineMatch => 'MATCH';

  @override
  String get welcomeTaglineDot => '·';

  @override
  String get welcomeTaglineKolab => 'KOLAB';

  @override
  String get welcomeTaglineGrow => 'GROW';

  @override
  String get welcomeFloatingEvents => 'events';

  @override
  String get welcomeFloatingUgc => 'UGC';

  @override
  String get welcomeFloatingReviews => 'reviews';

  @override
  String get welcomeFloatingGrowth => 'growth';

  @override
  String get welcomeFloatingCommunity => 'community';

  @override
  String get welcomeFloatingBrands => 'brands';

  @override
  String get welcomeFloatingPeople => 'people';

  @override
  String get welcomeFloatingConnection => 'connection';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageScreenTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageCatalan => 'Català';

  @override
  String get applicationReviewTitle => 'APPLICATION';

  @override
  String get applicationReviewLoadError => 'Failed to load application';

  @override
  String get applicationReviewNotFound => 'Application not found';

  @override
  String get applicationReviewMessageLabel => 'Message';

  @override
  String get applicationReviewNoMessage => 'No message provided';

  @override
  String get applicationReviewAvailabilityLabel => 'Availability';

  @override
  String get applicationReviewNotSpecified => 'Not specified';

  @override
  String get applicationReviewAppliedLabel => 'Applied';

  @override
  String get applicationReviewUnknownOpportunity => 'Unknown Opportunity';

  @override
  String get applicationReviewViewFullProfile => 'View Full Profile';

  @override
  String get applicationReviewStatusAccepted => 'Accepted';

  @override
  String get applicationReviewStatusAcceptedDesc =>
      'This application has been accepted. You can chat with the applicant.';

  @override
  String get applicationReviewStatusDeclined => 'Declined';

  @override
  String applicationReviewStatusDeclinedReason(String reason) {
    return 'Declined: $reason';
  }

  @override
  String get applicationReviewStatusDeclinedDesc =>
      'This application has been declined.';

  @override
  String get applicationReviewStatusWithdrawn => 'Withdrawn';

  @override
  String get applicationReviewStatusWithdrawnDesc =>
      'The applicant has withdrawn their application.';

  @override
  String get applicationReviewStatusPending => 'Pending';

  @override
  String get applicationReviewOpenChat => 'OPEN CHAT';

  @override
  String get applicationReviewDecline => 'DECLINE';

  @override
  String get applicationReviewAccept => 'ACCEPT';

  @override
  String get applicationReviewDeclineDialogTitle => 'Decline Application';

  @override
  String applicationReviewDeclineDialogBody(String name) {
    return 'Are you sure you want to decline this application from $name?';
  }

  @override
  String get applicationReviewDeclineReasonHint => 'Reason (optional)';

  @override
  String get applicationReviewDeclineDialogConfirm => 'Decline';

  @override
  String get applicationReviewDeclinedSnack => 'Application declined';

  @override
  String get acceptFormTitle => 'Accept Application';

  @override
  String get acceptFormSubtitle =>
      'Pick a kolab date — you\'ll continue the conversation in chat after accepting.';

  @override
  String get acceptFormScheduledDate => 'SCHEDULED DATE';

  @override
  String get acceptFormNoDates =>
      'No available future dates in the opportunity range.';

  @override
  String get acceptFormConfirm => 'CONFIRM ACCEPT';

  @override
  String get acceptFormAcceptedSnack => 'Application accepted! Kolab created.';

  @override
  String get acceptFormError =>
      'Failed to accept application. Please try again.';

  @override
  String get applicationsTitle => 'APPLICATIONS';

  @override
  String get applicationsTabSent => 'SENT';

  @override
  String get applicationsTabReceived => 'RECEIVED';

  @override
  String get applicationsSentEmptyTitle => 'No Applications Yet';

  @override
  String get applicationsSentEmptyBody =>
      'Start exploring opportunities and apply to kolab with businesses and communities.';

  @override
  String get applicationsReceivedEmptyTitle => 'No Received Applications';

  @override
  String get applicationsReceivedEmptyBody =>
      'When someone applies to your opportunities, they\'ll appear here.';

  @override
  String get applicationsErrorTitle => 'Something went wrong';

  @override
  String applicationCardFrom(String name) {
    return 'From: $name';
  }

  @override
  String applicationCardTo(String name) {
    return 'To: $name';
  }

  @override
  String get applicationStatusPending => 'Pending';

  @override
  String get applicationStatusAccepted => 'Accepted';

  @override
  String get applicationStatusDeclined => 'Declined';

  @override
  String get applicationStatusWithdrawn => 'Withdrawn';

  @override
  String get chatApplicationNotFound => 'Application not found';

  @override
  String get chatResubscribeBanner =>
      'Your subscription lapsed. Resubscribe to continue this chat.';

  @override
  String get chatResubscribeAction => 'RESUBSCRIBE';

  @override
  String get chatLoading => 'Loading...';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get chatMessageHint => 'Type a message...';

  @override
  String get chatSessionExpiredTitle => 'Session expired';

  @override
  String get chatSessionExpiredBody => 'Please sign in again to continue.';

  @override
  String get chatSignIn => 'Sign In';

  @override
  String get chatEmptyTitle => 'Start the conversation';

  @override
  String get chatEmptyBody => 'Send a message to begin discussing this kolab';

  @override
  String get chatViewOpportunity => 'View Opportunity';

  @override
  String get chatCancelApplication => 'Cancel Application';

  @override
  String get chatCancelDialogTitle => 'Cancel Application?';

  @override
  String get chatCancelDialogBody =>
      'Are you sure you want to cancel this application? This action cannot be undone.';

  @override
  String get chatCancelDialogKeep => 'No, Keep It';

  @override
  String get chatCancelDialogWithdraw => 'Yes, Withdraw';

  @override
  String get chatApplicationWithdrawn => 'Application withdrawn';

  @override
  String get applyModalHeader => 'NEW APPLICATION';

  @override
  String get applyModalMessageTitle => 'Your message';

  @override
  String get applyModalMessageHelp =>
      'A short pitch helps you stand out — mention what you bring and why this fit makes sense.';

  @override
  String get applyModalMessageHint =>
      'Tell them why you\'re perfect for this kolab and what value you can bring...';

  @override
  String get applyModalSelectDatesTitle => 'Select Date(s)';

  @override
  String get applyModalSelectDatesHelp =>
      'Pick from the available dates for this kolab';

  @override
  String get applyModalSelectDateError => 'Please select at least one date';

  @override
  String get applyModalNoDates => 'No available dates for this kolab';

  @override
  String get applyModalNotesLabel => 'Additional notes (optional)';

  @override
  String get applyModalNotesHint =>
      'e.g., Flexible on timing, prefer mornings...';

  @override
  String get applyModalTimeFrom => 'From';

  @override
  String get applyModalTimeTo => 'To';

  @override
  String get applyModalOptionalBadge => 'Optional';

  @override
  String get applyModalUnknownHost => 'Unknown host';

  @override
  String get applyModalHostFallback => 'Host';

  @override
  String get applyModalApplyingTo => 'You are applying to';

  @override
  String get applyModalWhatsOffered => 'What\'s offered';

  @override
  String get applyModalTip =>
      'Pick the dates that work for you and add a short message — applications with specifics get accepted faster.';

  @override
  String get applyModalSending => 'SENDING…';

  @override
  String get applyModalSend => 'SEND APPLICATION';

  @override
  String get applyModalAlreadyApplied =>
      'You have already applied to this opportunity';

  @override
  String get applyModalSubmitError =>
      'Failed to submit application. Please try again.';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'your@email.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get authUnexpectedError => 'An unexpected error occurred';

  @override
  String get attendeeRegisterTitle => 'JOIN AS ATTENDEE';

  @override
  String get attendeeRegisterSubtitle =>
      'Create your account to join events and complete challenges';

  @override
  String get attendeeRegisterPasswordHint => 'Min. 8 characters';

  @override
  String get attendeeRegisterConfirmPasswordHint => 'Re-enter your password';

  @override
  String get attendeeRegisterCreateAccount => 'CREATE ACCOUNT';

  @override
  String get attendeeRegisterTerms =>
      'By creating an account, you agree to our Terms of Service and Privacy Policy';

  @override
  String get loginPanelTitle => 'Sign in to your account';

  @override
  String get loginPanelSubtitle => 'Pick up where you left off.';

  @override
  String get loginSignInButton => 'Sign in';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginHeroWelcome => 'Welcome back.';

  @override
  String get loginSignUpLink => 'Sign up';

  @override
  String get loginUserNotFoundTitle => 'Account Not Found';

  @override
  String get loginUserNotFoundMessage =>
      'No account exists with this Google email. Please create an account first.';

  @override
  String get loginCreateAccountButton => 'Create Account';

  @override
  String get forgotPasswordFormTitle => 'Reset your password';

  @override
  String get forgotPasswordFormSubtitle =>
      'Enter your account email and we\'ll send a secure reset link.';

  @override
  String get forgotPasswordHelperText =>
      'If the email matches an account, the reset link will arrive shortly.';

  @override
  String get forgotPasswordSendButton => 'SEND RESET LINK';

  @override
  String get forgotPasswordSuccessTitle => 'Check your inbox';

  @override
  String get forgotPasswordSuccessSubtitle =>
      'If an account exists for this email, the reset link is on its way.';

  @override
  String get forgotPasswordBackToSignIn => 'BACK TO SIGN IN';

  @override
  String get forgotPasswordUseAnotherEmail => 'Use another email';

  @override
  String get forgotPasswordHeroLine1 => 'RESET ACCESS.';

  @override
  String get forgotPasswordHeroLine2 => 'GET BACK IN.';

  @override
  String get forgotPasswordHeroLine3 => 'FORGOT PASSWORD?';

  @override
  String get forgotPasswordHeroSentLine1 => 'CHECK YOUR EMAIL.';

  @override
  String get forgotPasswordHeroSentLine2 => 'OPEN THE LINK.';

  @override
  String get forgotPasswordHeroSentLine3 => 'YOU\'RE ALMOST IN.';

  @override
  String get resetPasswordTitle => 'RESET PASSWORD';

  @override
  String get resetPasswordSubtitle => 'Enter your new password below.';

  @override
  String get resetPasswordNewLabel => 'New Password';

  @override
  String get resetPasswordNewHint => 'Enter new password';

  @override
  String get resetPasswordConfirmHint => 'Confirm new password';

  @override
  String get resetPasswordButton => 'RESET PASSWORD';

  @override
  String get resetPasswordInvalidLink =>
      'Invalid reset link. Please request a new one.';

  @override
  String get resetPasswordSuccessTitle => 'PASSWORD RESET';

  @override
  String get resetPasswordSuccessMessage =>
      'Your password has been successfully reset. Redirecting you to sign in...';

  @override
  String get resetPasswordGoToSignIn => 'GO TO SIGN IN';

  @override
  String get signInTitle => 'WELCOME BACK';

  @override
  String get signInSubtitle => 'Sign in to continue';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInNoAccount => 'Don\'t have an account?';

  @override
  String get signInSignUp => 'Sign Up';

  @override
  String get signInTypeMismatchTitle => 'Account Type Mismatch';

  @override
  String signInTypeMismatchMessage(String type) {
    return 'This Google account is registered as a $type user. Please sign in from the correct screen.';
  }

  @override
  String get signInTypeMismatchDifferent => 'different';

  @override
  String get splashSemanticLabel => 'Kolabing - Loading application';

  @override
  String authLinkSemanticLabel(String leading, String action) {
    return '$leading Tap $action to navigate';
  }

  @override
  String get kolabingLogoSemanticLabel => 'Kolabing logo';

  @override
  String get selectionCardBusinessTitle => 'I\'M A BUSINESS';

  @override
  String get selectionCardCommunityTitle => 'I\'M A COMMUNITY';

  @override
  String get selectionCardAttendeeTitle => 'I\'M AN ATTENDEE';

  @override
  String get selectionCardBusinessDescription =>
      'Looking for communities to partner with';

  @override
  String get selectionCardCommunityDescription =>
      'Seeking sponsors and kolab partners';

  @override
  String get selectionCardAttendeeDescription =>
      'Joining events and completing challenges';

  @override
  String selectionCardSemanticLabel(String title, String description) {
    return '$title. $description';
  }

  @override
  String get businessNavHome => 'Home';

  @override
  String get businessNavExplore => 'Explore';

  @override
  String get businessNavMyKolabs => 'My Kolabs';

  @override
  String get businessNavProfile => 'Profile';

  @override
  String get businessMainCreateKolabTooltip => 'Create Kolab Request';

  @override
  String get businessProfileSignOutTitle => 'Sign Out';

  @override
  String get businessProfileSignOutMessage =>
      'Are you sure you want to sign out?';

  @override
  String get businessProfileSignOut => 'Sign Out';

  @override
  String get businessProfileDeleteAccountTitle => 'Delete Account';

  @override
  String get businessProfileDeleteAccountMessage =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get businessProfileDelete => 'Delete';

  @override
  String get businessProfileDeleteAccount => 'Delete Account';

  @override
  String get businessProfileChangePhotoTitle => 'Change Profile Photo';

  @override
  String get businessProfileTakePhoto => 'Take Photo';

  @override
  String get businessProfileTakePhotoSubtitle => 'Use your camera';

  @override
  String get businessProfileChooseFromGallery => 'Choose from Gallery';

  @override
  String get businessProfileChooseFromGallerySubtitle =>
      'Select an existing photo';

  @override
  String get businessProfileUploadingPhoto => 'Uploading photo...';

  @override
  String get businessProfilePhotoUpdated => 'Profile photo updated';

  @override
  String get businessProfilePhotoUpdateFailed => 'Failed to update photo';

  @override
  String get businessProfileDismiss => 'Dismiss';

  @override
  String get businessProfileLoadFailed => 'Failed to load profile';

  @override
  String get businessProfileSomethingWrong => 'Something went wrong';

  @override
  String get businessProfileTryAgain => 'TRY AGAIN';

  @override
  String get businessProfileBusinessFallback => 'Business';

  @override
  String get businessProfileAbout => 'About';

  @override
  String get businessProfileSubscription => 'Subscription';

  @override
  String get businessProfilePremiumPlan => 'Premium Plan';

  @override
  String get businessProfileNoActivePlan => 'No Active Plan';

  @override
  String get businessProfileRenews => 'Renews';

  @override
  String get businessProfileRemaining => 'Remaining';

  @override
  String businessProfileDaysRemaining(num count) {
    return '$count days';
  }

  @override
  String get businessProfileSubscriptionEnding =>
      'Subscription ends at current billing period';

  @override
  String get businessProfileManageSubscription => 'MANAGE SUBSCRIPTION';

  @override
  String get businessProfileUpgradePremium => 'UPGRADE TO PREMIUM';

  @override
  String get businessProfileStatusActive => 'Active';

  @override
  String get businessProfileStatusCancelled => 'Cancelled';

  @override
  String get businessProfileStatusPastDue => 'Past Due';

  @override
  String get businessProfileStatusInactive => 'Inactive';

  @override
  String get businessProfileContactInfo => 'Contact Info';

  @override
  String get businessProfileNotifications => 'Notifications';

  @override
  String get businessProfileNotifMessages => 'Messages';

  @override
  String get businessProfileNotifApplications => 'Application Alerts';

  @override
  String get businessProfileNotifKolabUpdates => 'Kolab Updates';

  @override
  String get businessProfileNotifRewards => 'Rewards & Wallet';

  @override
  String get businessProfileNotifMarketing => 'Marketing & Tips';

  @override
  String get businessProfileAccount => 'Account';

  @override
  String get communityOfferDetailUnknown => 'Unknown';

  @override
  String get communityOfferDetailSubscribeToReveal => 'Subscribe to reveal';

  @override
  String communityOfferDetailApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applications',
      one: '$count application',
      zero: 'No applications',
    );
    return '$_temp0';
  }

  @override
  String get communityOfferDetailCategories => 'CATEGORIES';

  @override
  String get communityOfferDetailBusinessOffer => 'BUSINESS OFFER';

  @override
  String get communityOfferDetailVenueProvided => 'Venue provided';

  @override
  String get communityOfferDetailFoodDrink => 'Food & Drink included';

  @override
  String communityOfferDetailDiscountPct(num percent) {
    return '$percent% Discount';
  }

  @override
  String get communityOfferDetailDiscountOffered => 'Discount offered';

  @override
  String get communityOfferDetailExpectedDeliverables =>
      'EXPECTED DELIVERABLES';

  @override
  String get communityOfferDetailSocialMedia => 'Social Media Content';

  @override
  String get communityOfferDetailEventActivation => 'Event Activation';

  @override
  String get communityOfferDetailProductPlacement => 'Product Placement';

  @override
  String get communityOfferDetailCommunityReach => 'Community Reach';

  @override
  String get communityOfferDetailReviewFeedback => 'Review & Feedback';

  @override
  String get communityOfferDetailLocationTitle => 'LOCATION & AVAILABILITY';

  @override
  String get communityOfferDetailCity => 'City';

  @override
  String get communityOfferDetailNotSpecified => 'Not specified';

  @override
  String get communityOfferDetailVenue => 'Venue';

  @override
  String get communityOfferDetailAddress => 'Address';

  @override
  String get communityOfferDetailDates => 'Dates';

  @override
  String get communityOfferDetailMode => 'Mode';

  @override
  String get communityOfferDetailPreviewMode => 'PREVIEW MODE';

  @override
  String get communityOfferDetailAlreadyApplied => 'ALREADY APPLIED';

  @override
  String get communityOfferDetailApplyNow => 'APPLY NOW';

  @override
  String get communityOfferDetailTitle => 'Opportunity Details';

  @override
  String get communityOfferDetailNotFound => 'Opportunity Not Found';

  @override
  String get communityOfferDetailPreviewBanner =>
      'You are previewing this kolab as businesses see it';

  @override
  String get communityOfferDetailPastEvents =>
      'Past events from this community';

  @override
  String get communityOfferDetailPastEventsSubtitle =>
      'See this community\'s recent track record before applying.';

  @override
  String get communityOfferDetailTheOffer => 'THE OFFER';

  @override
  String get communityOfferDetailExtraTerms => 'EXTRA TERMS UNLOCKED';

  @override
  String get communityOfferDetailExtraTermsSubtitle =>
      'These only show because you have already applied.';

  @override
  String communityOfferDetailTriggerCondition(String condition) {
    return 'IF $condition';
  }

  @override
  String get exploreRecommendedMatches => 'Recommended matches for you';

  @override
  String get exploreBrowseAll => 'Browse all open kolabs';

  @override
  String exploreFilterNeeds(num count) {
    return 'Offers $count';
  }

  @override
  String exploreFilterTypes(num count) {
    return 'Types $count';
  }

  @override
  String exploreFilterOffers(num count) {
    return 'Offers $count';
  }

  @override
  String exploreFilterKolab(num count) {
    return 'Kolab $count';
  }

  @override
  String exploreResultCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '$count result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyNoResults => 'No results found';

  @override
  String get exploreEmptyNoRecommended => 'No recommended matches yet';

  @override
  String get exploreEmptyNoOpportunities => 'No opportunities yet';

  @override
  String get exploreEmptyNoResultsHint =>
      'Try broadening your filters or switching feeds.';

  @override
  String get exploreEmptyNoRecommendedHint =>
      'Switch to All or check back for fresh kolabs.';

  @override
  String get exploreEmptyNoOpportunitiesHint =>
      'Check back later for new opportunities.';

  @override
  String get exploreClearFilters => 'Clear all filters';

  @override
  String get exploreSomethingWrong => 'Something went wrong';

  @override
  String get exploreTryAgain => 'Try again';

  @override
  String get exploreFeedRecommended => 'Recommended';

  @override
  String get exploreFeedAll => 'All';

  @override
  String get myKolabsTabPublished => 'Published';

  @override
  String get myKolabsTabDraft => 'Draft';

  @override
  String get myKolabsPublished => 'Kolab published!';

  @override
  String get myKolabsPublishFailed => 'Failed to publish';

  @override
  String get myKolabsClosed => 'Kolab closed';

  @override
  String get myKolabsCloseFailed => 'Failed to close';

  @override
  String get myKolabsDeleteTitle => 'Delete Kolab';

  @override
  String get myKolabsDeleteMessage =>
      'Are you sure you want to delete this kolab? This action cannot be undone.';

  @override
  String get myKolabsDelete => 'Delete';

  @override
  String get myKolabsDeleted => 'Kolab deleted';

  @override
  String get myKolabsDeleteFailed => 'Failed to delete';

  @override
  String get myKolabsTitle => 'MY KOLABS';

  @override
  String get myKolabsSubtitle => 'Manage your kolabs';

  @override
  String myKolabsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kolabs',
      one: '$count kolab',
      zero: '0 kolabs',
    );
    return '$_temp0';
  }

  @override
  String get myKolabsEmptyTitle => 'No kolabs yet';

  @override
  String get myKolabsEmptyMessage =>
      'Create your first kolab to start connecting with communities';

  @override
  String get myKolabsCreate => 'Create Kolab';

  @override
  String get myKolabsSomethingWrong => 'Something went wrong';

  @override
  String get myKolabsTryAgain => 'Try again';

  @override
  String get kolabReviewSheetTitle => 'How was the Kolab? ⭐';

  @override
  String kolabReviewSheetSubtitle(String partnerName) {
    return 'Your review helps $partnerName build trust on Kolabing.';
  }

  @override
  String get kolabReviewSheetCommentHint => 'Anything to add? (optional)';

  @override
  String get kolabReviewSheetWouldAgain => 'Would you Kolab again?';

  @override
  String get kolabReviewSheetYes => 'Yes';

  @override
  String get kolabReviewSheetNo => 'No';

  @override
  String get kolabReviewSheetSubmitXp => 'Submit +10 XP ✨';

  @override
  String get kolabReviewSheetSkip => 'Skip for now';

  @override
  String get kolabCompletionConfirmTitle => 'Did the Kolab happen? 🎯';

  @override
  String kolabCompletionConfirmSubtitle(String partnerName) {
    return 'Mark your Kolab with $partnerName as complete.';
  }

  @override
  String get kolabCompletionConfirmLoading => 'Completing…';

  @override
  String get kolabCompletionConfirmCta => 'Yes, complete Kolab ✨';

  @override
  String get kolabCompletionConfirmDismiss => 'Not yet';

  @override
  String get kolabCompletionFeedbackTitle => 'How was the Kolab? ⭐';

  @override
  String kolabCompletionFeedbackSubtitle(String partnerName) {
    return 'Feedback is required to finish. Your review helps $partnerName build trust on Kolabing.';
  }

  @override
  String get kolabCompletionFeedbackCommentHint =>
      'Anything to add? (optional)';

  @override
  String get kolabCompletionFeedbackWouldAgain => 'Would you Kolab again?';

  @override
  String get kolabCompletionFeedbackYes => 'Yes';

  @override
  String get kolabCompletionFeedbackNo => 'No';

  @override
  String get kolabCompletionFeedbackSubmitting => 'Submitting…';

  @override
  String get kolabCompletionFeedbackSubmit => 'Submit & finish';

  @override
  String get kolabCompletionFeedbackTapStar => 'Tap a star to rate';

  @override
  String get kolabCompletionFeedbackFinishLater => 'Finish later';

  @override
  String get kolabCompletionSheetFeedbackError =>
      'Could not submit feedback. Please try again.';

  @override
  String get kolabCompletionCelebrationTitle => 'Kolab completed! 🎉';

  @override
  String get kolabCompletionCelebrationBody =>
      'You earned XP and your profile now reflects this completed Kolab.';

  @override
  String kolabCompletionXpEarned(num xp) {
    return '+$xp XP earned ⚡';
  }

  @override
  String get kolabCompletionCelebrationCta => 'See my XP →';

  @override
  String get kolabCompletionDoneTitle => 'All done! 🏆';

  @override
  String get kolabCompletionDoneBody =>
      'This Kolab is complete. Check your profile to see your growing history of collaborations.';

  @override
  String kolabCompletionDoneXp(num xp) {
    return '+$xp XP';
  }

  @override
  String get kolabCompletionDoneXpLabel => 'XP earned';

  @override
  String get kolabCompletionDoneClose => 'Close';

  @override
  String get collaborationDetailNotFound => 'Kolab not found';

  @override
  String get collaborationDetailRescheduleHelp => 'Reschedule kolab';

  @override
  String get collaborationDetailStartTimeHelp => 'Start time (optional)';

  @override
  String get collaborationDetailScheduleUpdated => 'Schedule updated.';

  @override
  String collaborationDetailScheduleUpdateError(String error) {
    return 'Could not update schedule: $error';
  }

  @override
  String get collaborationDetailEventDetails => 'EVENT DETAILS';

  @override
  String get collaborationDetailEdit => 'EDIT';

  @override
  String get collaborationDetailDateLabel => 'Date';

  @override
  String get collaborationDetailTimeLabel => 'Time';

  @override
  String get collaborationDetailVenueLabel => 'Venue';

  @override
  String collaborationDetailVenueValue(String businessName) {
    return '$businessName (Business venue)';
  }

  @override
  String get collaborationDetailCommunityReachLabel => 'Community Reach';

  @override
  String get collaborationDetailReachIncluded => 'Included';

  @override
  String get collaborationDetailReachNotSpecified => 'Not specified';

  @override
  String get collaborationDetailBusinessPartner => 'BUSINESS PARTNER';

  @override
  String get collaborationDetailCommunityPartner => 'COMMUNITY PARTNER';

  @override
  String get collaborationDetailOffersTitleBusiness => 'WHAT YOU\'RE OFFERING';

  @override
  String get collaborationDetailOffersTitleCommunity => 'WHAT\'S OFFERED';

  @override
  String get collaborationDetailOfferVenue => 'Venue provided';

  @override
  String get collaborationDetailOfferFoodDrink => 'Food & Drink included';

  @override
  String get collaborationDetailOfferSocialMedia => 'Social media exposure';

  @override
  String get collaborationDetailOfferContentCreation =>
      'Content creation support';

  @override
  String collaborationDetailOfferDiscount(num percentage) {
    return 'Discount: $percentage%';
  }

  @override
  String get collaborationDetailDeliverablesTitleBusiness =>
      'EXPECTED DELIVERABLES';

  @override
  String get collaborationDetailDeliverablesTitleCommunity =>
      'WHAT YOU\'LL DELIVER';

  @override
  String get collaborationDetailDeliverableSocialContent =>
      'Social Media Content';

  @override
  String get collaborationDetailDeliverableEventActivation =>
      'Event Activation';

  @override
  String get collaborationDetailDeliverableProductPlacement =>
      'Product Placement';

  @override
  String get collaborationDetailDeliverableCommunityReach => 'Community Reach';

  @override
  String get collaborationDetailDeliverableReviewFeedback =>
      'Review & Feedback';

  @override
  String get collaborationDetailContactTitle => 'CONTACT';

  @override
  String get collaborationDetailContactEmail => 'Email';

  @override
  String get collaborationDetailProcessTitle => 'PROCESS';

  @override
  String get collaborationDetailGamificationTitle => 'GAMIFICATION SETUP';

  @override
  String collaborationDetailSelectedCount(num count) {
    return '$count selected';
  }

  @override
  String get collaborationDetailGamificationDescription =>
      'Select challenges for attendees to complete during the event. These will be available in the attendee app.';

  @override
  String get collaborationDetailNoChallengesTitle => 'No challenges yet';

  @override
  String get collaborationDetailNoChallengesBody =>
      'Add challenges to make the event more engaging for attendees';

  @override
  String get collaborationDetailPoints => 'pts';

  @override
  String get collaborationDetailCustomChallengeSoon =>
      'Custom challenge creation coming soon';

  @override
  String get collaborationDetailAddCustomChallenge => 'ADD CUSTOM CHALLENGE';

  @override
  String get collaborationDetailQrTitle => 'QR CODE CHECK-IN';

  @override
  String get collaborationDetailQrPlaceholder => 'QR Code';

  @override
  String get collaborationDetailQrGeneratedOnDay => 'Generated on event day';

  @override
  String get collaborationDetailQrDescription =>
      'Attendees scan this QR code at your event to check in and start completing challenges.';

  @override
  String get collaborationDetailQrUnavailable =>
      'QR code will be available when the event is created';

  @override
  String get collaborationDetailViewQr => 'VIEW QR CODE';

  @override
  String get collaborationDetailResubscribeTitle => 'Resubscribe to continue';

  @override
  String get collaborationDetailResubscribeBody =>
      'Your subscription has lapsed, so this ongoing kolab and its chat are paused on your side. The community keeps full access. Resubscribe to pick up where you left off.';

  @override
  String get collaborationDetailResubscribeCta => 'RESUBSCRIBE';

  @override
  String get collaborationDetailLoadError => 'Failed to load kolab';

  @override
  String get collaborationDetailTodayBannerTitle => 'Today\'s Kolab!';

  @override
  String collaborationDetailTodayBannerBody(String partnerName) {
    return 'Your Kolab with $partnerName is today. Once it\'s active you\'ll be able to mark it complete.';
  }

  @override
  String get collaborationDetailCompleteTitleToday =>
      'Complete today\'s Kolab!';

  @override
  String get collaborationDetailCompleteTitle => 'Kolab completed?';

  @override
  String collaborationDetailCompleteBodyToday(String partnerName) {
    return 'Did your Kolab with $partnerName happen? Mark it done.';
  }

  @override
  String collaborationDetailCompleteBody(String partnerName) {
    return 'Did the Kolab with $partnerName happen? Mark it done.';
  }

  @override
  String get collaborationDetailMarkDone => 'Mark it done ✨';

  @override
  String get collaborationDetailItHappened => 'Yes, it happened ✨';

  @override
  String get collaborationDetailReviewSubmitted => 'Review submitted ✓';

  @override
  String get collaborationDetailLeaveReview => 'Leave a review';

  @override
  String get collaborationDetailXpBadge => '+10 XP';

  @override
  String collaborationDetailReviewHelp(String partnerName) {
    return 'Help $partnerName build trust on Kolabing.';
  }

  @override
  String get collaborationDetailLeaveReviewCta => 'Leave review +10 XP ✨';

  @override
  String get communityMainNavHome => 'Home';

  @override
  String get communityMainNavExplore => 'Explore';

  @override
  String get communityMainNavMyKolabs => 'My Kolabs';

  @override
  String get communityMainNavCommunity => 'Community';

  @override
  String get communityMainNavProfile => 'Profile';

  @override
  String get communityMainCreateOpportunityTooltip => 'Create Opportunity';

  @override
  String get communityProfileSignOutTitle => 'Sign Out';

  @override
  String get communityProfileSignOutBody =>
      'Are you sure you want to sign out?';

  @override
  String get communityProfileSignOutConfirm => 'Sign Out';

  @override
  String get communityProfileSignOutButton => 'SIGN OUT';

  @override
  String get communityProfileDeleteAccountTitle => 'Delete Account';

  @override
  String get communityProfileDeleteAccountBody =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get communityProfileDeleteAccountConfirm => 'Delete';

  @override
  String get communityProfileDeleteAccountLink => 'Delete Account';

  @override
  String get communityProfileChangePhotoTitle => 'Change Profile Photo';

  @override
  String get communityProfileTakePhoto => 'Take Photo';

  @override
  String get communityProfileTakePhotoSubtitle => 'Use your camera';

  @override
  String get communityProfileChooseFromGallery => 'Choose from Gallery';

  @override
  String get communityProfileChooseFromGallerySubtitle =>
      'Select an existing photo';

  @override
  String get communityProfileUploadingPhoto => 'Uploading photo...';

  @override
  String get communityProfilePhotoUpdated => 'Profile photo updated';

  @override
  String communityProfilePhotoUpdateFailed(String error) {
    return 'Failed to update photo: $error';
  }

  @override
  String get communityProfileDismiss => 'Dismiss';

  @override
  String get communityProfileLoadFailed => 'Failed to load profile';

  @override
  String get communityProfileErrorTitle => 'Something went wrong';

  @override
  String get communityProfileTryAgain => 'TRY AGAIN';

  @override
  String get communityProfileCommunityFallback => 'Community';

  @override
  String communityProfileLevelChip(int level, String title, int xp) {
    return 'LVL $level · $title · $xp XP';
  }

  @override
  String get communityProfileAboutSection => 'About';

  @override
  String get communityProfileContactInfoSection => 'Contact Info';

  @override
  String get communityProfileNotificationsSection => 'Notifications';

  @override
  String get communityProfileNotifMessages => 'Messages';

  @override
  String get communityProfileNotifApplications => 'Application Alerts';

  @override
  String get communityProfileNotifKolabUpdates => 'Kolab Updates';

  @override
  String get communityProfileNotifRewards => 'Rewards & Wallet';

  @override
  String get communityProfileNotifMarketing => 'Marketing & Tips';

  @override
  String get communityProfileAccountSection => 'Account';

  @override
  String get createOpportunityEditTitle => 'Edit Kolab';

  @override
  String get createOpportunityCreateTitle => 'Create a Kolab';

  @override
  String get createOpportunityStep0Title => 'BASIC INFORMATION';

  @override
  String get createOpportunityStep0Subtitle => 'Describe your kolab idea';

  @override
  String get createOpportunityTitleLabel => 'Title';

  @override
  String get createOpportunityTitleHint => 'e.g., Restaurant Week Promotion';

  @override
  String get createOpportunityDescriptionLabel => 'Description';

  @override
  String get createOpportunityDescriptionHint =>
      'Describe your kolab opportunity in detail. What are you looking for?';

  @override
  String get createOpportunityCategoriesLabel => 'Categories';

  @override
  String get createOpportunityCategoriesHint => 'Select up to 5 categories';

  @override
  String get createOpportunityPhotoLabel => 'Kolab Photo';

  @override
  String get createOpportunityPhotoHint =>
      'Optional, but recommended for Explore.';

  @override
  String get createOpportunityStep1Title =>
      'WHAT DO YOU NEED FROM THE BUSINESS?';

  @override
  String get createOpportunityStep1Subtitle =>
      'Select what your community expects in this kolab';

  @override
  String get createOpportunityOfferVenueTitle => 'Venue';

  @override
  String get createOpportunityOfferVenueSubtitle =>
      'You need a venue for the event';

  @override
  String get createOpportunityOfferFoodTitle => 'Food & Drink';

  @override
  String get createOpportunityOfferFoodSubtitle =>
      'You\'d like food or beverages provided';

  @override
  String get createOpportunityOfferDiscountTitle => 'Discount';

  @override
  String get createOpportunityOfferDiscountSubtitle =>
      'Special discount for your community';

  @override
  String get createOpportunityDiscountPercentageLabel => 'Discount Percentage';

  @override
  String get createOpportunityDiscountPercentageHint => 'e.g., 20';

  @override
  String get createOpportunityOfferProductsTitle => 'Products';

  @override
  String get createOpportunityOfferProductsSubtitle =>
      'You\'d like products or samples';

  @override
  String get createOpportunityProductNameHint => 'Product name';

  @override
  String get createOpportunityAddProduct => 'ADD PRODUCT';

  @override
  String get createOpportunityOfferOtherTitle => 'Other';

  @override
  String get createOpportunityOfferOtherSubtitle =>
      'Other support from the business';

  @override
  String get createOpportunityOfferOtherDetailsLabel => 'Other Offer Details';

  @override
  String get createOpportunityOfferOtherDetailsHint =>
      'Describe what the business offers';

  @override
  String get createOpportunityStep2Title => 'COMMUNITY DELIVERABLES';

  @override
  String get createOpportunityStep2Subtitle =>
      'What will the community provide in return?';

  @override
  String get createOpportunityDelivSocialTitle => 'Social Media Content';

  @override
  String get createOpportunityDelivSocialSubtitle =>
      'Instagram Post, Instagram Story, Reel / Short Video, TikTok Video, Photo Content (UGC for brand use)';

  @override
  String get createOpportunityDelivEventTitle => 'Event Activation';

  @override
  String get createOpportunityDelivEventSubtitle =>
      'Brand integration or mention during our event';

  @override
  String get createOpportunityDelivProductTitle => 'Product Placement';

  @override
  String get createOpportunityDelivProductSubtitle =>
      'Product showcase or visibility during our event';

  @override
  String get createOpportunityDelivReachTitle => 'Community Reach';

  @override
  String get createOpportunityDelivReachSubtitle =>
      'Minimum attendee guarantee, access to our members, feature, community discount code';

  @override
  String get createOpportunityDelivReviewTitle => 'Review & Feedback';

  @override
  String get createOpportunityDelivReviewSubtitle =>
      'Google/social reviews, testimonials or member feedback';

  @override
  String get createOpportunityDelivOtherTitle => 'Other';

  @override
  String get createOpportunityDelivOtherSubtitle =>
      'Write your own deliverable';

  @override
  String get createOpportunityDelivOtherDetailsLabel =>
      'Other Deliverable Details';

  @override
  String get createOpportunityDelivOtherDetailsHint =>
      'Describe what the community will deliver';

  @override
  String get createOpportunityStep3Title => 'LOCATION & AVAILABILITY';

  @override
  String get createOpportunityStep3Subtitle =>
      'When is your community available for this kolab?';

  @override
  String get createOpportunityAvailabilityLabel => 'Availability';

  @override
  String get createOpportunityVenueLabel => 'Venue';

  @override
  String get createOpportunityAddressLabel => 'Address';

  @override
  String get createOpportunityAddressHint => 'Enter the venue address';

  @override
  String get createOpportunityPreferredCityLabel => 'Preferred City';

  @override
  String createOpportunityCitiesLoadError(String error) {
    return 'Error loading cities: $error';
  }

  @override
  String get createOpportunitySelectCityHint => 'Select city';

  @override
  String get createOpportunityAvailableFromLabel => 'Available From';

  @override
  String get createOpportunityAvailableUntilLabel => 'Available Until';

  @override
  String get createOpportunityTimeLabel => 'Time';

  @override
  String get createOpportunityDayOfWeekLabel => 'Day of Week';

  @override
  String get createOpportunitySelectTime => 'Select time';

  @override
  String get createOpportunityStep4Title => 'REVIEW YOUR OPPORTUNITY';

  @override
  String get createOpportunityStep4Subtitle =>
      'Make sure everything looks correct before publishing';

  @override
  String get createOpportunityReviewUntitled => 'Untitled Opportunity';

  @override
  String get createOpportunityReviewNoDescription => 'No description provided';

  @override
  String get createOpportunityReviewBusinessOffer => 'Business Offer';

  @override
  String get createOpportunityReviewDeliverables => 'Community Deliverables';

  @override
  String get createOpportunityReviewNoCity => 'No city selected';

  @override
  String get createOpportunityReviewEditHint => 'Tap any section above to edit';

  @override
  String get createOpportunityBackButton => 'BACK';

  @override
  String get createOpportunityContinueButton => 'CONTINUE';

  @override
  String get createOpportunityPublishButton => 'PUBLISH';

  @override
  String get createOpportunitySaveDraftButton => 'SAVE DRAFT';

  @override
  String get myOpportunitiesTabPublished => 'Published';

  @override
  String get myOpportunitiesTabDraft => 'Draft';

  @override
  String get myOpportunitiesPublishError => 'Failed to publish opportunity';

  @override
  String get myOpportunitiesPublishSuccess => 'Opportunity published!';

  @override
  String get myOpportunitiesShareUnavailable =>
      'Sharing is unavailable. Link copied instead.';

  @override
  String get myOpportunitiesShareFailed => 'Could not open the share sheet.';

  @override
  String get myOpportunitiesCloseError => 'Failed to close opportunity';

  @override
  String get myOpportunitiesCloseSuccess => 'Opportunity closed';

  @override
  String get myOpportunitiesDeleteTitle => 'Delete Opportunity';

  @override
  String get myOpportunitiesDeleteBody =>
      'Are you sure you want to delete this opportunity? This action cannot be undone.';

  @override
  String get myOpportunitiesDeleteConfirm => 'Delete';

  @override
  String get myOpportunitiesDeleteError => 'Failed to delete opportunity';

  @override
  String get myOpportunitiesDeleteSuccess => 'Opportunity deleted';

  @override
  String get myOpportunitiesCreateNewTooltip => 'Create New Opportunity';

  @override
  String get myOpportunitiesHeaderTitle => 'MY OPPORTUNITIES';

  @override
  String get myOpportunitiesHeaderSubtitle =>
      'Create and manage your opportunities';

  @override
  String myOpportunitiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opportunities',
      one: '1 opportunity',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunitiesEmptyTitle => 'No opportunities yet';

  @override
  String get myOpportunitiesEmptyBody =>
      'Create your first opportunity and start connecting.';

  @override
  String get myOpportunitiesEmptyCreateButton => 'Create Opportunity';

  @override
  String get myOpportunitiesErrorTitle => 'Something went wrong';

  @override
  String myOpportunityCardApplicationsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get myOpportunityCardUntitled => 'Untitled Opportunity';

  @override
  String get myOpportunityCardActionView => 'View';

  @override
  String get myOpportunityCardActionEdit => 'Edit';

  @override
  String get myOpportunityCardActionPublish => 'Publish';

  @override
  String get myOpportunityCardActionShare => 'Share';

  @override
  String get myOpportunityCardActionClose => 'Close';

  @override
  String get myOpportunityCardActionDelete => 'Delete';

  @override
  String get opportunityPublishSuccessDraftTitle => 'Draft Saved!';

  @override
  String get opportunityPublishSuccessPublishedTitle =>
      'Opportunity Published!';

  @override
  String get opportunityPublishSuccessDraftBody =>
      'Your opportunity has been saved as a draft. You can edit and publish it later.';

  @override
  String get opportunityPublishSuccessPublishedBody =>
      'Your opportunity is now live. Businesses can start applying!';

  @override
  String get opportunityPublishSuccessShare => 'SHARE';

  @override
  String get opportunityPublishSuccessViewOpportunities =>
      'VIEW MY OPPORTUNITIES';

  @override
  String get eventDetailDeleteTitle => 'Delete Event';

  @override
  String eventDetailDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get eventDetailDeleteAction => 'Delete';

  @override
  String get eventDetailDeletedSnack => 'Event deleted';

  @override
  String get eventDetailNotFound => 'Event not found';

  @override
  String get eventDetailPhotosTitle => 'Photos';

  @override
  String get eventDetailVideosTitle => 'Videos';

  @override
  String get eventDetailDeleteButton => 'DELETE EVENT';

  @override
  String get eventDetailKolabWithLabel => 'Kolab with';

  @override
  String get eventDetailDateLabel => 'Event Date';

  @override
  String get eventDetailAttendeesLabel => 'Attendees';

  @override
  String eventDetailAttendeesCount(num count) {
    return '$count people';
  }

  @override
  String eventDetailRecapVideoTitle(num number) {
    return 'Recap video $number';
  }

  @override
  String get eventDetailRecapVideoSubtitle => 'Tap to open the uploaded video';

  @override
  String get eventDetailVideoOpenError => 'Could not open the video link';

  @override
  String get addEventTitle => 'Add Past Event';

  @override
  String get addEventMaxPhotos => 'Maximum 5 photos allowed';

  @override
  String get addEventMaxVideos => 'Maximum 1 video allowed';

  @override
  String get addEventAtLeastOnePhoto => 'Please add at least one photo';

  @override
  String get addEventSuccess => 'Event added successfully';

  @override
  String get addEventFailure => 'Failed to add event';

  @override
  String get addEventNameLabel => 'Event Name';

  @override
  String get addEventNameHint => 'e.g., Summer Music Festival';

  @override
  String get addEventNameError => 'Please enter event name';

  @override
  String get addEventPartnerLabel => 'Kolab With';

  @override
  String get addEventPartnerHint => 'e.g., Rock Community Istanbul';

  @override
  String get addEventPartnerError => 'Please enter partner name';

  @override
  String get addEventDateLabel => 'Event Date';

  @override
  String get addEventAttendeeCountLabel => 'Attendee Count';

  @override
  String get addEventAttendeeCountHint => 'e.g., 250';

  @override
  String get addEventAttendeeCountError => 'Please enter attendee count';

  @override
  String get addEventAttendeeCountInvalid => 'Please enter a valid number';

  @override
  String get addEventPhotosLabel => 'Event Photos';

  @override
  String addEventPhotosCounter(num count) {
    return '($count/5)';
  }

  @override
  String get addEventAddPhotoButton => 'Add Photo';

  @override
  String get addEventVideoLabel => 'Recap Video (Optional)';

  @override
  String get addEventVideoDescription =>
      'Add one short video to show how the event felt.';

  @override
  String get addEventAddVideoButton => 'ADD VIDEO';

  @override
  String get addEventSubmitButton => 'ADD EVENT';

  @override
  String get pastEventsTitle => 'Past Events';

  @override
  String get pastEventsAddButton => 'ADD';

  @override
  String get pastEventsLoadError => 'Failed to load events';

  @override
  String get pastEventsEmptyTitle => 'No events yet';

  @override
  String get pastEventsEmptySubtitle =>
      'Share your past kolabs with the community';

  @override
  String get pastEventsEmptyAddButton => '+ Add a past event';

  @override
  String get attendeeRoleLabel => 'Attendee';

  @override
  String get attendeeNavHome => 'Home';

  @override
  String get attendeeNavCommunities => 'Communities';

  @override
  String get attendeeNavScan => 'Scan';

  @override
  String get attendeeNavProfile => 'Profile';

  @override
  String get attendeeHomeWelcomeBack => 'Welcome back';

  @override
  String get attendeeHomeNearbyEvents => 'NEARBY EVENTS';

  @override
  String attendeeHomeRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get attendeeHomeGettingLocation => 'Getting your location...';

  @override
  String get attendeeHomeSearchingEvents => 'Searching for events...';

  @override
  String attendeeHomeShowingWithinRadius(String radius) {
    return 'Showing events within $radius km';
  }

  @override
  String attendeeHomeEventsFound(num count) {
    return '$count found';
  }

  @override
  String get attendeeHomeLoadMore => 'Load More';

  @override
  String get attendeeHomeStatPoints => 'Points';

  @override
  String get attendeeHomeStatChallenges => 'Challenges';

  @override
  String get attendeeHomeStatEvents => 'Events';

  @override
  String get attendeeHomeLocationRequired => 'Location Required';

  @override
  String get attendeeHomeTryAgain => 'Try Again';

  @override
  String get attendeeHomeOpenSettings => 'Open Settings';

  @override
  String get attendeeHomeNoEventsNearby => 'No Events Nearby';

  @override
  String get attendeeHomeNoEventsNearbyHint =>
      'Try increasing the search radius\nor check back later for new events.';

  @override
  String get attendeeHomeAdjustRadius => 'Adjust Radius';

  @override
  String get attendeeHomeFailedToLoadEvents => 'Failed to load events';

  @override
  String get attendeeHomeSearchRadius => 'Search Radius';

  @override
  String get attendeeHomeApply => 'Apply';

  @override
  String get attendeeHomeLocationDenied => 'Location permission denied';

  @override
  String get attendeeHomeLocationDeniedForever =>
      'Location permissions are permanently denied. Please enable them in settings.';

  @override
  String get attendeeHomeLocationServicesDisabled =>
      'Location services are disabled';

  @override
  String attendeeHomeLocationError(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get attendeeProfileYourStats => 'YOUR STATS';

  @override
  String get attendeeProfileTotalPoints => 'Total Points';

  @override
  String get attendeeProfileChallenges => 'Challenges';

  @override
  String get attendeeProfileEventsAttended => 'Events Attended';

  @override
  String get attendeeProfileEditProfile => 'Edit Profile';

  @override
  String get attendeeProfileNotifications => 'Notifications';

  @override
  String get attendeeProfileHelpSupport => 'Help & Support';

  @override
  String get attendeeProfileSignOut => 'Sign Out';

  @override
  String get attendeeProfileSignOutConfirm =>
      'Are you sure you want to sign out?';

  @override
  String get badgesScreenTitle => 'Badges';

  @override
  String get badgesScreenEarnedBadges => 'EARNED BADGES';

  @override
  String get badgesScreenAllBadges => 'ALL BADGES';

  @override
  String get badgesScreenBadgesEarned => 'Badges Earned';

  @override
  String get badgesScreenFailedToLoad => 'Failed to load badges';

  @override
  String get gamificationTryAgain => 'Try Again';

  @override
  String get leaderboardScreenGlobalTitle => 'Global Leaderboard';

  @override
  String get leaderboardScreenTitle => 'Leaderboard';

  @override
  String get leaderboardScreenRankings => 'RANKINGS';

  @override
  String get leaderboardScreenYourRanking => 'Your Ranking';

  @override
  String get leaderboardScreenPoints => 'points';

  @override
  String get leaderboardScreenNoRankings => 'No Rankings Yet';

  @override
  String get leaderboardScreenNoRankingsHint =>
      'Be the first to earn points\nand claim the top spot!';

  @override
  String get leaderboardScreenFailedToLoad => 'Failed to load leaderboard';

  @override
  String get statsScreenTitle => 'My Stats';

  @override
  String get statsScreenTotalPoints => 'Total Points';

  @override
  String get statsScreenEvents => 'Events';

  @override
  String get statsScreenChallenges => 'Challenges';

  @override
  String get statsScreenBadges => 'Badges';

  @override
  String get statsScreenDetailedStats => 'DETAILED STATS';

  @override
  String get statsScreenRewardsWon => 'Rewards Won';

  @override
  String get statsScreenRewardsRedeemed => 'Rewards Redeemed';

  @override
  String get statsScreenEventsDiscovered => 'Events Discovered';

  @override
  String get statsScreenSpinsUsed => 'Spins Used';

  @override
  String get statsScreenQuickActions => 'QUICK ACTIONS';

  @override
  String get statsScreenRewards => 'Rewards';

  @override
  String get statsScreenShareComingSoon => 'Game card sharing coming soon!';

  @override
  String get statsScreenFailedToLoad => 'Failed to load stats';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get createChallengeTitle => 'Create Challenge';

  @override
  String get createChallengeSuccess => 'Challenge created successfully!';

  @override
  String get createChallengeNameLabel => 'Challenge Name';

  @override
  String get createChallengeNameHint => 'Enter challenge name';

  @override
  String get createChallengeNameRequired => 'Please enter a challenge name';

  @override
  String get createChallengeNameTooShort =>
      'Name must be at least 3 characters';

  @override
  String get createChallengeDescriptionLabel => 'Description';

  @override
  String get createChallengeDescriptionHint =>
      'Describe what attendees need to do';

  @override
  String get createChallengeDifficultyLabel => 'Difficulty';

  @override
  String get createChallengePointsLabel => 'Points';

  @override
  String get createChallengePointsHint => 'Points awarded';

  @override
  String get createChallengePointsInvalid => 'Enter a valid number';

  @override
  String get createChallengePointsMax => 'Maximum 100 points';

  @override
  String get createChallengeResetDefault => 'Reset to default';

  @override
  String get createChallengePointsDefaultHint =>
      'Default: Easy=5, Medium=15, Hard=30 points';

  @override
  String get createChallengeSubmit => 'CREATE CHALLENGE';

  @override
  String createChallengePointsValue(int points) {
    return '$points pts';
  }

  @override
  String get eventChallengesTitle => 'Challenges';

  @override
  String get eventChallengesTabAll => 'All Challenges';

  @override
  String get eventChallengesTabCustom => 'Custom';

  @override
  String get eventChallengesEmptyAll =>
      'No challenges available for this event';

  @override
  String get eventChallengesEmptyCustomOrganizer =>
      'Create custom challenges for your event';

  @override
  String get eventChallengesEmptyCustom => 'No custom challenges yet';

  @override
  String get eventChallengesNewChallenge => 'New Challenge';

  @override
  String eventChallengesPointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get eventChallengesSystemBadge => 'System';

  @override
  String get eventChallengesStartChallenge => 'START CHALLENGE';

  @override
  String get eventDiscoveryTitle => 'Discover Events';

  @override
  String get eventDiscoveryPermissionDenied => 'Location permission denied';

  @override
  String get eventDiscoveryPermissionDeniedForever =>
      'Location permissions are permanently denied. Please enable them in settings.';

  @override
  String get eventDiscoveryServicesDisabled => 'Location services are disabled';

  @override
  String eventDiscoveryLocationFailed(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get eventDiscoveryGettingLocation => 'Getting your location...';

  @override
  String get eventDiscoverySearching => 'Searching for events...';

  @override
  String eventDiscoveryRadiusInfo(String radius) {
    return 'Showing events within $radius km';
  }

  @override
  String eventDiscoveryFoundCount(int count) {
    return '$count found';
  }

  @override
  String get eventDiscoveryLoadMore => 'Load More';

  @override
  String get eventDiscoveryLocationRequired => 'Location Required';

  @override
  String get eventDiscoveryOpenSettings => 'Open Settings';

  @override
  String get eventDiscoveryEmptyTitle => 'No Events Nearby';

  @override
  String get eventDiscoveryEmptyBody =>
      'Try increasing the search radius\nor check back later for new events.';

  @override
  String get eventDiscoveryAdjustRadius => 'Adjust Radius';

  @override
  String get eventDiscoveryErrorTitle => 'Failed to discover events';

  @override
  String get eventDiscoverySearchRadius => 'Search Radius';

  @override
  String eventDiscoveryRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get eventDiscoveryApply => 'Apply';

  @override
  String get eventQrTitle => 'Event Check-in';

  @override
  String get eventQrInstructions =>
      'Attendees can scan this QR code to check in to your event';

  @override
  String get eventQrViewCheckins => 'View Check-ins';

  @override
  String get eventQrGenerating => 'Generating QR Code...';

  @override
  String get eventQrErrorTitle => 'Failed to generate QR code';

  @override
  String get eventQrCopyToken => 'Copy Token';

  @override
  String get eventQrTokenCopied => 'Token copied to clipboard';

  @override
  String get initiateChallengeTitle => 'Start Challenge';

  @override
  String get initiateChallengeFailed => 'Failed to initiate challenge';

  @override
  String get initiateChallengeSuccessTitle => 'Challenge Started!';

  @override
  String get initiateChallengeSuccessBody =>
      'The verifier will be notified to confirm your challenge completion.';

  @override
  String initiateChallengePointsAwarded(int points) {
    return '+$points pts';
  }

  @override
  String get initiateChallengeHowItWorks => 'How it works';

  @override
  String get initiateChallengeStep1 => 'Enter the verifier\'s profile ID';

  @override
  String get initiateChallengeStep2 =>
      'Complete the challenge with the verifier present';

  @override
  String get initiateChallengeStep3 => 'The verifier confirms your completion';

  @override
  String get initiateChallengeStep4 => 'Earn your points!';

  @override
  String get initiateChallengeVerifierLabel => 'Verifier Profile ID';

  @override
  String get initiateChallengeVerifierHint =>
      'Enter the verifier\'s profile ID';

  @override
  String get initiateChallengeVerifierRequired =>
      'Please enter the verifier\'s profile ID';

  @override
  String get initiateChallengeVerifierHelper =>
      'Ask another attendee for their profile ID to verify your challenge';

  @override
  String get initiateChallengeSubmit => 'START CHALLENGE';

  @override
  String get qrScannerEventFallback => 'Event';

  @override
  String get qrScannerCheckinFailed => 'Failed to check in';

  @override
  String get qrScannerSuccessTitle => 'Check-in Successful!';

  @override
  String get qrScannerSuccessSubtitle => 'You have checked in to';

  @override
  String get qrScannerErrorTitle => 'Check-in Failed';

  @override
  String get qrScannerClose => 'Close';

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerCheckingIn => 'Checking in...';

  @override
  String get qrScannerInstructionTitle =>
      'Point your camera at the event QR code';

  @override
  String get qrScannerInstructionSubtitle =>
      'The QR code will be displayed by the event organizer';

  @override
  String get rewardWalletTitle => 'My Rewards';

  @override
  String get rewardWalletEmptyTitle => 'No Rewards Yet';

  @override
  String get rewardWalletEmptyBody =>
      'Complete challenges and spin the wheel\nto win exciting rewards!';

  @override
  String get rewardWalletErrorTitle => 'Failed to load rewards';

  @override
  String get challengeCompletionDefaultName => 'Challenge';

  @override
  String get challengeCompletionDefaultChallenger => 'Challenger';

  @override
  String get challengeCompletionReject => 'Reject';

  @override
  String get challengeCompletionVerify => 'Verify';

  @override
  String get challengeCompletionStatusVerified => 'Verified';

  @override
  String get challengeCompletionStatusRejected => 'Rejected';

  @override
  String get challengeCompletionStatusPending => 'Pending';

  @override
  String get mediaTitleVenue => 'SHOW OFF YOUR VENUE';

  @override
  String get mediaTitleProduct => 'SHOW YOUR PRODUCT';

  @override
  String get mediaSubtitle =>
      'Add photos so communities can see what you\'re offering. (Min 1, Max 5)';

  @override
  String get mediaSelectFromLibrary => 'SELECT FROM LIBRARY';

  @override
  String get mediaSelectExistingTitle => 'Select existing photos';

  @override
  String get mediaUsePhoto => 'Use photo';

  @override
  String get mediaUsePhotos => 'Use photos';

  @override
  String get mediaPhotosAlreadyAdded =>
      'Those photos are already in this Kolab.';

  @override
  String mediaPhotosAdded(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count existing photos.',
      one: 'Added $count existing photo.',
    );
    return '$_temp0';
  }

  @override
  String mediaUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get mediaAddPhoto => 'Add Photo';

  @override
  String mediaPhotoSlot(int number) {
    return 'Photo $number';
  }

  @override
  String get offeringTitle => 'WHAT YOU\'RE OFFERING';

  @override
  String get offeringSelectAllThatApply => 'Select all that apply';

  @override
  String get offeringVenueTitle => 'Venue';

  @override
  String get offeringVenueSubtitle => 'Provide your space for the kolab';

  @override
  String get offeringFoodDrinkTitle => 'Food & Drink included';

  @override
  String get offeringFoodDrinkSubtitle =>
      'Meals or beverages for community members';

  @override
  String get offeringDiscountTitle => 'Discount for community members';

  @override
  String get offeringDiscountSubtitle => 'Exclusive pricing for participants';

  @override
  String get offeringProductsTitle => 'Products / Samples';

  @override
  String get offeringProductsSubtitle => 'Free product samples or giveaways';

  @override
  String get offeringSocialMediaTitle => 'Social Media Exposure';

  @override
  String get offeringSocialMediaSubtitle => 'Feature on your channels';

  @override
  String get offeringContentCreationTitle => 'Content Creation';

  @override
  String get offeringContentCreationSubtitle => 'Professional photos/video';

  @override
  String get offeringSponsorshipTitle => 'Sponsorship budget';

  @override
  String get offeringSponsorshipSubtitle => 'Financial support for the kolab';

  @override
  String get offeringOtherTitle => 'Other';

  @override
  String get offeringOtherSubtitle => 'Something else to offer';

  @override
  String get offeringBaseOfferLabel => 'BASE OFFER';

  @override
  String get offeringBaseOfferHelper =>
      'What every community will see on your card. Be specific so leaders can evaluate at a glance.';

  @override
  String get offeringBaseOfferHint =>
      'e.g. 20% off Tuesdays, free meeting room for groups of 10+';

  @override
  String get offeringExtraTermsLabel => 'EXTRA TERMS (OPTIONAL)';

  @override
  String get offeringExtraTermsHelper =>
      'Better terms you only unlock once a community proposes a kolab. They see these after sending you a Kolab.';

  @override
  String get offeringAddExtraTerm => 'ADD EXTRA TERM';

  @override
  String offeringTriggerIfPrefix(String condition) {
    return 'IF $condition';
  }

  @override
  String get offeringTriggerSheetTitle => 'Add an extra term';

  @override
  String get offeringTriggerSheetSubtitle =>
      'Surfaces only after a community sends a Kolab proposal.';

  @override
  String get offeringTriggerWhenLabel => 'When';

  @override
  String get offeringTriggerWhenHint => 'e.g. recurring monthly events';

  @override
  String get offeringTriggerThenLabel => 'Then offer';

  @override
  String get offeringTriggerThenHint =>
      'e.g. free venue rental from the 3rd event onward';

  @override
  String get offeringAddTerm => 'ADD TERM';

  @override
  String get pastEventsSubtitle =>
      'Show communities what events have been hosted at your venue before.';

  @override
  String get pastEventsLoadingProfileEvents => 'Loading profile events...';

  @override
  String get pastEventsSelectFromProfile => 'Select from profile';

  @override
  String get pastEventsAddPastEvent => 'Add a past event';

  @override
  String get pastEventsAllAlreadyAdded =>
      'All profile events are already added.';

  @override
  String pastEventsImported(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count profile events.',
      one: 'Imported $count profile event.',
    );
    return '$_temp0';
  }

  @override
  String pastEventsEventNumber(int number) {
    return 'Event $number';
  }

  @override
  String get pastEventsEventNameLabel => 'Event Name';

  @override
  String get pastEventsEventNameHint => 'e.g. Summer Wellness Meetup';

  @override
  String get pastEventsDateLabel => 'Date';

  @override
  String get pastEventsPartnerNameLabel => 'Partner Name';

  @override
  String get pastEventsPartnerNameHint => 'e.g. City Runners Club';

  @override
  String get pastEventsPhotosLabel => 'Photos (max 3)';

  @override
  String get pastEventsRecapVideoLabel => 'Recap Video (max 1)';

  @override
  String get pastEventsRecapVideoChip => 'Recap video';

  @override
  String pastEventsUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get productDetailsSectionHeader => 'YOUR PRODUCT OR SERVICE';

  @override
  String get productDetailsListingTitleLabel => 'Listing Title';

  @override
  String get productDetailsListingTitleHint =>
      'e.g. Organic Cold Brew - Perfect for Community Events';

  @override
  String get productDetailsProductNameLabel => 'Product Name';

  @override
  String get productDetailsProductNameHint => 'e.g. Organic Cold Brew Coffee';

  @override
  String get productDetailsProductTypeLabel => 'Product Type';

  @override
  String get productDetailsDescriptionLabel => 'Description';

  @override
  String get productDetailsDescriptionHint =>
      'Describe your product or service...';

  @override
  String get productDetailsOfferHeadlineLabel => 'Offer Headline';

  @override
  String get productDetailsOfferHeadlineHelper =>
      'One short line communities will see on your card.';

  @override
  String get productDetailsOfferHeadlineHint => 'e.g. Free with any 5+ order';

  @override
  String get productDetailsCityLabel => 'City';

  @override
  String get productDetailsSelectCityHint => 'Select city';

  @override
  String get productDetailsFailedToLoadCities => 'Failed to load cities';

  @override
  String get venueDetailsSectionHeader => 'PROMOTION DETAILS';

  @override
  String get venueDetailsListingTitleLabel => 'Listing Title';

  @override
  String get venueDetailsListingTitleHint =>
      'e.g. Sunset rooftop social for local creators';

  @override
  String get venueDetailsCampaignDescriptionLabel => 'Campaign Description';

  @override
  String get venueDetailsCampaignDescriptionHint =>
      'Tell communities what kind of experience you want to host and why your venue is a great fit.';

  @override
  String get venueDetailsOfferHeadlineLabel => 'Offer Headline';

  @override
  String get venueDetailsOfferHeadlineHelper =>
      'One short line communities will see on your card.';

  @override
  String get venueDetailsOfferHeadlineHint =>
      'e.g. 20% off Tuesdays for groups of 10+';

  @override
  String get venueDetailsPrimaryVenue => 'PRIMARY VENUE';

  @override
  String get venueDetailsVenueFallback => 'Venue';

  @override
  String venueDetailsTypeCapacity(String type, String capacity) {
    return '$type • Capacity $capacity';
  }

  @override
  String get communityInfoTypeHeader => 'YOUR COMMUNITY TYPE';

  @override
  String get communityInfoTypeSubtitle =>
      'Help businesses understand your audience. Select up to 3.';

  @override
  String get communityInfoCommunitySizeLabel => 'COMMUNITY SIZE';

  @override
  String get communityInfoCommunitySizeHint => 'e.g., 500';

  @override
  String get communityInfoExpectedAttendeesLabel => 'EXPECTED ATTENDEES';

  @override
  String get communityInfoExpectedAttendeesHint => 'e.g., 50';

  @override
  String get eventDetailsHeader => 'KOLAB DETAILS';

  @override
  String get eventDetailsSubtitle => 'Describe your kolab and what you offer';

  @override
  String get eventDetailsTitleLabel => 'Title';

  @override
  String get eventDetailsTitleHint => 'e.g., Fitness Community x Local Cafe';

  @override
  String get eventDetailsDescriptionLabel => 'Description';

  @override
  String get eventDetailsDescriptionHint =>
      'Describe what you are looking for and how this kolab would work...';

  @override
  String get eventDetailsOffersHeader => 'WHAT YOU OFFER IN RETURN';

  @override
  String get logisticsAvailabilityHeader => 'AVAILABILITY';

  @override
  String get logisticsAvailabilitySubtitle =>
      'When is your community available for this kolab?';

  @override
  String get logisticsLocationHeader => 'LOCATION';

  @override
  String get logisticsPreferredCityLabel => 'Preferred City';

  @override
  String logisticsCitiesLoadError(String error) {
    return 'Error loading cities: $error';
  }

  @override
  String get logisticsSelectCityHint => 'Select city';

  @override
  String get logisticsPreferredAreaLabel =>
      'Preferred Neighbourhood / Area (optional)';

  @override
  String get logisticsPreferredAreaHint => 'e.g., Shoreditch, Kreuzberg';

  @override
  String get logisticsAvailableFromLabel => 'Available From';

  @override
  String get logisticsAvailableUntilLabel => 'Available Until';

  @override
  String get logisticsTimeLabel => 'Time';

  @override
  String get logisticsDayOfWeekLabel => 'Day of Week';

  @override
  String get logisticsSelectDate => 'Select date';

  @override
  String get logisticsSelectTime => 'Select time';

  @override
  String get photoAddHeader => 'ADD A PHOTO';

  @override
  String get photoAddSubtitle =>
      'This will appear on your kolab card in Explore.';

  @override
  String get photoUseProfilePhoto => 'Use your community profile photo';

  @override
  String get photoDividerOr => 'OR';

  @override
  String get photoChooseFromGallery => 'Choose from gallery or past events';

  @override
  String get photoUploadTitle => 'Upload a photo';

  @override
  String get photoUploadMaxSize => 'Max 5MB';

  @override
  String photoUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get photoPickerSheetTitle => 'Use a gallery or past-event photo';

  @override
  String get photoPickerConfirmLabel => 'Use photo';

  @override
  String get photoUploadedSelectedTitle => 'Uploaded photo selected';

  @override
  String get photoUploadedSelectedSubtitle =>
      'This image will appear on your kolab card in Explore.';

  @override
  String get photoUseProfilePhotoButton => 'Use profile photo';

  @override
  String get photoReplacePhotoButton => 'Replace photo';

  @override
  String get intentSelectionAppBarTitle => 'NEW KOLAB';

  @override
  String get intentSelectionCommunityTitle => 'What would you like to do?';

  @override
  String get intentSelectionBusinessTitle => 'What would you like to promote?';

  @override
  String get intentSelectionCommunitySubtitle =>
      'Choose how you want to kolab with businesses.';

  @override
  String get intentSelectionBusinessSubtitle =>
      'Choose what you want to promote to communities.';

  @override
  String get intentSelectionFindVenueTitle => 'Find a Venue or Sponsor';

  @override
  String get intentSelectionFindVenueSubtitle => 'for my community event';

  @override
  String get intentSelectionBadgeFree => 'FREE';

  @override
  String get intentSelectionPromoteVenueTitle => 'Promote my Venue';

  @override
  String get intentSelectionPromoteVenueSubtitle =>
      'Get communities to host events at your location';

  @override
  String get intentSelectionPromoteProductTitle =>
      'Promote a Product or Service';

  @override
  String get intentSelectionPromoteProductSubtitle =>
      'Get communities to feature your products at their events';

  @override
  String get intentSelectionProfileLoadError => 'Unable to load your profile';

  @override
  String get intentSelectionProfileLoadErrorHint =>
      'Please try again to continue creating a kolab.';

  @override
  String get intentSelectionLockedTitle =>
      'An active subscription is required to create Kolabs.';

  @override
  String get intentSelectionLockedSubtitle =>
      'Upgrade your business plan to publish venue or product opportunities for communities.';

  @override
  String get intentSelectionUpgradeButton => 'Upgrade to create';

  @override
  String get kolabFlowNoIntentSelected => 'No intent selected';

  @override
  String get kolabFlowTitleFindPartner => 'FIND A PARTNER';

  @override
  String get kolabFlowTitlePromoteVenue => 'PROMOTE VENUE';

  @override
  String get kolabFlowTitlePromoteProduct => 'PROMOTE PRODUCT';

  @override
  String get kolabFlowPublishedTitle => 'Kolab Published!';

  @override
  String get kolabFlowDraftSavedTitle => 'Draft Saved!';

  @override
  String get kolabFlowPublishedMessage =>
      'Your kolab is now visible in Explore.';

  @override
  String get kolabFlowDraftSavedMessage => 'You can continue editing later.';

  @override
  String get myKolabsHubTitle => 'MY KOLABS';

  @override
  String get myKolabsHubTabOffers => 'OFFERS';

  @override
  String get myKolabsHubTabRequests => 'REQUESTS';

  @override
  String get myKolabsHubTabActive => 'ACTIVE';

  @override
  String get myKolabsHubTabFinished => 'FINISHED';

  @override
  String get myKolabsHubActiveEmptyTitle => 'No active kolabs';

  @override
  String get myKolabsHubActiveEmptyMessage =>
      'Once an application is accepted by both sides, the kolab shows up here while it\'s underway.';

  @override
  String get myKolabsHubFinishedEmptyTitle => 'Nothing finished yet';

  @override
  String get myKolabsHubFinishedEmptyMessage =>
      'Completed and cancelled kolabs will be collected here.';

  @override
  String get myKolabsHubCreateTooltip => 'Create Kolab';

  @override
  String existingPhotoPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count previously uploaded photos',
      one: '1 previously uploaded photo',
    );
    return 'Select up to $_temp0.';
  }

  @override
  String get existingPhotoPickerEmpty => 'No reusable photos yet.';

  @override
  String get kolabActionBarSaveDraft => 'SAVE DRAFT';

  @override
  String get kolabActionBarPublish => 'PUBLISH';

  @override
  String get kolabReviewSectionTitleDescription => 'Title & Description';

  @override
  String get kolabReviewSectionWhatYouNeed => 'What You Need';

  @override
  String get kolabReviewSectionCommunityInfo => 'Community Info';

  @override
  String get kolabReviewSectionOffersInReturn => 'Offers in Return';

  @override
  String get kolabReviewSectionLocation => 'Location';

  @override
  String get kolabReviewSectionCampaignVenue => 'Campaign & Venue';

  @override
  String get kolabReviewSectionMedia => 'Media';

  @override
  String get kolabReviewSectionWhatYouOffer => 'What You Offer';

  @override
  String get kolabReviewSectionSeekingCommunities => 'Seeking Communities';

  @override
  String get kolabReviewSectionPastEvents => 'Past Events';

  @override
  String get kolabReviewSectionProductInfo => 'Product Info';

  @override
  String get kolabReviewSectionAvailability => 'Availability';

  @override
  String get kolabReviewFieldTitle => 'Title';

  @override
  String get kolabReviewFieldDescription => 'Description';

  @override
  String get kolabReviewFieldTypes => 'Types';

  @override
  String get kolabReviewFieldCommunitySize => 'Community Size';

  @override
  String get kolabReviewFieldTypicalAttendance => 'Typical Attendance';

  @override
  String get kolabReviewFieldCity => 'City';

  @override
  String get kolabReviewFieldArea => 'Area';

  @override
  String get kolabReviewFieldVenue => 'Venue';

  @override
  String get kolabReviewFieldType => 'Type';

  @override
  String get kolabReviewFieldCapacity => 'Capacity';

  @override
  String get kolabReviewFieldAddress => 'Address';

  @override
  String get kolabReviewFieldPhotosVideos => 'Photos / Videos';

  @override
  String get kolabReviewFieldEvents => 'Events';

  @override
  String get kolabReviewFieldName => 'Name';

  @override
  String get kolabReviewFieldSchedule => 'Schedule';

  @override
  String get kolabReviewEmptyNeeds => 'No needs selected';

  @override
  String get kolabReviewEmptyCommunityInfo => 'No community info provided';

  @override
  String get kolabReviewEmptyOffers => 'No offers selected';

  @override
  String get kolabReviewEmptyOfferings => 'No offerings listed';

  @override
  String get kolabReviewEmptyCommunities => 'No communities selected';

  @override
  String get kolabReviewNoMedia => 'No media added';

  @override
  String get kolabReviewNoPastEvents => 'No past events added';

  @override
  String kolabReviewMediaCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewEventsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String kolabReviewAvailabilityFrom(String date) {
    return 'From: $date';
  }

  @override
  String kolabReviewAvailabilityTo(String date) {
    return 'To: $date';
  }

  @override
  String get myKolabCardUntitled => 'Untitled Kolab';

  @override
  String get myKolabCardActionView => 'View';

  @override
  String get myKolabCardActionEdit => 'Edit';

  @override
  String get myKolabCardActionPublish => 'Publish';

  @override
  String get myKolabCardActionClose => 'Close';

  @override
  String get myKolabCardActionDelete => 'Delete';

  @override
  String get myKolabCardStatusPublished => 'PUBLISHED';

  @override
  String get myKolabCardStatusClosed => 'CLOSED';

  @override
  String get myKolabCardStatusCompleted => 'COMPLETED';

  @override
  String get myKolabCardStatusDraft => 'DRAFT';

  @override
  String get profileEventPickerTitle => 'Choose from your profile events';

  @override
  String profileEventPickerSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return 'Select up to $_temp0 to import.';
  }

  @override
  String get profileEventPickerImport => 'Import events';

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get notificationsScreenMarkAllRead => 'Mark all read';

  @override
  String get notificationsScreenEmptyTitle => 'No notifications yet';

  @override
  String get notificationsScreenEmptyBody =>
      'When you receive messages or application updates, they\'ll show up here.';

  @override
  String get notificationBellTooltip => 'Notifications';

  @override
  String get businessFinalEmailRequired => 'Email is required';

  @override
  String get businessFinalEmailInvalid => 'Please enter a valid email';

  @override
  String get businessFinalPasswordRequired => 'Password is required';

  @override
  String get businessFinalPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get businessFinalConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get businessFinalPasswordsMismatch => 'Passwords do not match';

  @override
  String get businessFinalSignupFailed => 'Sign-up failed';

  @override
  String get businessFinalNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get businessFinalErrorCopied => 'Error details copied to clipboard';

  @override
  String get businessFinalCopyDetails => 'Copy details';

  @override
  String get businessFinalTitleAuthenticated => 'FINISH BUSINESS ONBOARDING';

  @override
  String get businessFinalTitleNewAccount => 'CREATE YOUR ACCOUNT';

  @override
  String get businessFinalSubtitleAuthenticated =>
      'Review your imported details one last time and save your business profile.';

  @override
  String get businessFinalSubtitleNewAccount =>
      'Enter your email and password to complete registration';

  @override
  String get businessFinalEdit => 'Edit';

  @override
  String get businessFinalEmailLabel => 'Email';

  @override
  String get businessFinalEmailHint => 'your@email.com';

  @override
  String get businessFinalPasswordLabel => 'Password';

  @override
  String get businessFinalPasswordHint => 'Min. 8 characters';

  @override
  String get businessFinalConfirmPasswordLabel => 'Confirm Password';

  @override
  String get businessFinalConfirmPasswordHint => 'Re-enter your password';

  @override
  String get businessFinalAuthenticatedInfo =>
      'Your account is already created. Tapping the button below will save this onboarding data to the business onboarding endpoint.';

  @override
  String get businessFinalCompleteButton => 'COMPLETE ONBOARDING';

  @override
  String get businessFinalCreateAccountButton => 'CREATE ACCOUNT';

  @override
  String get businessFinalTermsAuthenticated =>
      'We only save the selected Google photos when the onboarding request succeeds.';

  @override
  String get businessFinalTermsNewAccount =>
      'By creating an account, you agree to our Terms of Service and Privacy Policy';

  @override
  String get businessStep2PhotoAccessDenied =>
      'Please allow Photos access in Settings to add venue images.';

  @override
  String get businessStep2PhotoLibraryError =>
      'We could not open your photo library. Please try again.';

  @override
  String get businessStep2IncompleteError =>
      'Complete the required business details, add at least one venue photo, and enter venue capacity before continuing.';

  @override
  String get businessStep2PhoneMustStartPlus =>
      'Must start with + (e.g. +34612345678)';

  @override
  String get businessStep2PhoneDigitsOnly =>
      'Use E.164 format with digits only';

  @override
  String get businessStep2PhoneTooShort => 'Enter at least 9 digits after +';

  @override
  String get businessStep2PhoneTooLong => 'Phone number too long';

  @override
  String get businessStep2Title => 'REVIEW YOUR BUSINESS DETAILS';

  @override
  String get businessStep2Subtitle =>
      'We imported what we could from Google. Review it, fill in capacity, and curate the final venue gallery before you finish.';

  @override
  String get businessStep2ImportedBanner =>
      'Imported from Google. You can edit every field before saving.';

  @override
  String get businessStep2AddLogo => 'Add logo (optional)';

  @override
  String get businessStep2VenueAddressLabel => 'Venue Address';

  @override
  String get businessStep2BusinessNameLabel => 'Business Name';

  @override
  String get businessStep2BusinessNameHint => 'Enter your business name';

  @override
  String get businessStep2BusinessTypeLabel => 'Business Type';

  @override
  String get businessStep2BusinessTypeHint =>
      'Select up to 3 categories that describe your business.';

  @override
  String get businessStep2BusinessTypesLoadError =>
      'Failed to load business types';

  @override
  String get businessStep2VenueTypeLabel => 'Venue Type';

  @override
  String get businessStep2CapacityLabel => 'Capacity';

  @override
  String get businessStep2CapacityHelper =>
      'Google does not provide venue capacity, so you still need to enter it manually.';

  @override
  String get businessStep2CapacityHint => 'How many people can you host?';

  @override
  String get businessStep2VenuePhotosLabel => 'Venue Photos';

  @override
  String get businessStep2AboutLabel => 'About Your Business';

  @override
  String get businessStep2AboutHint => 'Share what makes your business special';

  @override
  String get businessStep2PhoneLabel => 'Phone Number';

  @override
  String get businessStep2InstagramLabel => 'Instagram';

  @override
  String get businessStep2WebsiteLabel => 'Website';

  @override
  String get businessStep2ChangeVenue => 'Change venue';

  @override
  String get businessStep3PhotoAccessDenied =>
      'Please allow Photos access in Settings to add venue images.';

  @override
  String get businessStep3PhotoLibraryError =>
      'We could not open your photo library. Please try again.';

  @override
  String get businessStep3NoPhotosError =>
      'Add at least one venue photo to continue';

  @override
  String get businessStep3Title => 'ADD VENUE PHOTOS';

  @override
  String get businessStep3Subtitle =>
      'These become your reusable venue gallery, so you won’t need to upload them again every time you create a venue Kolab.';

  @override
  String get businessStep3AddPhoto => 'Add Photo';

  @override
  String get businessStep5PickAddressError =>
      'Pick your venue address from the suggestions';

  @override
  String get businessStep5ImportFallback =>
      'We couldn\'t import from Google, please fill in manually.';

  @override
  String get businessStep5Title => 'CHOOSE YOUR VENUE';

  @override
  String get businessStep5Subtitle =>
      'Search for your business venue and we will import the details we can from Google before you review them.';

  @override
  String get businessStep5SearchHint => 'Search venue address';

  @override
  String get businessStep5HintStartTyping =>
      'Start typing your venue address to see suggestions.';

  @override
  String get businessStep5HintNoMatches =>
      'No matches yet. Try adding the city to the address.';

  @override
  String get businessStep5SuggestionsError =>
      'We could not load venue suggestions right now.';

  @override
  String get businessStep5Importing =>
      'Importing your business info from Google';

  @override
  String get businessStep5PreviewTitle => 'PHOTOS FROM GOOGLE';

  @override
  String get businessStep5PreviewSubtitle =>
      'We imported these photos for your venue. Tap the X to remove any you do not want before continuing. You can add your own later.';

  @override
  String get businessStep5NoPhotosLeft =>
      'No photos left. Continue to add your own, or go back to pick a different venue.';

  @override
  String get businessStep5SelectedAddress => 'Selected address';

  @override
  String get communityFinalTitle => 'CREATE YOUR ACCOUNT';

  @override
  String get communityFinalSubtitle =>
      'Enter your email and password to complete registration';

  @override
  String get communityFinalEdit => 'Edit';

  @override
  String get communityFinalEmailLabel => 'Email';

  @override
  String get communityFinalEmailHint => 'your@email.com';

  @override
  String get communityFinalPasswordLabel => 'Password';

  @override
  String get communityFinalPasswordHint => 'Min. 8 characters';

  @override
  String get communityFinalConfirmPasswordLabel => 'Confirm Password';

  @override
  String get communityFinalConfirmPasswordHint => 'Re-enter your password';

  @override
  String get communityFinalEmailRequired => 'Email is required';

  @override
  String get communityFinalEmailInvalid => 'Please enter a valid email';

  @override
  String get communityFinalPasswordRequired => 'Password is required';

  @override
  String get communityFinalPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get communityFinalConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get communityFinalPasswordsMismatch => 'Passwords do not match';

  @override
  String get communityFinalNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get communityFinalCreateAccountButton => 'CREATE ACCOUNT';

  @override
  String get communityFinalTermsNotice =>
      'By creating an account, you agree to our Terms of Service and Privacy Policy';

  @override
  String get communityStep1Title => 'TELL US ABOUT YOU';

  @override
  String get communityStep1Subtitle => 'Let\'s create your profile';

  @override
  String get communityStep1DisplayNameLabel => 'Display Name';

  @override
  String get communityStep1NameHint => 'Your name or handle';

  @override
  String get communityStep1NameRequired => 'Please enter your display name';

  @override
  String get communityStep2Title => 'What type of community are you?';

  @override
  String get communityStep2Subtitle =>
      'Help businesses understand your community';

  @override
  String get communityStep2TypeRequired => 'Please select a community type';

  @override
  String get communityStep2LoadError => 'Failed to load community types';

  @override
  String get communityStep3Title => 'WHERE ARE YOU LOCATED?';

  @override
  String get communityStep3Subtitle => 'Find opportunities in your area';

  @override
  String get communityStep3SearchHint => 'Search cities...';

  @override
  String get communityStep3PopularCities => 'Popular Cities:';

  @override
  String get communityStep3NoCitiesFound => 'No cities found';

  @override
  String get communityStep3LoadError => 'Failed to load cities';

  @override
  String get communityStep3CityRequired => 'Please select a city';

  @override
  String get communityStep4Title => 'COMPLETE YOUR PROFILE';

  @override
  String get communityStep4Subtitle => 'Add your social links (all optional)';

  @override
  String get communityStep4AboutLabel => 'About / Bio';

  @override
  String get communityStep4AboutHint => 'Tell us about yourself...';

  @override
  String get communityStep4UsernameHint => 'username';

  @override
  String get communityStep4WebsiteLabel => 'Website';

  @override
  String get communityStep4WebsiteHint => 'www.example.com';

  @override
  String get photoUploadFileTooLarge => 'Image must be less than 5MB';

  @override
  String get photoUploadSelectFailed => 'Failed to select image';

  @override
  String get photoUploadSelectFailedRetry =>
      'Failed to select image. Please try again.';

  @override
  String get photoUploadPhotosAccessDenied =>
      'Please allow Photos access in Settings to upload an image.';

  @override
  String get photoUploadCameraAccessDenied =>
      'Please allow Camera access in Settings to take a photo.';

  @override
  String get photoUploadChooseLibrary => 'Choose from Library';

  @override
  String get photoUploadTakePhoto => 'Take Photo';

  @override
  String get photoUploadChangePhoto => 'Change Photo';

  @override
  String get photoUploadRemovePhoto => 'Remove Photo';

  @override
  String get photoUploadTapToChange => 'Tap to change';

  @override
  String get venuePhotoAddPhoto => 'Add photo';

  @override
  String get venuePhotoPoweredByGoogle => 'Powered by Google';

  @override
  String get venuePhotoEmptyTitle => 'Add venue photos';

  @override
  String get venuePhotoEmptyDescription =>
      'Keep imported Google photos, upload your own, remove what you do not want, and set the final order here.';

  @override
  String get venuePhotoSourceGoogle => 'Google import';

  @override
  String get venuePhotoSourceSaved => 'Saved photo';

  @override
  String get venuePhotoSourceUpload => 'Upload';

  @override
  String venuePhotoPositionLabel(num position, num total) {
    return 'Photo $position of $total';
  }

  @override
  String get venuePhotoMoveEarlier => 'Move earlier';

  @override
  String get venuePhotoMoveLater => 'Move later';

  @override
  String get venuePhotoRemovePhoto => 'Remove photo';

  @override
  String get venuePhotoCredits => 'Photo credits';

  @override
  String get venuePhotoCreditsSheetTitle => 'Google photo credits';

  @override
  String get profileReviewsTitle => 'Reviews';

  @override
  String profileReviewsTitleNamed(String name) {
    return '$name Reviews';
  }

  @override
  String get profileReviewsLoadError => 'Could not load reviews.';

  @override
  String get profileReviewsEmpty => 'No reviews yet.';

  @override
  String get profileReviewsLoadMore => 'Load more';

  @override
  String get publicProfileAbout => 'About';

  @override
  String get publicProfileLoadError => 'Failed to load profile';

  @override
  String get publicProfilePastKolabs => 'Past Kolabs';

  @override
  String get publicProfileNoPastKolabs => 'No past kolabs yet';

  @override
  String get publicProfileSocialLinks => 'Social Links';

  @override
  String get publicProfileSaveForLater => 'Save for later';

  @override
  String get publicProfileSendKolabProposal => 'SEND A KOLAB PROPOSAL';

  @override
  String get publicProfileRecentReviews => 'Recent Reviews';

  @override
  String get publicProfileViewMore => 'View more';

  @override
  String get referralCodeCopied => 'Referral code copied';

  @override
  String get referralScreenTitle => 'REFERRAL PROGRAM';

  @override
  String get referralScreenYourCode => 'YOUR REFERRAL CODE';

  @override
  String get referralScreenCopyCode => 'COPY CODE';

  @override
  String get referralScreenShareCode => 'SHARE CODE';

  @override
  String get referralScreenHowItWorks => 'HOW IT WORKS';

  @override
  String get referralScreenStep1Title => 'Share your unique code';

  @override
  String get referralScreenStep1Desc =>
      'Send your referral code to friends and colleagues.';

  @override
  String get referralScreenStep2Title =>
      'A business subscribes using your code';

  @override
  String get referralScreenStep2Desc =>
      'When they sign up and choose a plan, they enter your code.';

  @override
  String get referralScreenStep3TitleBusiness =>
      'You earn 1 free month of subscription';

  @override
  String get referralScreenStep3TitleCommunity =>
      'You earn 50-100 points (EUR 10-EUR 20)';

  @override
  String get referralScreenStep3DescBusiness =>
      'Your next billing cycle is automatically extended.';

  @override
  String get referralScreenStep3DescCommunity =>
      'Points are added to your wallet and can be withdrawn.';

  @override
  String get referralScreenRewardTiers => 'REWARD TIERS';

  @override
  String get referralScreenTierBusinessCondition => 'Each successful referral';

  @override
  String get referralScreenTierBusinessReward => '1 free month';

  @override
  String get referralScreenTier1MonthCondition => 'Referred user stays 1 month';

  @override
  String get referralScreenTier1MonthReward => '50 pts (EUR 10)';

  @override
  String get referralScreenTier4MonthCondition =>
      'Referred user stays 4 months';

  @override
  String get referralScreenTier4MonthReward => '100 pts (EUR 20)';

  @override
  String get walletScreenTitle => 'XP & REPUTATION';

  @override
  String get walletScreenWaysToEarn => 'WAYS TO EARN XP';

  @override
  String get walletScreenBadges => 'BADGES';

  @override
  String get walletScreenCashReferral => 'CASH REFERRAL';

  @override
  String get walletScreenXpHistory => 'XP HISTORY';

  @override
  String get walletScreenXpPoints => 'XP POINTS';

  @override
  String walletScreenTotalXp(num count) {
    return 'Total XP: $count';
  }

  @override
  String walletScreenXpToNext(num count, String tier) {
    return '$count XP to $tier';
  }

  @override
  String walletScreenXpGain(num count) {
    return '+$count XP';
  }

  @override
  String walletScreenXpAmount(num count) {
    return '$count XP';
  }

  @override
  String get walletScreenMissionCompleteKolab => 'Complete a kolab';

  @override
  String get walletScreenMissionPostReview => 'Post a review';

  @override
  String get walletScreenMissionShareContent => 'Share content (UGC)';

  @override
  String get walletScreenMissionReferBusiness => 'Refer a business';

  @override
  String get walletScreenNoBadges => 'No badges available';

  @override
  String get walletScreenEarnCashTitle => 'Earn €75 Cash';

  @override
  String get walletScreenEarnCashSubtitle =>
      'Refer 3 businesses on a 4-month plan';

  @override
  String get walletScreenMilestoneReached =>
      'Milestone reached! Request your cash reward.';

  @override
  String walletScreenMilestoneProgress(
    num conversions,
    num goal,
    num remaining,
  ) {
    return '$conversions / $goal businesses referred · $remaining more to go';
  }

  @override
  String walletScreenShareMessage(String code) {
    return 'Join Kolabing with my code: $code';
  }

  @override
  String get walletScreenShareLink => 'SHARE LINK';

  @override
  String get walletScreenRequestCash => 'REQUEST €75';

  @override
  String get walletScreenNoXpActivity =>
      'No XP activity yet — complete a kolab!';

  @override
  String get walletScreenLoadMore => 'LOAD MORE';

  @override
  String get withdrawalScreenTitle => 'WITHDRAW';

  @override
  String get withdrawalRequestFailed => 'Withdrawal request failed';

  @override
  String get withdrawalIbanRequired => 'IBAN is required';

  @override
  String get withdrawalIbanInvalid =>
      'Please enter a valid IBAN (15-34 characters)';

  @override
  String get withdrawalAccountHolderRequired =>
      'Account holder name is required';

  @override
  String get withdrawalSuccessTitle => 'Request Submitted';

  @override
  String get withdrawalSuccessMessage =>
      'Your withdrawal request has been submitted successfully. Processing within 5-7 business days.';

  @override
  String get withdrawalBackToWallet => 'BACK TO WALLET';

  @override
  String get withdrawalAvailableLabel => 'Available to withdraw';

  @override
  String get withdrawalIbanLabel => 'IBAN';

  @override
  String get withdrawalIbanHint => 'e.g. DE89 3704 0044 0532 0130 00';

  @override
  String get withdrawalAccountHolderLabel => 'ACCOUNT HOLDER NAME';

  @override
  String get withdrawalAccountHolderHint => 'Full name on bank account';

  @override
  String withdrawalSubmitButton(String amount) {
    return 'WITHDRAW EUR $amount';
  }

  @override
  String get referralBannerEarnBySharing => 'EARN BY SHARING';

  @override
  String get referralBannerTagline => 'Refer 3 businesses → earn €75 cash';

  @override
  String get referralBannerShareButton => 'SHARE REFERRAL CODE';

  @override
  String get referralSheetYourCode => 'YOUR REFERRAL CODE';

  @override
  String get referralSheetInstructions =>
      'Ask businesses to use this code during signup.';

  @override
  String get referralSheetCopyCode => 'COPY CODE';

  @override
  String get referralSheetShareCode => 'SHARE CODE';

  @override
  String get referralSheetShareUnavailable =>
      'Sharing is unavailable. Referral code copied.';

  @override
  String get referralSheetShareFailed =>
      'Could not open share sheet. Referral code copied.';

  @override
  String get themeSelectorTitle => 'Appearance';

  @override
  String get themeSelectorSystemLabel => 'System';

  @override
  String get themeSelectorSystemDescription => 'Follow device settings';

  @override
  String get themeSelectorLightLabel => 'Light';

  @override
  String get themeSelectorLightDescription => 'Always use light theme';

  @override
  String get themeSelectorDarkLabel => 'Dark';

  @override
  String get themeSelectorDarkDescription => 'Always use dark theme';

  @override
  String get referralCodeFieldLabel => 'Referral Code (optional)';

  @override
  String get referralCodeFieldHint => 'Paste referral code';

  @override
  String get discoveryQuickFilterCity => 'City';

  @override
  String get discoveryQuickFilterKolabType => 'Kolab Type';

  @override
  String get discoveryQuickFilterWhatTheyOffer => 'What They Offer';

  @override
  String get discoveryQuickFilterAvailability => 'Availability';

  @override
  String get discoveryQuickFilterNeed => 'Offer';

  @override
  String get discoveryQuickFilterCommunityType => 'Community Type';

  @override
  String get discoveryQuickFilterAudienceSize => 'Audience Size';

  @override
  String get profileGallerySectionTitle => 'Gallery';

  @override
  String get profileGallerySectionAdd => 'Add';

  @override
  String get profileGallerySectionUploading => 'Uploading photo...';

  @override
  String get profileGallerySheetTitle => 'Add Gallery Photo';

  @override
  String get profileGallerySheetTakePhoto => 'Take Photo';

  @override
  String get profileGallerySheetTakePhotoSubtitle => 'Use your camera';

  @override
  String get profileGallerySheetChooseGallery => 'Choose from Gallery';

  @override
  String get profileGallerySheetChooseGallerySubtitle =>
      'Select an existing photo';

  @override
  String get profileGalleryEmptyTitleBusiness => 'Showcase your venue';

  @override
  String get profileGalleryEmptyTitleCommunity => 'Showcase your community';

  @override
  String get profileGalleryEmptyBodyBusiness =>
      'Add venue photos so kolab partners can see your space before they apply.';

  @override
  String get profileGalleryEmptyBodyCommunity =>
      'Add photos from your events so new kolab partners understand your community.';

  @override
  String get profileGalleryDeleteTitle => 'Delete Photo';

  @override
  String get profileGalleryDeleteBody =>
      'Are you sure you want to remove this photo?';

  @override
  String get profileGalleryDeleteConfirm => 'Delete';

  @override
  String get exploreFilterSearchHint =>
      'Search by title, description, or creator...';

  @override
  String get exploreFilterCity => 'City';

  @override
  String get exploreFilterCityHint => 'Type a city';

  @override
  String get exploreFilterAvailability => 'Availability';

  @override
  String get exploreFilterKolabType => 'Kolab Type';

  @override
  String get exploreFilterWhatTheyOffer => 'What They Offer';

  @override
  String get exploreFilterVenueType => 'Venue Type';

  @override
  String get exploreFilterProductType => 'Product Type';

  @override
  String get exploreFilterExpectedDeliverables => 'Expected Deliverables';

  @override
  String get exploreFilterMinCommunitySize =>
      'Minimum Community Size Requirement';

  @override
  String get exploreFilterNeed => 'Offer';

  @override
  String get exploreFilterCommunityType => 'Community Type';

  @override
  String get exploreFilterAudienceSize => 'Audience Size';

  @override
  String get exploreFilterOffersInReturn => 'Offers In Return';

  @override
  String get exploreFilterVenuePreference => 'Venue Preference';

  @override
  String get exploreFilterTitle => 'Search & Filter';

  @override
  String get exploreFilterClearAll => 'Clear all';

  @override
  String get exploreFilterNoMatchingCities => 'No matching cities found';

  @override
  String get exploreFilterCitySuggestionsError =>
      'Could not load city suggestions';

  @override
  String exploreFilterResultsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results found',
      one: '1 result found',
      zero: 'Showing all opportunities',
    );
    return '$_temp0';
  }

  @override
  String exploreSwipeCardMatch(num score) {
    return '$score% match';
  }

  @override
  String get exploreSwipeCardBusinessOffer => 'Business Offer';

  @override
  String get exploreSwipeCardCommunityRequest => 'Community Request';

  @override
  String exploreSwipeCardKolabsCount(num count) {
    return '$count Kolabs';
  }

  @override
  String exploreSwipeCardPreviousKolabs(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count previous Kolabs',
      one: '1 previous Kolab',
    );
    return '$_temp0';
  }

  @override
  String get exploreSwipeCardViewDetails => 'View Details';

  @override
  String get exploreDetailUnknownCreator => 'Unknown';

  @override
  String get exploreDetailSubscribeToReveal =>
      'Subscribe to reveal this community';

  @override
  String get exploreDetailCreatorBadge => 'Creator';

  @override
  String get exploreDetailLookingFor => 'What they are looking for';

  @override
  String get exploreDetailWhatTheyOffer => 'What they offer';

  @override
  String get exploreDetailCommunitySize => 'Community size';

  @override
  String exploreDetailScaleCommunity(num count) {
    return '$count community';
  }

  @override
  String exploreDetailScaleExpected(num count) {
    return '$count expected';
  }

  @override
  String get exploreDetailWhatsOffered => 'What\'s Offered';

  @override
  String get exploreDetailAvailableDays => 'Available Days';

  @override
  String get exploreDetailUnlockToApply => 'UNLOCK TO APPLY';

  @override
  String get exploreDetailApplyNow => 'APPLY NOW';

  @override
  String get exploreDetailViewCreatorProfile => 'View creator profile';

  @override
  String get exploreDetailPastEventPhotos => 'Past event photos';

  @override
  String get exploreDetailRecentMoments => 'Recent moments from this community';

  @override
  String get subscriptionScreenTitle => 'Subscription';

  @override
  String get subscriptionScreenAppleError =>
      'Failed to start App Store purchase';

  @override
  String get subscriptionScreenCheckoutError =>
      'Failed to create checkout session';

  @override
  String get subscriptionReferralCodeApplied => 'Referral code applied.';

  @override
  String get subscriptionReactivateSuccess =>
      'Subscription reactivated successfully';

  @override
  String get subscriptionCancelScheduledToast =>
      'Subscription will cancel at the end of billing period';

  @override
  String get subscriptionCancelDialogTitle => 'Cancel Subscription';

  @override
  String get subscriptionCancelDialogBody =>
      'Your subscription will remain active until the end of the current billing period. You can resubscribe at any time.\n\nAre you sure you want to cancel?';

  @override
  String get subscriptionKeepButton => 'Keep Subscription';

  @override
  String get subscriptionCancelButton => 'Cancel Subscription';

  @override
  String get subscriptionStatusPremiumTitle => 'Premium Business';

  @override
  String get subscriptionStatusActiveSubtitle => 'Your subscription is active';

  @override
  String get subscriptionStatusEndingTitle => 'Subscription Ending';

  @override
  String get subscriptionStatusEndingSubtitle =>
      'Active until end of billing period';

  @override
  String get subscriptionStatusPastDueTitle => 'Payment Failed';

  @override
  String get subscriptionStatusPastDueSubtitle =>
      'Please update your payment method';

  @override
  String get subscriptionStatusNoPlanTitle => 'No Active Plan';

  @override
  String get subscriptionStatusNoPlanSubtitle =>
      'Subscribe to publish opportunities';

  @override
  String get subscriptionBenefitsTitle => 'Premium Benefits';

  @override
  String get subscriptionBenefitPublishTitle => 'Publish Opportunities';

  @override
  String get subscriptionBenefitPublishDesc =>
      'Create and publish kolab offers';

  @override
  String get subscriptionBenefitConnectTitle => 'Connect with Communities';

  @override
  String get subscriptionBenefitConnectDesc =>
      'Reach local communities and creators';

  @override
  String get subscriptionBenefitApplicationsTitle => 'Receive Applications';

  @override
  String get subscriptionBenefitApplicationsDesc =>
      'Get applications from interested communities';

  @override
  String get subscriptionBenefitTrackTitle => 'Track Performance';

  @override
  String get subscriptionBenefitTrackDesc => 'Monitor your kolab metrics';

  @override
  String get subscriptionPerMonthUnit => 'EUR/month';

  @override
  String get subscriptionPlanDetailsTitle => 'Plan Details';

  @override
  String get subscriptionDetailPlanLabel => 'Plan';

  @override
  String get subscriptionDetailPriceLabel => 'Price';

  @override
  String get subscriptionPriceMonthly => '29 EUR/month';

  @override
  String get subscriptionDetailCurrentPeriodLabel => 'Current Period';

  @override
  String get subscriptionDetailRenewsOnLabel => 'Renews On';

  @override
  String get subscriptionDetailDaysRemainingLabel => 'Days Remaining';

  @override
  String subscriptionDaysValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionPastDueWarningBody =>
      'Your last payment failed. Update your payment method to continue publishing opportunities.';

  @override
  String get subscriptionCancelPendingTitle => 'Cancellation Scheduled';

  @override
  String subscriptionCancelPendingBody(String endDate) {
    return 'Your subscription is active until $endDate. After that, you will not be able to publish new opportunities.';
  }

  @override
  String get subscriptionEndOfBillingPeriod => 'end of billing period';

  @override
  String get subscriptionReactivateButton => 'REACTIVATE SUBSCRIPTION';

  @override
  String get subscriptionSubscribeButton => 'SUBSCRIBE';

  @override
  String get subscriptionSubscribePricedButton => 'SUBSCRIBE FOR 29 EUR/MONTH';

  @override
  String get subscriptionUpdatePaymentButton => 'UPDATE PAYMENT METHOD';

  @override
  String get subscriptionManageBillingButton => 'MANAGE BILLING';

  @override
  String get subscriptionLoadingApplePrice => 'Loading App Store price...';

  @override
  String get subscriptionUnavailable => 'Subscription unavailable';

  @override
  String subscriptionPricePerMonth(String price) {
    return '$price/month';
  }

  @override
  String get subscriptionPaywallAppleError =>
      'Failed to start App Store purchase';

  @override
  String get subscriptionPaywallCheckoutError =>
      'Failed to create checkout session';

  @override
  String get subscriptionPaywallTitle => 'Upgrade to Premium';

  @override
  String get subscriptionPaywallDescription =>
      'You\'ve used your 1 free kolab request. Subscribe to create unlimited requests and connect with more communities.';

  @override
  String get subscriptionPaywallBenefitUnlimited =>
      'Publish unlimited kolab requests';

  @override
  String get subscriptionPaywallBenefitConnect =>
      'Connect with local communities';

  @override
  String get subscriptionPaywallBenefitApplications =>
      'Receive and manage applications';

  @override
  String get subscriptionPaywallPerMonth => '/ month';

  @override
  String get subscriptionPaywallSubscribeButton => 'SUBSCRIBE NOW';

  @override
  String get subscriptionPaywallNotNowButton => 'Not Now';

  @override
  String get subscriptionRestorePurchasesButton => 'Restore Purchases';

  @override
  String get pastEventsStepHeader => 'PAST KOLABS (OPTIONAL)';

  @override
  String referralShareMessage(String code) {
    return 'Share Kolabing and earn — register your business with my referral code $code during signup.';
  }

  @override
  String get dashboardBusinessTitle => 'BUSINESS DASHBOARD';

  @override
  String get dashboardCommunityTitle => 'COMMUNITY DASHBOARD';

  @override
  String dashboardWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get dashboardErrorLoad => 'Unable to load dashboard data';

  @override
  String get dashboardStatPublished => 'Published';

  @override
  String get dashboardStatPendingApplications => 'Pending Applications';

  @override
  String get dashboardStatActiveKolabs => 'Active Kolabs';

  @override
  String get dashboardStatCompleted => 'Completed';

  @override
  String get dashboardStatPending => 'Pending';

  @override
  String get dashboardStatAccepted => 'Accepted';

  @override
  String get dashboardCreateKolabRequest => 'CREATE KOLAB REQUEST';

  @override
  String get dashboardFindAKolab => 'FIND A KOLAB';

  @override
  String get dashboardMyApplications => 'MY APPLICATIONS';

  @override
  String get dashboardUpcomingKolabs => 'UPCOMING KOLABS';

  @override
  String get dashboardNoUpcomingKolabs => 'No upcoming kolabs yet';

  @override
  String get dashboardDefaultBusinessName => 'Business';

  @override
  String get dashboardDefaultCommunityName => 'Community';

  @override
  String get eventHubOpenChat => 'Open event chat';

  @override
  String get eventHubAttendeesTitle => 'Attendees';

  @override
  String get eventHubWaitlistTitle => 'Waitlist';

  @override
  String get eventHubNoAttendees => 'No one has signed up yet.';

  @override
  String eventHubGoingCount(num count) {
    return '$count going';
  }

  @override
  String eventHubWaitlistCount(num count) {
    return '$count on waitlist';
  }

  @override
  String eventHubCapacity(num count) {
    return 'capacity $count';
  }

  @override
  String eventHubSpotsLeft(num count) {
    return '$count spot(s) left';
  }

  @override
  String get eventHubUnlimited => 'Unlimited';

  @override
  String get eventHubImGoing => 'I\'m going';

  @override
  String get eventHubGoingTapToLeave => 'Going ✓  ·  tap to leave';

  @override
  String get eventHubJoinWaitlist => 'Join waitlist';

  @override
  String get eventHubOnWaitlistTapToLeave => 'On waitlist  ·  tap to leave';

  @override
  String eventHubWaitlistPosition(num position) {
    return 'You\'re #$position on the waitlist';
  }

  @override
  String get eventHubEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get eventHubDelete => 'Delete event';

  @override
  String get eventHubDeleteConfirmTitle => 'Delete this event?';

  @override
  String eventHubDeleteConfirmBody(String name) {
    return '\"$name\" — anyone going or waitlisted will be notified it\'s cancelled.';
  }

  @override
  String get eventHubDeleteScopeThis => 'This event only';

  @override
  String get eventHubDeleteScopeFollowing => 'This and the following events';

  @override
  String get eventHubDeleteScopeSeries => 'The entire series';

  @override
  String get eventHubDeleted => 'Event deleted';

  @override
  String get eventHubExtendSeries => 'Extend series (+3 months)';

  @override
  String eventHubExtended(int count) {
    return 'Series extended — $count new dates';
  }

  @override
  String get eventHubExtendedNone => 'No new dates to add';

  @override
  String get eventHubAddPhotos => 'Add photos';

  @override
  String get eventFormNewTitle => 'New event';

  @override
  String get eventFormEditTitle => 'Edit event';

  @override
  String get eventFormSave => 'Save';

  @override
  String get eventFormPublish => 'Publish event';

  @override
  String get eventFormRepeatLabel => 'Repeat';

  @override
  String get eventFormRepeatNone => 'Doesn\'t repeat';

  @override
  String get eventFormRepeatWeekly => 'Weekly';

  @override
  String get eventFormRepeatBiweekly => 'Every 2 weeks';

  @override
  String get eventFormRepeatMonthly => 'Monthly';

  @override
  String get eventFormRepeatEnds => 'Ends';

  @override
  String get eventFormRepeatNever => 'Never';

  @override
  String get eventFormRepeatAfter => 'After';

  @override
  String get eventFormRepeatEvents => 'events';

  @override
  String get eventFormRepeatOnDate => 'On date';

  @override
  String get eventFormRepeatChatLabel => 'Chat for this series';

  @override
  String get eventFormRepeatChatPerEvent => 'One chat per event';

  @override
  String get eventFormRepeatChatShared => 'One shared series chat';

  @override
  String get eventFormPublishSeries => 'Publish series';

  @override
  String get eventFormApplyTo => 'Apply changes to';

  @override
  String get eventFormErrWeekday => 'Pick at least one day';

  @override
  String get eventFormErrEndsCount => 'Enter how many events';

  @override
  String get eventFormErrEndsOn => 'Pick an end date after the start';

  @override
  String get eventFormNameLabel => 'Name';

  @override
  String get eventFormNameHint => 'Saturday 10K';

  @override
  String get eventFormStartsLabel => 'Starts';

  @override
  String get eventFormEndsLabel => 'Ends (optional)';

  @override
  String get eventFormPickStart => 'Pick start date & time';

  @override
  String get eventFormPickEnd => 'Pick end date & time';

  @override
  String get eventFormLocationLabel => 'Location (optional)';

  @override
  String get eventFormLocationHint => 'Ciutadella Park';

  @override
  String get eventFormCapacityLabel => 'Capacity (optional)';

  @override
  String get eventFormLimit => 'Limit';

  @override
  String get eventFormWhoCanJoin => 'Who can join';

  @override
  String get eventFormAllMembers => 'All members';

  @override
  String get eventFormSelectedTiers => 'Selected tiers';

  @override
  String get eventFormPhotos => 'Photos';

  @override
  String get eventFormAddFromGallery => 'Add from gallery';

  @override
  String get eventFormPhotosAfterCreate =>
      'Photos can be added once the event is created.';

  @override
  String get eventFormErrName => 'Event name needs at least 3 characters.';

  @override
  String get eventFormErrStart => 'Pick a start date & time.';

  @override
  String get eventFormErrStartFuture => 'Start must be in the future.';

  @override
  String get eventFormErrEndAfterStart => 'End must be after the start.';

  @override
  String get eventFormErrCapacity =>
      'Enter a valid capacity, or turn off the limit.';

  @override
  String get eventFormPhotosUploaded => 'Photos uploaded.';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String get notifSettingsMessages => 'Messages';

  @override
  String get notifSettingsMessagesSubtitle =>
      'New chat messages in your communities and events';

  @override
  String get notifSettingsApplications => 'New applications';

  @override
  String get notifSettingsApplicationsSubtitle =>
      'When someone applies to your Kolab';

  @override
  String get notifSettingsCollaborations => 'Collaboration updates';

  @override
  String get notifSettingsCollaborationsSubtitle =>
      'Status changes on your Kolabs';

  @override
  String get notifSettingsMarketing => 'Tips & updates';

  @override
  String get notifSettingsMarketingSubtitle =>
      'Occasional product tips and news';

  @override
  String get notifSettingsSaveError =>
      'Could not save your preference. Try again.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatInboxTooltip => 'Chats';

  @override
  String get chatThreadFallbackTitle => 'Chat';

  @override
  String get chatThreadTapToOpen => 'Tap to open';

  @override
  String get chatThreadNoMessagesYet => 'No messages yet';

  @override
  String get chatInboxEmptyTitle => 'No chats yet';

  @override
  String get chatInboxEmptyBody =>
      'Conversations show up here once a Kolab, community, or event chat gets going.';

  @override
  String get chatSectionMain => 'Main';

  @override
  String get chatSectionCommunityChats => 'Community chats';

  @override
  String get chatSectionEvents => 'Events';

  @override
  String get chatSectionKolabs => 'Kolabs';

  @override
  String get chatComposerHint => 'Message';

  @override
  String get chatThreadEmptyMessage => 'No messages yet. Say hi 👋';

  @override
  String get communityDetailTabChats => 'Chats';

  @override
  String get communityDetailTabEvents => 'Events';

  @override
  String get communityDetailTabMembers => 'Members';

  @override
  String get communityDetailTabDetails => 'Details';

  @override
  String communityDetailTypeAndMembers(String type, int count) {
    return '$type · $count members';
  }

  @override
  String communityDetailMembersCount(int count) {
    return '$count members';
  }

  @override
  String get communityDetailChatsLoadError => 'Could not load chats';

  @override
  String get communityDetailNoChatsTitle => 'No chats yet';

  @override
  String get communityDetailNoChatsBody =>
      'This community’s conversations show up here.';

  @override
  String get communityDetailNoEventsTitle => 'No upcoming events';

  @override
  String get communityDetailNoEventsBody =>
      'Events created for this community will show here.';

  @override
  String get communityDetailEventLockedSubtitle =>
      'Locked — for another membership tier';

  @override
  String get communityDetailEventLockedSnack =>
      'This event is for a different membership tier.';

  @override
  String get communityDetailLeaderboardButton => 'Chapter leaderboard';

  @override
  String get communityDetailAboutLabel => 'About';

  @override
  String get communityDetailMembershipLabel => 'Your membership';

  @override
  String get communityDetailRowTier => 'Tier';

  @override
  String get communityDetailRowType => 'Type';

  @override
  String get communityDetailRowMembers => 'Members';

  @override
  String get communityDetailRowRole => 'Role';

  @override
  String get communityDetailRoleCanManage => 'Can manage';

  @override
  String get communityDetailTierFallback => 'Member';

  @override
  String get communityDetailGalleryLabel => 'Gallery & past events';

  @override
  String get communityDetailGalleryBody =>
      'Photos and past events will live here once the events lifecycle ships (Phase 3).';

  @override
  String get myCommunitiesNoTier => 'No tier yet';

  @override
  String get myCommunitiesAdminBadge => 'ADMIN';

  @override
  String get myCommunitiesEmptyTitle => 'You\'re not in any communities yet';

  @override
  String get myCommunitiesEmptyBody =>
      'Join a community to earn your place on its tiers and see member-only events and perks.';

  @override
  String get communityHubEmptyTitle => 'Start your community';

  @override
  String get communityHubEmptyBody =>
      'Create a community to build a member roster and set up your own tiers. Your first community is free.';

  @override
  String get communityHubCreateCommunity => 'CREATE COMMUNITY';

  @override
  String get communityHubSectionTiers => 'Tiers';

  @override
  String get communityHubSectionMembers => 'Members';

  @override
  String get communityHubSectionEvents => 'Events';

  @override
  String get communityHubSectionChats => 'Chats';

  @override
  String communityHubTypeAndMembers(String type, int count) {
    return '$type  ·  $count members';
  }

  @override
  String get communityHubNoEvents => 'No upcoming events yet.';

  @override
  String get communityHubCreateEvent => 'Create event';

  @override
  String get communityHubNewChatTitle => 'New chat';

  @override
  String get communityHubChatNameLabel => 'Chat name';

  @override
  String get communityHubChatNameHint => 'e.g. Exec, Socials, Philanthropy';

  @override
  String get communityHubCreate => 'Create';

  @override
  String communityHubChatCreated(String name) {
    return '\"$name\" created';
  }

  @override
  String communityHubChatLimit(int count) {
    return 'You can have up to $count chats';
  }

  @override
  String get communityHubAccess => 'Access';

  @override
  String get chatManageRename => 'Rename chat';

  @override
  String get chatManageDelete => 'Delete chat';

  @override
  String get chatManageAccess => 'Who can access';

  @override
  String get chatManageMembers => 'Members';

  @override
  String get chatBlock => 'Block';

  @override
  String get chatUnblock => 'Unblock';

  @override
  String get chatBlockedTag => 'Blocked';

  @override
  String get chatMembersEmpty => 'No members have access yet.';

  @override
  String get chatRenameHint => 'Chat name';

  @override
  String get chatRenamed => 'Chat renamed';

  @override
  String get chatDeleteTitle => 'Delete this chat?';

  @override
  String chatDeleteBody(String name) {
    return 'All messages in \"$name\" will be removed.';
  }

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get communityHubAccessNoTiers => 'No tiers';

  @override
  String get communityHubAccessAllTiers => 'All tiers';

  @override
  String get communityHubAccessOneTier => '1 tier';

  @override
  String communityHubAccessTierCount(int count) {
    return '$count tiers';
  }

  @override
  String get communityHubCreateTiersFirst =>
      'Create membership tiers first to gate chats.';

  @override
  String communityHubAccessDialogTitle(String name) {
    return 'Who can access \"$name\"?';
  }

  @override
  String get communityHubAccessDialogChat => 'chat';

  @override
  String get communityHubAccessDialogBody =>
      'You and your managers always have access. Choose which member tiers can open this chat.';

  @override
  String get communityHubChatAccessUpdated => 'Chat access updated';

  @override
  String communityHubNoChatsHint(int count) {
    return 'No chats yet. Your main chat + up to $count custom chats live here.';
  }

  @override
  String get communityHubCreateChat => 'Create chat';

  @override
  String communityHubChatLimitReached(int count) {
    return 'Chat limit reached ($count custom chats).';
  }

  @override
  String get communityHubChatMain => 'Main';

  @override
  String get communityHubChatFallback => 'Chat';

  @override
  String get communityHubChipMain => 'MAIN';

  @override
  String communityHubTierDetail(String rule, int threshold, String unit) {
    return '$rule · $threshold $unit';
  }

  @override
  String get communityHubChipDefault => 'DEFAULT';

  @override
  String communityHubTierRank(int rank) {
    return '#$rank';
  }

  @override
  String get communityHubNoTiersHint =>
      'No tiers yet. Add tiers to give members a status ladder.';

  @override
  String get communityHubAddTier => 'Add tier';

  @override
  String get communityHubNoMembersHint =>
      'No members yet. Invite people or share your join link.';

  @override
  String get communityHubManageMembers => 'Manage members';

  @override
  String communityHubManageAllMembers(int count) {
    return 'Manage all $count members';
  }

  @override
  String get communityHubMemberFallback => 'Member';

  @override
  String get communityHubChipAdmin => 'ADMIN';

  @override
  String get communityHubLoadError => 'Couldn\'t load your community';

  @override
  String get createCommunityPremiumTitle => 'Community Premium';

  @override
  String get createCommunityPremiumBody =>
      'Your free plan includes one community. Running more than one is part of Community Premium — coming soon.';

  @override
  String get createCommunityTitle => 'New community';

  @override
  String get createCommunityNameLabel => 'Name';

  @override
  String get createCommunityNameHint =>
      'e.g. Kappa Delta — Beta Chi, or City Run Club';

  @override
  String get createCommunityNameRequired => 'Name is required';

  @override
  String get createCommunityTypeLabel => 'Type';

  @override
  String get createCommunityWhoCanJoin => 'Who can join';

  @override
  String get createCommunityJoinAnyone => 'Anyone';

  @override
  String get createCommunityJoinInviteOnly => 'Invite only';

  @override
  String get createCommunitySubmit => 'CREATE COMMUNITY';

  @override
  String get tierEditorEditTitle => 'Edit tier';

  @override
  String get tierEditorNewTitle => 'New tier';

  @override
  String get tierEditorDeleteTooltip => 'Delete tier';

  @override
  String get tierEditorDeleteTitle => 'Delete tier?';

  @override
  String tierEditorDeleteBody(String name) {
    return 'Remove \"$name\"? Members in it will need reassigning.';
  }

  @override
  String get tierEditorDelete => 'Delete';

  @override
  String get tierEditorNameLabel => 'Name';

  @override
  String get tierEditorNameHint => 'e.g. Exec, Active, Captain, Coach';

  @override
  String get tierEditorNameRequired => 'Name is required';

  @override
  String get tierEditorRankLabel => 'Rank (higher = more senior)';

  @override
  String get tierEditorRankRequired => 'Enter a number (1 or higher)';

  @override
  String get tierEditorColourLabel => 'Colour';

  @override
  String get tierEditorRuleLabel => 'How members get this tier';

  @override
  String tierEditorThresholdLabel(String unit) {
    return 'Threshold ($unit)';
  }

  @override
  String tierEditorThresholdRequired(String unit) {
    return 'Enter a $unit threshold';
  }

  @override
  String get tierEditorSave => 'SAVE';

  @override
  String get tierEditorCreate => 'CREATE TIER';

  @override
  String get rosterTitle => 'Members';

  @override
  String get rosterInviteTooltip => 'Invite member';

  @override
  String get rosterInviteTitle => 'Invite member';

  @override
  String get rosterInviteBody =>
      'Add a member by the email on their Kolabing account.';

  @override
  String get rosterInviteEmailLabel => 'Email';

  @override
  String get rosterInviteEmailHint => 'name@example.com';

  @override
  String get rosterInvite => 'Invite';

  @override
  String get rosterInviteInvalidEmail => 'Enter a valid email address';

  @override
  String get rosterMemberAdded => 'Member added';

  @override
  String get rosterNoAccountForEmail =>
      'No Kolabing account found for that email';

  @override
  String get rosterMemberFallback => 'Member';

  @override
  String get rosterViewProfile => 'View profile';

  @override
  String get rosterEmptyTitle => 'No members yet';

  @override
  String get rosterInviteMember => 'Invite a member';

  @override
  String get rosterRemoveTitle => 'Remove member?';

  @override
  String rosterRemoveBody(String name) {
    return 'Remove $name from the community?';
  }

  @override
  String get rosterRemoveBodyFallback => 'this member';

  @override
  String get rosterRemove => 'Remove';

  @override
  String get rosterTierLabel => 'Tier';

  @override
  String get rosterNoTier => 'No tier';

  @override
  String get rosterCanManageTitle => 'Can manage this community';

  @override
  String get rosterCanManageSubtitle =>
      'Admin capability — independent of tier';

  @override
  String get rosterStatusLabel => 'Status';

  @override
  String get rosterSave => 'SAVE';
}
