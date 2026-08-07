import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ca'),
  ];

  /// Application name. Brand — usually not translated.
  ///
  /// In en, this message translates to:
  /// **'Kolabing'**
  String get appName;

  /// Generic primary action to proceed to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Generic dismiss/cancel action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic save action.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Retry a failed operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Advance to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Go to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Confirm completion.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Fallback error message shown when an operation fails without a specific reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorGeneric;

  /// Error when account creation is blocked by missing onboarding fields; {fields} is a comma-separated list of field names
  ///
  /// In en, this message translates to:
  /// **'Please complete: {fields}'**
  String onboardingCompleteMissingFields(String fields);

  /// No description provided for @onboardingFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingFieldName;

  /// No description provided for @onboardingFieldBusinessCategory.
  ///
  /// In en, this message translates to:
  /// **'Business category'**
  String get onboardingFieldBusinessCategory;

  /// No description provided for @onboardingFieldVenueType.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get onboardingFieldVenueType;

  /// No description provided for @onboardingFieldVenueCapacity.
  ///
  /// In en, this message translates to:
  /// **'Venue capacity'**
  String get onboardingFieldVenueCapacity;

  /// No description provided for @onboardingFieldVenuePhotos.
  ///
  /// In en, this message translates to:
  /// **'Venue photos'**
  String get onboardingFieldVenuePhotos;

  /// No description provided for @onboardingFieldBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get onboardingFieldBusinessAddress;

  /// No description provided for @onboardingFieldTargetCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get onboardingFieldTargetCities;

  /// No description provided for @onboardingFieldCommunityType.
  ///
  /// In en, this message translates to:
  /// **'Community type'**
  String get onboardingFieldCommunityType;

  /// No description provided for @onboardingFieldCommunityCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get onboardingFieldCommunityCity;

  /// Welcome screen — secondary text button for existing users to sign in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// Welcome screen headline, first line. Pairs with welcomeHeadlineLine2.
  ///
  /// In en, this message translates to:
  /// **'Where local brands'**
  String get welcomeHeadlineLine1;

  /// Welcome screen headline, second line. Pairs with welcomeHeadlineLine1.
  ///
  /// In en, this message translates to:
  /// **'meet real communities.'**
  String get welcomeHeadlineLine2;

  /// Welcome screen subtitle under the headline.
  ///
  /// In en, this message translates to:
  /// **'Community-led partnerships for events, UGC, reviews and real-world growth.'**
  String get welcomeSubtitle;

  /// Welcome screen primary call-to-action button.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// Welcome screen primary CTA — redesigned version.
  ///
  /// In en, this message translates to:
  /// **'Start kolabing'**
  String get welcomeStartKolabing;

  /// Hero sentence part 1.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get welcomeHeroWhere;

  /// Hero sentence part 2.
  ///
  /// In en, this message translates to:
  /// **'businesses'**
  String get welcomeHeroBusinesses;

  /// Hero sentence part 3.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get welcomeHeroAnd;

  /// Hero sentence part 4.
  ///
  /// In en, this message translates to:
  /// **'communities'**
  String get welcomeHeroCommunities;

  /// Hero sentence part 5.
  ///
  /// In en, this message translates to:
  /// **'grow'**
  String get welcomeHeroGrow;

  /// Hero sentence part 6.
  ///
  /// In en, this message translates to:
  /// **'together'**
  String get welcomeHeroTogether;

  /// Tagline first word.
  ///
  /// In en, this message translates to:
  /// **'MATCH'**
  String get welcomeTaglineMatch;

  /// Tagline separator dot.
  ///
  /// In en, this message translates to:
  /// **'·'**
  String get welcomeTaglineDot;

  /// Tagline middle word — highlighted in yellow.
  ///
  /// In en, this message translates to:
  /// **'KOLAB'**
  String get welcomeTaglineKolab;

  /// Tagline last word.
  ///
  /// In en, this message translates to:
  /// **'GROW'**
  String get welcomeTaglineGrow;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get welcomeFloatingEvents;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'UGC'**
  String get welcomeFloatingUgc;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get welcomeFloatingReviews;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'growth'**
  String get welcomeFloatingGrowth;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'community'**
  String get welcomeFloatingCommunity;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'brands'**
  String get welcomeFloatingBrands;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get welcomeFloatingPeople;

  /// Atmospheric floating word on welcome screen.
  ///
  /// In en, this message translates to:
  /// **'connection'**
  String get welcomeFloatingConnection;

  /// Settings/profile row label that opens the language picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// App bar title of the language selection screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageScreenTitle;

  /// Option to follow the device language instead of a fixed app language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Endonym for the English language option.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Endonym for the Spanish language option (shown in its own language).
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Endonym for the Catalan language option (shown in its own language).
  ///
  /// In en, this message translates to:
  /// **'Català'**
  String get languageCatalan;

  /// Application review screen AppBar title.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION'**
  String get applicationReviewTitle;

  /// Error title when the application fails to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load application'**
  String get applicationReviewLoadError;

  /// Shown when the application does not exist.
  ///
  /// In en, this message translates to:
  /// **'Application not found'**
  String get applicationReviewNotFound;

  /// Section label for the applicant's message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get applicationReviewMessageLabel;

  /// Placeholder when the applicant left no message.
  ///
  /// In en, this message translates to:
  /// **'No message provided'**
  String get applicationReviewNoMessage;

  /// Section label for the applicant's availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get applicationReviewAvailabilityLabel;

  /// Placeholder when availability is not specified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get applicationReviewNotSpecified;

  /// Section label for the date the application was sent.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applicationReviewAppliedLabel;

  /// Fallback opportunity title in the header.
  ///
  /// In en, this message translates to:
  /// **'Unknown Opportunity'**
  String get applicationReviewUnknownOpportunity;

  /// Link to open the applicant's full profile.
  ///
  /// In en, this message translates to:
  /// **'View Full Profile'**
  String get applicationReviewViewFullProfile;

  /// Status label for an accepted application.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get applicationReviewStatusAccepted;

  /// Description shown for an accepted application.
  ///
  /// In en, this message translates to:
  /// **'This application has been accepted. You can chat with the applicant.'**
  String get applicationReviewStatusAcceptedDesc;

  /// Status label for a declined application.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get applicationReviewStatusDeclined;

  /// Decline status with the given reason.
  ///
  /// In en, this message translates to:
  /// **'Declined: {reason}'**
  String applicationReviewStatusDeclinedReason(String reason);

  /// Description shown for a declined application without a reason.
  ///
  /// In en, this message translates to:
  /// **'This application has been declined.'**
  String get applicationReviewStatusDeclinedDesc;

  /// Status label for a withdrawn application.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get applicationReviewStatusWithdrawn;

  /// Description shown for a withdrawn application.
  ///
  /// In en, this message translates to:
  /// **'The applicant has withdrawn their application.'**
  String get applicationReviewStatusWithdrawnDesc;

  /// Status label for a pending application.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get applicationReviewStatusPending;

  /// Button to open the chat for an accepted application.
  ///
  /// In en, this message translates to:
  /// **'OPEN CHAT'**
  String get applicationReviewOpenChat;

  /// Decline action button label.
  ///
  /// In en, this message translates to:
  /// **'DECLINE'**
  String get applicationReviewDecline;

  /// Accept action button label.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get applicationReviewAccept;

  /// Title of the decline confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Decline Application'**
  String get applicationReviewDeclineDialogTitle;

  /// Decline confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this application from {name}?'**
  String applicationReviewDeclineDialogBody(String name);

  /// Hint for the optional decline reason field.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get applicationReviewDeclineReasonHint;

  /// Confirm button in the decline dialog.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get applicationReviewDeclineDialogConfirm;

  /// Snackbar confirming the application was declined.
  ///
  /// In en, this message translates to:
  /// **'Application declined'**
  String get applicationReviewDeclinedSnack;

  /// Title of the accept-application bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Accept Application'**
  String get acceptFormTitle;

  /// Subtitle explaining the accept flow.
  ///
  /// In en, this message translates to:
  /// **'Pick a kolab date — you\'ll continue the conversation in chat after accepting.'**
  String get acceptFormSubtitle;

  /// Section label for the scheduled date picker.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED DATE'**
  String get acceptFormScheduledDate;

  /// Shown when there are no selectable future dates.
  ///
  /// In en, this message translates to:
  /// **'No available future dates in the opportunity range.'**
  String get acceptFormNoDates;

  /// Confirm button in the accept bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM ACCEPT'**
  String get acceptFormConfirm;

  /// Snackbar after accepting an application.
  ///
  /// In en, this message translates to:
  /// **'Application accepted! Kolab created.'**
  String get acceptFormAcceptedSnack;

  /// Error shown when accepting an application fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept application. Please try again.'**
  String get acceptFormError;

  /// Applications screen AppBar title.
  ///
  /// In en, this message translates to:
  /// **'APPLICATIONS'**
  String get applicationsTitle;

  /// Tab label for sent applications.
  ///
  /// In en, this message translates to:
  /// **'SENT'**
  String get applicationsTabSent;

  /// Tab label for received applications.
  ///
  /// In en, this message translates to:
  /// **'RECEIVED'**
  String get applicationsTabReceived;

  /// Empty state title for sent applications.
  ///
  /// In en, this message translates to:
  /// **'No Applications Yet'**
  String get applicationsSentEmptyTitle;

  /// Empty state body for sent applications.
  ///
  /// In en, this message translates to:
  /// **'Start exploring opportunities and apply to kolab with businesses and communities.'**
  String get applicationsSentEmptyBody;

  /// Empty state title for received applications.
  ///
  /// In en, this message translates to:
  /// **'No Received Applications'**
  String get applicationsReceivedEmptyTitle;

  /// Empty state body for received applications.
  ///
  /// In en, this message translates to:
  /// **'When someone applies to your opportunities, they\'ll appear here.'**
  String get applicationsReceivedEmptyBody;

  /// Generic error title in the applications list.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get applicationsErrorTitle;

  /// Sender label on a received application card.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String applicationCardFrom(String name);

  /// Recipient label on a sent application card.
  ///
  /// In en, this message translates to:
  /// **'To: {name}'**
  String applicationCardTo(String name);

  /// Application status badge: pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get applicationStatusPending;

  /// Application status badge: accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get applicationStatusAccepted;

  /// Application status badge: declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get applicationStatusDeclined;

  /// Application status badge: withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get applicationStatusWithdrawn;

  /// Chat error when the application cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Application not found'**
  String get chatApplicationNotFound;

  /// Banner shown to a lapsed business in chat.
  ///
  /// In en, this message translates to:
  /// **'Your subscription lapsed. Resubscribe to continue this chat.'**
  String get chatResubscribeBanner;

  /// Resubscribe action label in the chat banner.
  ///
  /// In en, this message translates to:
  /// **'RESUBSCRIBE'**
  String get chatResubscribeAction;

  /// Chat AppBar title while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatLoading;

  /// Date divider label for today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// Date divider label for yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// Chat message input hint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatMessageHint;

  /// Auth error title in chat.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get chatSessionExpiredTitle;

  /// Auth error body in chat.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get chatSessionExpiredBody;

  /// Sign in button in the chat auth error state.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get chatSignIn;

  /// Empty chat state title.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get chatEmptyTitle;

  /// Empty chat state body.
  ///
  /// In en, this message translates to:
  /// **'Send a message to begin discussing this kolab'**
  String get chatEmptyBody;

  /// Options menu item to view the opportunity.
  ///
  /// In en, this message translates to:
  /// **'View Opportunity'**
  String get chatViewOpportunity;

  /// Options menu item to cancel the application.
  ///
  /// In en, this message translates to:
  /// **'Cancel Application'**
  String get chatCancelApplication;

  /// Cancel application confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Application?'**
  String get chatCancelDialogTitle;

  /// Cancel application confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this application? This action cannot be undone.'**
  String get chatCancelDialogBody;

  /// Dismiss button in the cancel dialog.
  ///
  /// In en, this message translates to:
  /// **'No, Keep It'**
  String get chatCancelDialogKeep;

  /// Confirm withdraw button in the cancel dialog.
  ///
  /// In en, this message translates to:
  /// **'Yes, Withdraw'**
  String get chatCancelDialogWithdraw;

  /// Snackbar confirming the application was withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Application withdrawn'**
  String get chatApplicationWithdrawn;

  /// Header label of the apply modal.
  ///
  /// In en, this message translates to:
  /// **'NEW APPLICATION'**
  String get applyModalHeader;

  /// Section title for the application message field.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get applyModalMessageTitle;

  /// Helper text under the message field.
  ///
  /// In en, this message translates to:
  /// **'A short pitch helps you stand out — mention what you bring and why this fit makes sense.'**
  String get applyModalMessageHelp;

  /// Hint for the application message field.
  ///
  /// In en, this message translates to:
  /// **'Tell them why you\'re perfect for this kolab and what value you can bring...'**
  String get applyModalMessageHint;

  /// Section title for the date picker.
  ///
  /// In en, this message translates to:
  /// **'Select Date(s)'**
  String get applyModalSelectDatesTitle;

  /// Helper text under the date picker title.
  ///
  /// In en, this message translates to:
  /// **'Pick from the available dates for this kolab'**
  String get applyModalSelectDatesHelp;

  /// Validation error when no date is selected.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one date'**
  String get applyModalSelectDateError;

  /// Shown when the opportunity has no selectable dates.
  ///
  /// In en, this message translates to:
  /// **'No available dates for this kolab'**
  String get applyModalNoDates;

  /// Snackbar shown when the apply modal is opened for a closed/date-exhausted opportunity.
  ///
  /// In en, this message translates to:
  /// **'Applications for this Kolab are closed'**
  String get applyModalClosedSnack;

  /// Label shown on an offer whose application window has closed or is date-exhausted.
  ///
  /// In en, this message translates to:
  /// **'Applications closed'**
  String get exploreApplicationsClosed;

  /// Label for the optional availability notes field.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)'**
  String get applyModalNotesLabel;

  /// Hint for the availability notes field.
  ///
  /// In en, this message translates to:
  /// **'e.g., Flexible on timing, prefer mornings...'**
  String get applyModalNotesHint;

  /// Start time label in the time range picker.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get applyModalTimeFrom;

  /// End time label in the time range picker.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get applyModalTimeTo;

  /// Badge marking a section as optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get applyModalOptionalBadge;

  /// Fallback name when the host is unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown host'**
  String get applyModalUnknownHost;

  /// Fallback role label when the creator's type is unknown.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get applyModalHostFallback;

  /// Label above the opportunity in the hero card.
  ///
  /// In en, this message translates to:
  /// **'You are applying to'**
  String get applyModalApplyingTo;

  /// Title of the offer highlight card.
  ///
  /// In en, this message translates to:
  /// **'What\'s offered'**
  String get applyModalWhatsOffered;

  /// Tip card text in the apply modal.
  ///
  /// In en, this message translates to:
  /// **'Pick the dates that work for you and add a short message — applications with specifics get accepted faster.'**
  String get applyModalTip;

  /// Submit button label while sending.
  ///
  /// In en, this message translates to:
  /// **'SENDING…'**
  String get applyModalSending;

  /// Submit button label for the apply modal.
  ///
  /// In en, this message translates to:
  /// **'SEND APPLICATION'**
  String get applyModalSend;

  /// Error when the user already applied.
  ///
  /// In en, this message translates to:
  /// **'You have already applied to this opportunity'**
  String get applyModalAlreadyApplied;

  /// Generic error when submitting the application fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit application. Please try again.'**
  String get applyModalSubmitError;

  /// Generic action to dismiss a snackbar or notification.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// App bar title on the unknown-route fallback screen.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get routeNotFoundTitle;

  /// Body headline on the unknown-route fallback screen.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that page'**
  String get routeNotFoundBody;

  /// Recovery button on the unknown-route screen for a signed-in user.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get routeNotFoundGoToDashboard;

  /// Recovery button on the unknown-route screen for a signed-in user.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get routeNotFoundSignOut;

  /// Recovery button on the unknown-route screen for a signed-out user.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get routeNotFoundBackToLogin;

  /// Error shown when an opportunity fails to load for editing.
  ///
  /// In en, this message translates to:
  /// **'Could not load opportunity: {error}'**
  String opportunityLoadError(Object error);

  /// Title of the profile-avatar dropdown/menu entry.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileMenuTitle;

  /// Global offline banner shown when a request fails due to no connectivity.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Turn off airplane mode or reconnect, then try again.'**
  String get networkOfflineBannerMessage;

  /// Generic acknowledgement button to close an informational dialog.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Email field label/hint used across auth screens.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Email field placeholder showing an example address.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get authEmailHint;

  /// Password field label/hint used across auth screens.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Confirm-password field label used across auth screens.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// Validation error when the email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// Validation error when the email format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// Validation error when the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// Validation error when the password is shorter than 8 characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// Validation error when the confirm-password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// Validation error when the two password fields differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// Network error snackbar message shown on auth screens.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get authNoInternet;

  /// Generic unexpected-error snackbar message on auth screens.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get authUnexpectedError;

  /// Attendee registration screen title.
  ///
  /// In en, this message translates to:
  /// **'JOIN AS ATTENDEE'**
  String get attendeeRegisterTitle;

  /// Attendee registration screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to join events and complete challenges'**
  String get attendeeRegisterSubtitle;

  /// Attendee registration password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get attendeeRegisterPasswordHint;

  /// Attendee registration confirm-password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get attendeeRegisterConfirmPasswordHint;

  /// Attendee registration submit button.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get attendeeRegisterCreateAccount;

  /// Attendee registration legal/terms disclaimer under the create-account button.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms of Service and Privacy Policy'**
  String get attendeeRegisterTerms;

  /// Login screen auth panel title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginPanelTitle;

  /// Login screen auth panel subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off.'**
  String get loginPanelSubtitle;

  /// Login screen submit button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInButton;

  /// Login screen link to the forgot-password flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// Login screen hero headline.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get loginHeroWelcome;

  /// Login screen top-right link to create an account.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUpLink;

  /// Dialog title shown when Google sign-in finds no matching account.
  ///
  /// In en, this message translates to:
  /// **'Account Not Found'**
  String get loginUserNotFoundTitle;

  /// Dialog body shown when Google sign-in finds no matching account.
  ///
  /// In en, this message translates to:
  /// **'No account exists for this sign-in yet. Please create an account first.'**
  String get loginUserNotFoundMessage;

  /// Button in the user-not-found dialog to start account creation.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccountButton;

  /// Forgot-password form panel title.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordFormTitle;

  /// Forgot-password form panel subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll send a secure reset link.'**
  String get forgotPasswordFormSubtitle;

  /// Forgot-password helper text under the email field.
  ///
  /// In en, this message translates to:
  /// **'If the email matches an account, the reset link will arrive shortly.'**
  String get forgotPasswordHelperText;

  /// Forgot-password submit button.
  ///
  /// In en, this message translates to:
  /// **'SEND RESET LINK'**
  String get forgotPasswordSendButton;

  /// Forgot-password success panel title.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get forgotPasswordSuccessTitle;

  /// Forgot-password success panel subtitle.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, the reset link is on its way.'**
  String get forgotPasswordSuccessSubtitle;

  /// Forgot-password success panel button returning to login.
  ///
  /// In en, this message translates to:
  /// **'BACK TO SIGN IN'**
  String get forgotPasswordBackToSignIn;

  /// Forgot-password success panel link to retry with a different email.
  ///
  /// In en, this message translates to:
  /// **'Use another email'**
  String get forgotPasswordUseAnotherEmail;

  /// Forgot-password hero headline, line 1 (initial state).
  ///
  /// In en, this message translates to:
  /// **'RESET ACCESS.'**
  String get forgotPasswordHeroLine1;

  /// Forgot-password hero headline, line 2 (initial state).
  ///
  /// In en, this message translates to:
  /// **'GET BACK IN.'**
  String get forgotPasswordHeroLine2;

  /// Forgot-password hero headline, line 3 (initial state).
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD?'**
  String get forgotPasswordHeroLine3;

  /// Forgot-password hero headline, line 1 (after the email is sent).
  ///
  /// In en, this message translates to:
  /// **'CHECK YOUR EMAIL.'**
  String get forgotPasswordHeroSentLine1;

  /// Forgot-password hero headline, line 2 (after the email is sent).
  ///
  /// In en, this message translates to:
  /// **'OPEN THE LINK.'**
  String get forgotPasswordHeroSentLine2;

  /// Forgot-password hero headline, line 3 (after the email is sent).
  ///
  /// In en, this message translates to:
  /// **'YOU\'RE ALMOST IN.'**
  String get forgotPasswordHeroSentLine3;

  /// Reset-password screen headline.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get resetPasswordTitle;

  /// Reset-password screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below.'**
  String get resetPasswordSubtitle;

  /// Reset-password new-password field label.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewLabel;

  /// Reset-password new-password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get resetPasswordNewHint;

  /// Reset-password confirm-password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get resetPasswordConfirmHint;

  /// Reset-password submit button.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get resetPasswordButton;

  /// Error shown when the reset link is missing its token or email.
  ///
  /// In en, this message translates to:
  /// **'Invalid reset link. Please request a new one.'**
  String get resetPasswordInvalidLink;

  /// Reset-password success headline.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD RESET'**
  String get resetPasswordSuccessTitle;

  /// Reset-password success message with auto-redirect note.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset. Redirecting you to sign in...'**
  String get resetPasswordSuccessMessage;

  /// Reset-password success button to go to login manually.
  ///
  /// In en, this message translates to:
  /// **'GO TO SIGN IN'**
  String get resetPasswordGoToSignIn;

  /// Sign-in (Google) screen title.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get signInTitle;

  /// Sign-in (Google) screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInSubtitle;

  /// Google sign-in button label on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Apple social sign-in button label on auth screens.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Divider label above the social sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// Leading text of the sign-up footer link on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get signInNoAccount;

  /// Action text of the sign-up footer link on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signInSignUp;

  /// Dialog title shown when the Google account is of a different user type.
  ///
  /// In en, this message translates to:
  /// **'Account Type Mismatch'**
  String get signInTypeMismatchTitle;

  /// Dialog body explaining the user type mismatch. {type} is the existing account's user-type label.
  ///
  /// In en, this message translates to:
  /// **'This Google account is registered as a {type} user. Please sign in from the correct screen.'**
  String signInTypeMismatchMessage(String type);

  /// Fallback word used in the type-mismatch message when the existing user type label is unknown.
  ///
  /// In en, this message translates to:
  /// **'different'**
  String get signInTypeMismatchDifferent;

  /// Accessibility label announced on the splash screen while the app loads.
  ///
  /// In en, this message translates to:
  /// **'Kolabing - Loading application'**
  String get splashSemanticLabel;

  /// Accessibility label for the auth footer link. {leading} is the leading sentence and {action} is the tappable action text.
  ///
  /// In en, this message translates to:
  /// **'{leading} Tap {action} to navigate'**
  String authLinkSemanticLabel(String leading, String action);

  /// Accessibility label for the Kolabing logo image.
  ///
  /// In en, this message translates to:
  /// **'Kolabing logo'**
  String get kolabingLogoSemanticLabel;

  /// User-type selection card title for the Business option.
  ///
  /// In en, this message translates to:
  /// **'I\'m a business'**
  String get selectionCardBusinessTitle;

  /// User-type selection card title for the Community option.
  ///
  /// In en, this message translates to:
  /// **'I\'m a community'**
  String get selectionCardCommunityTitle;

  /// User-type selection card title for the Attendee option.
  ///
  /// In en, this message translates to:
  /// **'I\'m a member'**
  String get selectionCardAttendeeTitle;

  /// User-type selection card description for the Business option.
  ///
  /// In en, this message translates to:
  /// **'Looking for communities to partner with'**
  String get selectionCardBusinessDescription;

  /// User-type selection card description for the Community option. 'kolab' is brand terminology, keep untranslated.
  ///
  /// In en, this message translates to:
  /// **'Looking for brands to Kolab with'**
  String get selectionCardCommunityDescription;

  /// User-type selection card description for the Attendee option.
  ///
  /// In en, this message translates to:
  /// **'Joining events and completing challenges'**
  String get selectionCardAttendeeDescription;

  /// Badge shown on the Attendee user-type selection card while that account type is not yet available.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get selectionCardComingSoonBadge;

  /// Accessibility label for a user-type selection card, combining its title and description.
  ///
  /// In en, this message translates to:
  /// **'{title}. {description}'**
  String selectionCardSemanticLabel(String title, String description);

  /// Business bottom nav tab: Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get businessNavHome;

  /// Business bottom nav tab: Explore
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get businessNavExplore;

  /// Business bottom nav tab: My Kolabs
  ///
  /// In en, this message translates to:
  /// **'My Kolabs'**
  String get businessNavMyKolabs;

  /// Business bottom nav tab: Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get businessNavProfile;

  /// Tooltip on the create FAB for businesses
  ///
  /// In en, this message translates to:
  /// **'Create Kolab Request'**
  String get businessMainCreateKolabTooltip;

  /// Sign out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get businessProfileSignOutTitle;

  /// Sign out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get businessProfileSignOutMessage;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get businessProfileSignOut;

  /// Delete account dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get businessProfileDeleteAccountTitle;

  /// Delete account dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get businessProfileDeleteAccountMessage;

  /// Delete button label in account dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get businessProfileDelete;

  /// Delete account text link
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get businessProfileDeleteAccount;

  /// Change photo bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get businessProfileChangePhotoTitle;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get businessProfileTakePhoto;

  /// Take photo option subtitle
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get businessProfileTakePhotoSubtitle;

  /// Choose from gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get businessProfileChooseFromGallery;

  /// Choose from gallery option subtitle
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo'**
  String get businessProfileChooseFromGallerySubtitle;

  /// Snackbar shown while uploading profile photo
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get businessProfileUploadingPhoto;

  /// Snackbar shown after photo upload success
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get businessProfilePhotoUpdated;

  /// Snackbar shown when photo upload fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo'**
  String get businessProfilePhotoUpdateFailed;

  /// Snackbar action to dismiss an error
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get businessProfileDismiss;

  /// Error shown when profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get businessProfileLoadFailed;

  /// Generic error state heading
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get businessProfileSomethingWrong;

  /// Retry button on profile error state
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get businessProfileTryAgain;

  /// Fallback label for a business type
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessProfileBusinessFallback;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get businessProfileAbout;

  /// Subscription section title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get businessProfileSubscription;

  /// Label for active premium plan
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get businessProfilePremiumPlan;

  /// Label when there is no active plan
  ///
  /// In en, this message translates to:
  /// **'No Active Plan'**
  String get businessProfileNoActivePlan;

  /// Subscription renewal date label
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get businessProfileRenews;

  /// Days remaining label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get businessProfileRemaining;

  /// Days remaining value
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String businessProfileDaysRemaining(num count);

  /// Warning when subscription is set to cancel
  ///
  /// In en, this message translates to:
  /// **'Subscription ends at current billing period'**
  String get businessProfileSubscriptionEnding;

  /// Manage subscription button
  ///
  /// In en, this message translates to:
  /// **'MANAGE SUBSCRIPTION'**
  String get businessProfileManageSubscription;

  /// Upgrade to premium button
  ///
  /// In en, this message translates to:
  /// **'UPGRADE TO PREMIUM'**
  String get businessProfileUpgradePremium;

  /// Subscription status: active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get businessProfileStatusActive;

  /// Subscription status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get businessProfileStatusCancelled;

  /// Subscription status: past due
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get businessProfileStatusPastDue;

  /// Subscription status: inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get businessProfileStatusInactive;

  /// Contact info section title
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get businessProfileContactInfo;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get businessProfileNotifications;

  /// Notification toggle: messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get businessProfileNotifMessages;

  /// Notification toggle: application alerts
  ///
  /// In en, this message translates to:
  /// **'Application Alerts'**
  String get businessProfileNotifApplications;

  /// Notification toggle: kolab updates
  ///
  /// In en, this message translates to:
  /// **'Kolab Updates'**
  String get businessProfileNotifKolabUpdates;

  /// Notification toggle: rewards and wallet
  ///
  /// In en, this message translates to:
  /// **'Rewards & Wallet'**
  String get businessProfileNotifRewards;

  /// Notification toggle: marketing and tips
  ///
  /// In en, this message translates to:
  /// **'Marketing & Tips'**
  String get businessProfileNotifMarketing;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get businessProfileAccount;

  /// Fallback when creator name is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get communityOfferDetailUnknown;

  /// Shown under blurred community identity
  ///
  /// In en, this message translates to:
  /// **'Subscribe to reveal'**
  String get communityOfferDetailSubscribeToReveal;

  /// Number of applications received
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No applications} one{{count} application} other{{count} applications}}'**
  String communityOfferDetailApplicationsCount(num count);

  /// Categories section heading
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get communityOfferDetailCategories;

  /// Business offer section heading
  ///
  /// In en, this message translates to:
  /// **'BUSINESS OFFER'**
  String get communityOfferDetailBusinessOffer;

  /// Business offer item: venue
  ///
  /// In en, this message translates to:
  /// **'Venue provided'**
  String get communityOfferDetailVenueProvided;

  /// Business offer item: food and drink
  ///
  /// In en, this message translates to:
  /// **'Food & Drink included'**
  String get communityOfferDetailFoodDrink;

  /// Business offer item: percentage discount
  ///
  /// In en, this message translates to:
  /// **'{percent}% Discount'**
  String communityOfferDetailDiscountPct(num percent);

  /// Business offer item: discount without percentage
  ///
  /// In en, this message translates to:
  /// **'Discount offered'**
  String get communityOfferDetailDiscountOffered;

  /// Deliverables section heading
  ///
  /// In en, this message translates to:
  /// **'EXPECTED DELIVERABLES'**
  String get communityOfferDetailExpectedDeliverables;

  /// Deliverable: social media content
  ///
  /// In en, this message translates to:
  /// **'Social Media Content'**
  String get communityOfferDetailSocialMedia;

  /// Deliverable: event activation
  ///
  /// In en, this message translates to:
  /// **'Event Activation'**
  String get communityOfferDetailEventActivation;

  /// Deliverable: product placement
  ///
  /// In en, this message translates to:
  /// **'Product Placement'**
  String get communityOfferDetailProductPlacement;

  /// Deliverable: community reach
  ///
  /// In en, this message translates to:
  /// **'Community Reach'**
  String get communityOfferDetailCommunityReach;

  /// Deliverable: review and feedback
  ///
  /// In en, this message translates to:
  /// **'Review & Feedback'**
  String get communityOfferDetailReviewFeedback;

  /// Location and availability section heading
  ///
  /// In en, this message translates to:
  /// **'LOCATION & AVAILABILITY'**
  String get communityOfferDetailLocationTitle;

  /// Location row label: city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get communityOfferDetailCity;

  /// Fallback when a value is not specified
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get communityOfferDetailNotSpecified;

  /// Location row label: venue
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get communityOfferDetailVenue;

  /// Location row label: address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get communityOfferDetailAddress;

  /// Location row label: dates
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get communityOfferDetailDates;

  /// Location row label: availability mode
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get communityOfferDetailMode;

  /// Bottom action button when previewing
  ///
  /// In en, this message translates to:
  /// **'Preview mode'**
  String get communityOfferDetailPreviewMode;

  /// Bottom action button when already applied
  ///
  /// In en, this message translates to:
  /// **'Already applied'**
  String get communityOfferDetailAlreadyApplied;

  /// Bottom action button to apply
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get communityOfferDetailApplyNow;

  /// App bar title on error state
  ///
  /// In en, this message translates to:
  /// **'Opportunity Details'**
  String get communityOfferDetailTitle;

  /// Error heading when opportunity not found
  ///
  /// In en, this message translates to:
  /// **'Opportunity Not Found'**
  String get communityOfferDetailNotFound;

  /// Banner shown in preview mode
  ///
  /// In en, this message translates to:
  /// **'You are previewing this kolab as businesses see it'**
  String get communityOfferDetailPreviewBanner;

  /// Past events section heading
  ///
  /// In en, this message translates to:
  /// **'Past events from this community'**
  String get communityOfferDetailPastEvents;

  /// Past events section subtitle
  ///
  /// In en, this message translates to:
  /// **'See this community\'s recent track record before applying.'**
  String get communityOfferDetailPastEventsSubtitle;

  /// Base offer card heading
  ///
  /// In en, this message translates to:
  /// **'THE OFFER'**
  String get communityOfferDetailTheOffer;

  /// Negotiation triggers section heading
  ///
  /// In en, this message translates to:
  /// **'EXTRA TERMS UNLOCKED'**
  String get communityOfferDetailExtraTerms;

  /// Negotiation triggers section subtitle
  ///
  /// In en, this message translates to:
  /// **'These only show because you have already applied.'**
  String get communityOfferDetailExtraTermsSubtitle;

  /// Negotiation trigger condition label
  ///
  /// In en, this message translates to:
  /// **'IF {condition}'**
  String communityOfferDetailTriggerCondition(String condition);

  /// Filter label when showing recommended feed
  ///
  /// In en, this message translates to:
  /// **'Recommended matches for you'**
  String get exploreRecommendedMatches;

  /// Filter label when showing all feed
  ///
  /// In en, this message translates to:
  /// **'Browse all open kolabs'**
  String get exploreBrowseAll;

  /// Active filter chip: needs count
  ///
  /// In en, this message translates to:
  /// **'Offers {count}'**
  String exploreFilterNeeds(num count);

  /// Active filter chip: community types count
  ///
  /// In en, this message translates to:
  /// **'Types {count}'**
  String exploreFilterTypes(num count);

  /// Active filter chip: offer types count
  ///
  /// In en, this message translates to:
  /// **'Offers {count}'**
  String exploreFilterOffers(num count);

  /// Active filter chip: kolab intent count
  ///
  /// In en, this message translates to:
  /// **'Kolab {count}'**
  String exploreFilterKolab(num count);

  /// Result count label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} one{{count} result} other{{count} results}}'**
  String exploreResultCount(num count);

  /// Empty state heading with active filters
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get exploreEmptyNoResults;

  /// Empty state heading for recommended feed
  ///
  /// In en, this message translates to:
  /// **'No recommended matches yet'**
  String get exploreEmptyNoRecommended;

  /// Empty state heading for all feed
  ///
  /// In en, this message translates to:
  /// **'No opportunities yet'**
  String get exploreEmptyNoOpportunities;

  /// Empty state hint with active filters
  ///
  /// In en, this message translates to:
  /// **'Try broadening your filters or switching feeds.'**
  String get exploreEmptyNoResultsHint;

  /// Empty state hint for recommended feed
  ///
  /// In en, this message translates to:
  /// **'Switch to All or check back for fresh kolabs.'**
  String get exploreEmptyNoRecommendedHint;

  /// Empty state hint for all feed
  ///
  /// In en, this message translates to:
  /// **'Check back later for new opportunities.'**
  String get exploreEmptyNoOpportunitiesHint;

  /// Button to clear all filters
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get exploreClearFilters;

  /// Explore error state heading
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get exploreSomethingWrong;

  /// Explore error retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get exploreTryAgain;

  /// Feed toggle: recommended
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get exploreFeedRecommended;

  /// Feed toggle: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exploreFeedAll;

  /// Feed toggle: the viewer's saved (bookmarked) kolabs
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get exploreFeedSaved;

  /// Saved tab empty-state title
  ///
  /// In en, this message translates to:
  /// **'No saved kolabs yet'**
  String get savedKolabsEmptyTitle;

  /// Saved tab empty-state body
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on a kolab to save it for later.'**
  String get savedKolabsEmptyBody;

  /// Saved tab error-state title
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load saved kolabs'**
  String get savedKolabsErrorTitle;

  /// Saved tab error-state body
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get savedKolabsErrorBody;

  /// Snackbar when saving a kolab fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this kolab. Please try again.'**
  String get savedKolabsSaveError;

  /// Snackbar when unsaving a kolab fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove this kolab. Please try again.'**
  String get savedKolabsUnsaveError;

  /// Status tab: published
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get myKolabsTabPublished;

  /// Status tab: draft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get myKolabsTabDraft;

  /// Snackbar after publishing a kolab
  ///
  /// In en, this message translates to:
  /// **'Kolab published!'**
  String get myKolabsPublished;

  /// Snackbar when publish fails
  ///
  /// In en, this message translates to:
  /// **'Failed to publish'**
  String get myKolabsPublishFailed;

  /// Snackbar after closing a kolab
  ///
  /// In en, this message translates to:
  /// **'Kolab closed'**
  String get myKolabsClosed;

  /// Snackbar when close fails
  ///
  /// In en, this message translates to:
  /// **'Failed to close'**
  String get myKolabsCloseFailed;

  /// Delete kolab dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Kolab'**
  String get myKolabsDeleteTitle;

  /// Delete kolab dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this kolab? This action cannot be undone.'**
  String get myKolabsDeleteMessage;

  /// Delete button in kolab dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myKolabsDelete;

  /// Snackbar after deleting a kolab
  ///
  /// In en, this message translates to:
  /// **'Kolab deleted'**
  String get myKolabsDeleted;

  /// Snackbar when delete fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get myKolabsDeleteFailed;

  /// My Kolabs screen header
  ///
  /// In en, this message translates to:
  /// **'MY KOLABS'**
  String get myKolabsTitle;

  /// My Kolabs screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your kolabs'**
  String get myKolabsSubtitle;

  /// Count of kolabs in the list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 kolabs} one{{count} kolab} other{{count} kolabs}}'**
  String myKolabsCount(num count);

  /// Empty state heading
  ///
  /// In en, this message translates to:
  /// **'No kolabs yet'**
  String get myKolabsEmptyTitle;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'Create your first kolab to start connecting with communities'**
  String get myKolabsEmptyMessage;

  /// Empty-state CTA button that opens the create-Kolab flow.
  ///
  /// In en, this message translates to:
  /// **'Create a Kolab'**
  String get myKolabsCreateNewButton;

  /// Create kolab button
  ///
  /// In en, this message translates to:
  /// **'Create Kolab'**
  String get myKolabsCreate;

  /// Error state heading
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get myKolabsSomethingWrong;

  /// Error retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get myKolabsTryAgain;

  /// Review bottom-sheet title.
  ///
  /// In en, this message translates to:
  /// **'How was the Kolab? ⭐'**
  String get kolabReviewSheetTitle;

  /// Review sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your review helps {partnerName} build trust on Kolabing.'**
  String kolabReviewSheetSubtitle(String partnerName);

  /// Optional review comment field hint.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get kolabReviewSheetCommentHint;

  /// Would-collaborate-again question label.
  ///
  /// In en, this message translates to:
  /// **'Would you Kolab again?'**
  String get kolabReviewSheetWouldAgain;

  /// Affirmative choice chip.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get kolabReviewSheetYes;

  /// Negative choice chip.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get kolabReviewSheetNo;

  /// Submit review button label with XP reward.
  ///
  /// In en, this message translates to:
  /// **'Submit +10 XP ✨'**
  String get kolabReviewSheetSubmitXp;

  /// Skip the review action.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get kolabReviewSheetSkip;

  /// Completion sheet step 0 title.
  ///
  /// In en, this message translates to:
  /// **'Did the Kolab happen? 🎯'**
  String get kolabCompletionConfirmTitle;

  /// Completion confirm subtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark your Kolab with {partnerName} as complete.'**
  String kolabCompletionConfirmSubtitle(String partnerName);

  /// Loading label while completion request is in flight.
  ///
  /// In en, this message translates to:
  /// **'Completing…'**
  String get kolabCompletionConfirmLoading;

  /// Confirm completion primary button.
  ///
  /// In en, this message translates to:
  /// **'Yes, complete Kolab ✨'**
  String get kolabCompletionConfirmCta;

  /// Dismiss completion confirmation.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get kolabCompletionConfirmDismiss;

  /// Third completion confirmation option: the Kolab did not happen.
  ///
  /// In en, this message translates to:
  /// **'No, it didn\'t happen'**
  String get kolabCompletionConfirmNo;

  /// Acknowledgement title after answering 'not yet'.
  ///
  /// In en, this message translates to:
  /// **'Got it, thanks 👍'**
  String get kolabCompletionConfirmedNotYetTitle;

  /// Acknowledgement body after answering 'not yet'.
  ///
  /// In en, this message translates to:
  /// **'We\'ll check back later — come back here once the Kolab happens to confirm it.'**
  String get kolabCompletionConfirmedNotYetBody;

  /// Acknowledgement title after answering 'no, it didn't happen'.
  ///
  /// In en, this message translates to:
  /// **'Thanks for letting us know'**
  String get kolabCompletionConfirmedNoTitle;

  /// Acknowledgement body after answering 'no, it didn't happen'.
  ///
  /// In en, this message translates to:
  /// **'We\'ve recorded that this Kolab didn\'t happen. Reach out to support if you need help resolving it.'**
  String get kolabCompletionConfirmedNoBody;

  /// Error when the completion confirmation submission fails.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your confirmation. Please try again.'**
  String get kolabCompletionConfirmError;

  /// Completion sheet feedback step title.
  ///
  /// In en, this message translates to:
  /// **'How was the Kolab? ⭐'**
  String get kolabCompletionFeedbackTitle;

  /// Optional impact-data step title, shown after the Kolab is already confirmed complete.
  ///
  /// In en, this message translates to:
  /// **'Add a few details? ⭐'**
  String get kolabCompletionFeedbackOptionalTitle;

  /// Optional impact-data step subtitle.
  ///
  /// In en, this message translates to:
  /// **'Got it — your answer is recorded. Sharing a quick rating and a few details helps {partnerName} build trust on Kolabing — and earns you extra XP. Totally optional.'**
  String kolabCompletionFeedbackOptionalSubtitle(String partnerName);

  /// Skip the optional feedback step.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get kolabCompletionFeedbackSkip;

  /// Required feedback subtitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback is required to finish. Your review helps {partnerName} build trust on Kolabing.'**
  String kolabCompletionFeedbackSubtitle(String partnerName);

  /// Optional feedback comment field hint.
  ///
  /// In en, this message translates to:
  /// **'Anything to add? (optional)'**
  String get kolabCompletionFeedbackCommentHint;

  /// Would-collaborate-again question label.
  ///
  /// In en, this message translates to:
  /// **'Would you Kolab again?'**
  String get kolabCompletionFeedbackWouldAgain;

  /// Affirmative choice chip.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get kolabCompletionFeedbackYes;

  /// Negative choice chip.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get kolabCompletionFeedbackNo;

  /// Loading label while feedback is being submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get kolabCompletionFeedbackSubmitting;

  /// Submit feedback primary button.
  ///
  /// In en, this message translates to:
  /// **'Submit & finish'**
  String get kolabCompletionFeedbackSubmit;

  /// Hint shown when no rating selected yet.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get kolabCompletionFeedbackTapStar;

  /// Escape-hatch action shown after a feedback submission error.
  ///
  /// In en, this message translates to:
  /// **'Finish later'**
  String get kolabCompletionFeedbackFinishLater;

  /// Error when feedback submission fails.
  ///
  /// In en, this message translates to:
  /// **'Could not submit feedback. Please try again.'**
  String get kolabCompletionSheetFeedbackError;

  /// Title of the optional 5-star review step.
  ///
  /// In en, this message translates to:
  /// **'Rate this Kolab ⭐'**
  String get kolabStarReviewTitle;

  /// Subtitle of the optional 5-star review step.
  ///
  /// In en, this message translates to:
  /// **'Got it — your answer is recorded. A quick 5-star review helps {partnerName} build trust on Kolabing. Totally optional.'**
  String kolabStarReviewSubtitle(String partnerName);

  /// Business star review: communication row label
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get kolabStarReviewBizCommunicationLabel;

  /// Business star review: communication row helper
  ///
  /// In en, this message translates to:
  /// **'Was it easy to coordinate?'**
  String get kolabStarReviewBizCommunicationHelper;

  /// Business star review: reliability row label
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get kolabStarReviewBizReliabilityLabel;

  /// Business star review: reliability row helper
  ///
  /// In en, this message translates to:
  /// **'Did the community show up and deliver?'**
  String get kolabStarReviewBizReliabilityHelper;

  /// Business star review: fit row label
  ///
  /// In en, this message translates to:
  /// **'Community fit'**
  String get kolabStarReviewBizFitLabel;

  /// Business star review: fit row helper
  ///
  /// In en, this message translates to:
  /// **'Was their audience a good match?'**
  String get kolabStarReviewBizFitHelper;

  /// Business star review: value row label
  ///
  /// In en, this message translates to:
  /// **'Business value'**
  String get kolabStarReviewBizValueLabel;

  /// Business star review: value row helper
  ///
  /// In en, this message translates to:
  /// **'Did the Kolab bring value to your business?'**
  String get kolabStarReviewBizValueHelper;

  /// Business star review: repeat row label
  ///
  /// In en, this message translates to:
  /// **'Would work with them again'**
  String get kolabStarReviewBizRepeatLabel;

  /// Business star review: repeat row helper
  ///
  /// In en, this message translates to:
  /// **'Would you repeat a Kolab with them?'**
  String get kolabStarReviewBizRepeatHelper;

  /// Community star review: communication row label
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get kolabStarReviewComCommunicationLabel;

  /// Community star review: communication row helper
  ///
  /// In en, this message translates to:
  /// **'Was it easy to coordinate?'**
  String get kolabStarReviewComCommunicationHelper;

  /// Community star review: reliability row label
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get kolabStarReviewComReliabilityLabel;

  /// Community star review: reliability row helper
  ///
  /// In en, this message translates to:
  /// **'Did the business deliver what was agreed?'**
  String get kolabStarReviewComReliabilityHelper;

  /// Community star review: fit row label
  ///
  /// In en, this message translates to:
  /// **'Experience fit'**
  String get kolabStarReviewComFitLabel;

  /// Community star review: fit row helper
  ///
  /// In en, this message translates to:
  /// **'Was the experience right for your community?'**
  String get kolabStarReviewComFitHelper;

  /// Community star review: value row label
  ///
  /// In en, this message translates to:
  /// **'Member value'**
  String get kolabStarReviewComValueLabel;

  /// Community star review: value row helper
  ///
  /// In en, this message translates to:
  /// **'Did your members get something valuable?'**
  String get kolabStarReviewComValueHelper;

  /// Community star review: repeat row label
  ///
  /// In en, this message translates to:
  /// **'Would Kolab again'**
  String get kolabStarReviewComRepeatLabel;

  /// Community star review: repeat row helper
  ///
  /// In en, this message translates to:
  /// **'Would you repeat a Kolab with them?'**
  String get kolabStarReviewComRepeatHelper;

  /// Optional free-text comment field label.
  ///
  /// In en, this message translates to:
  /// **'Anything else you\'d like to add?'**
  String get kolabStarReviewCommentLabel;

  /// Submit the 5-star review.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get kolabStarReviewSubmit;

  /// Loading label while the review is being submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get kolabStarReviewSubmitting;

  /// Skip the optional star review step.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get kolabStarReviewSkip;

  /// Success copy shown after a star review is submitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your review helps improve future Kolabs.'**
  String get kolabStarReviewSuccess;

  /// Shown when the viewer has already submitted a star review.
  ///
  /// In en, this message translates to:
  /// **'You\'ve shared your feedback ✓'**
  String get kolabStarReviewAlreadyDone;

  /// Error when star review submission fails.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your review. Please try again.'**
  String get kolabStarReviewError;

  /// Celebration step title.
  ///
  /// In en, this message translates to:
  /// **'Kolab completed! 🎉'**
  String get kolabCompletionCelebrationTitle;

  /// Celebration step body.
  ///
  /// In en, this message translates to:
  /// **'You earned XP and your profile now reflects this completed Kolab.'**
  String get kolabCompletionCelebrationBody;

  /// XP preview badge.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP earned ⚡'**
  String kolabCompletionXpEarned(num xp);

  /// Advance from celebration to done.
  ///
  /// In en, this message translates to:
  /// **'See my XP →'**
  String get kolabCompletionCelebrationCta;

  /// Done step title.
  ///
  /// In en, this message translates to:
  /// **'All done! 🏆'**
  String get kolabCompletionDoneTitle;

  /// Done step body.
  ///
  /// In en, this message translates to:
  /// **'This Kolab is complete. Check your profile to see your growing history of collaborations.'**
  String get kolabCompletionDoneBody;

  /// Total XP earned display.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String kolabCompletionDoneXp(num xp);

  /// Label under the total XP figure.
  ///
  /// In en, this message translates to:
  /// **'XP earned'**
  String get kolabCompletionDoneXpLabel;

  /// Close the completion sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get kolabCompletionDoneClose;

  /// Pre-completion note explaining that confirmation comes first and review is optional after.
  ///
  /// In en, this message translates to:
  /// **'First, confirm whether the Kolab happened. Reviews are optional after that.'**
  String kolabCompletionConfirmMutualNote(String partnerName);

  /// Yes/No feedback question: expectation match.
  ///
  /// In en, this message translates to:
  /// **'Did it match your expectations?'**
  String get kolabCompletionFeedbackExpectationMatch;

  /// Yes/No feedback question: would recommend.
  ///
  /// In en, this message translates to:
  /// **'Would you recommend this partner?'**
  String get kolabCompletionFeedbackWouldRecommend;

  /// Yes/No feedback question: would the user collaborate (kolab) with this partner again.
  ///
  /// In en, this message translates to:
  /// **'Would you kolab again?'**
  String get kolabCompletionFeedbackWouldCollaborateAgain;

  /// Section header for optional metrics in the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Results (optional)'**
  String get kolabCompletionFeedbackMetricsOptional;

  /// Optional metric: number of posts or reels published.
  ///
  /// In en, this message translates to:
  /// **'Posts / reels published'**
  String get kolabCompletionFeedbackPostsReels;

  /// Optional business metric: number of stories posted.
  ///
  /// In en, this message translates to:
  /// **'Stories posted'**
  String get kolabCompletionFeedbackStoriesPosted;

  /// Optional business metric: revenue generated.
  ///
  /// In en, this message translates to:
  /// **'Revenue generated'**
  String get kolabCompletionFeedbackRevenue;

  /// Optional community metric: free-text benefits received.
  ///
  /// In en, this message translates to:
  /// **'Benefits received'**
  String get kolabCompletionFeedbackBenefits;

  /// Soft-success title when the caller is done but the partner has not confirmed yet.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your feedback is in ✅'**
  String get kolabCompletionAwaitingPartnerTitle;

  /// Soft-success body shown when waiting on the partner's feedback.
  ///
  /// In en, this message translates to:
  /// **'This Kolab completes once {partnerName} confirms too. We will let you know.'**
  String kolabCompletionAwaitingPartnerBody(String partnerName);

  /// Dismiss the awaiting-partner soft-success step.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get kolabCompletionAwaitingPartnerClose;

  /// Shown when the partner already completed the Kolab.
  ///
  /// In en, this message translates to:
  /// **'This Kolab is already completed.'**
  String get kolabCompletionAlreadyCompleted;

  /// Shown when the collaboration cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Kolab not found'**
  String get collaborationDetailNotFound;

  /// Date picker help text for rescheduling.
  ///
  /// In en, this message translates to:
  /// **'Reschedule kolab'**
  String get collaborationDetailRescheduleHelp;

  /// Time picker help text.
  ///
  /// In en, this message translates to:
  /// **'Start time (optional)'**
  String get collaborationDetailStartTimeHelp;

  /// Snackbar after successful reschedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated.'**
  String get collaborationDetailScheduleUpdated;

  /// Snackbar after failed reschedule.
  ///
  /// In en, this message translates to:
  /// **'Could not update schedule: {error}'**
  String collaborationDetailScheduleUpdateError(String error);

  /// Event info card section title.
  ///
  /// In en, this message translates to:
  /// **'EVENT DETAILS'**
  String get collaborationDetailEventDetails;

  /// Edit schedule action label.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get collaborationDetailEdit;

  /// Event date row label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get collaborationDetailDateLabel;

  /// Event time row label.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get collaborationDetailTimeLabel;

  /// Event venue row label.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get collaborationDetailVenueLabel;

  /// Venue value indicating the business hosts.
  ///
  /// In en, this message translates to:
  /// **'{businessName} (Business venue)'**
  String collaborationDetailVenueValue(String businessName);

  /// Community reach row label.
  ///
  /// In en, this message translates to:
  /// **'Community Reach'**
  String get collaborationDetailCommunityReachLabel;

  /// Community reach is included.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get collaborationDetailReachIncluded;

  /// Community reach not specified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get collaborationDetailReachNotSpecified;

  /// Partner card title when partner is a business.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS PARTNER'**
  String get collaborationDetailBusinessPartner;

  /// Partner card title when partner is a community.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY PARTNER'**
  String get collaborationDetailCommunityPartner;

  /// Offers section title for the business viewer.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU\'RE OFFERING'**
  String get collaborationDetailOffersTitleBusiness;

  /// Offers section title for the community viewer.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S OFFERED'**
  String get collaborationDetailOffersTitleCommunity;

  /// Business offer: venue.
  ///
  /// In en, this message translates to:
  /// **'Venue provided'**
  String get collaborationDetailOfferVenue;

  /// Business offer: food and drink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink included'**
  String get collaborationDetailOfferFoodDrink;

  /// Business offer: social media exposure.
  ///
  /// In en, this message translates to:
  /// **'Social media exposure'**
  String get collaborationDetailOfferSocialMedia;

  /// Business offer: content creation support.
  ///
  /// In en, this message translates to:
  /// **'Content creation support'**
  String get collaborationDetailOfferContentCreation;

  /// Business offer: discount percentage.
  ///
  /// In en, this message translates to:
  /// **'Discount: {percentage}%'**
  String collaborationDetailOfferDiscount(num percentage);

  /// Deliverables section title for the business viewer.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED DELIVERABLES'**
  String get collaborationDetailDeliverablesTitleBusiness;

  /// Deliverables section title for the community viewer.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU\'LL DELIVER'**
  String get collaborationDetailDeliverablesTitleCommunity;

  /// Deliverable: social media content.
  ///
  /// In en, this message translates to:
  /// **'Social Media Content'**
  String get collaborationDetailDeliverableSocialContent;

  /// Deliverable: event activation.
  ///
  /// In en, this message translates to:
  /// **'Event Activation'**
  String get collaborationDetailDeliverableEventActivation;

  /// Deliverable: product placement.
  ///
  /// In en, this message translates to:
  /// **'Product Placement'**
  String get collaborationDetailDeliverableProductPlacement;

  /// Deliverable: community reach.
  ///
  /// In en, this message translates to:
  /// **'Community Reach'**
  String get collaborationDetailDeliverableCommunityReach;

  /// Deliverable: review and feedback.
  ///
  /// In en, this message translates to:
  /// **'Review & Feedback'**
  String get collaborationDetailDeliverableReviewFeedback;

  /// Contact section title.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get collaborationDetailContactTitle;

  /// Email contact row label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get collaborationDetailContactEmail;

  /// Timeline section title.
  ///
  /// In en, this message translates to:
  /// **'PROCESS'**
  String get collaborationDetailProcessTitle;

  /// Challenges section title.
  ///
  /// In en, this message translates to:
  /// **'GAMIFICATION SETUP'**
  String get collaborationDetailGamificationTitle;

  /// Count of selected challenges.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String collaborationDetailSelectedCount(num count);

  /// Challenges section info text.
  ///
  /// In en, this message translates to:
  /// **'Select challenges for attendees to complete during the event. These will be available in the attendee app.'**
  String get collaborationDetailGamificationDescription;

  /// Empty challenges title.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet'**
  String get collaborationDetailNoChallengesTitle;

  /// Empty challenges body.
  ///
  /// In en, this message translates to:
  /// **'Add challenges to make the event more engaging for attendees'**
  String get collaborationDetailNoChallengesBody;

  /// Abbreviation for points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get collaborationDetailPoints;

  /// Snackbar for unimplemented custom challenge feature.
  ///
  /// In en, this message translates to:
  /// **'Custom challenge creation coming soon'**
  String get collaborationDetailCustomChallengeSoon;

  /// Button to add a custom challenge.
  ///
  /// In en, this message translates to:
  /// **'ADD CUSTOM CHALLENGE'**
  String get collaborationDetailAddCustomChallenge;

  /// QR section title.
  ///
  /// In en, this message translates to:
  /// **'QR CODE CHECK-IN'**
  String get collaborationDetailQrTitle;

  /// QR placeholder label.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get collaborationDetailQrPlaceholder;

  /// QR placeholder subtitle: the QR is generated when you tap the button.
  ///
  /// In en, this message translates to:
  /// **'Generated on demand'**
  String get collaborationDetailQrGeneratedOnDemand;

  /// QR section description.
  ///
  /// In en, this message translates to:
  /// **'Tap below to generate your check-in QR. Attendees scan it at your event to check in and start completing challenges.'**
  String get collaborationDetailQrDescription;

  /// QR button label while the QR is being generated.
  ///
  /// In en, this message translates to:
  /// **'GENERATING…'**
  String get collaborationDetailQrGenerating;

  /// Snackbar when generating the check-in QR fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the QR code: {error}'**
  String collaborationDetailQrGenerateError(String error);

  /// Button to view the QR code.
  ///
  /// In en, this message translates to:
  /// **'View QR code'**
  String get collaborationDetailViewQr;

  /// Subscription-lapse prompt title.
  ///
  /// In en, this message translates to:
  /// **'Resubscribe to continue'**
  String get collaborationDetailResubscribeTitle;

  /// Subscription-lapse prompt body.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has lapsed, so this ongoing kolab and its chat are paused on your side. The community keeps full access. Resubscribe to pick up where you left off.'**
  String get collaborationDetailResubscribeBody;

  /// Resubscribe button label.
  ///
  /// In en, this message translates to:
  /// **'RESUBSCRIBE'**
  String get collaborationDetailResubscribeCta;

  /// Error state title.
  ///
  /// In en, this message translates to:
  /// **'Failed to load kolab'**
  String get collaborationDetailLoadError;

  /// Today scheduled banner title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Kolab!'**
  String get collaborationDetailTodayBannerTitle;

  /// Today scheduled banner body.
  ///
  /// In en, this message translates to:
  /// **'Your Kolab with {partnerName} is today. Once it\'s active you\'ll be able to mark it complete.'**
  String collaborationDetailTodayBannerBody(String partnerName);

  /// Complete CTA title when the kolab is today.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s Kolab!'**
  String get collaborationDetailCompleteTitleToday;

  /// Complete CTA title.
  ///
  /// In en, this message translates to:
  /// **'Kolab completed?'**
  String get collaborationDetailCompleteTitle;

  /// Complete CTA body when the kolab is today.
  ///
  /// In en, this message translates to:
  /// **'Did your Kolab with {partnerName} happen? Mark it done.'**
  String collaborationDetailCompleteBodyToday(String partnerName);

  /// Complete CTA body.
  ///
  /// In en, this message translates to:
  /// **'Did the Kolab with {partnerName} happen? Mark it done.'**
  String collaborationDetailCompleteBody(String partnerName);

  /// Complete CTA button when the kolab is today.
  ///
  /// In en, this message translates to:
  /// **'Mark it done ✨'**
  String get collaborationDetailMarkDone;

  /// Complete CTA button.
  ///
  /// In en, this message translates to:
  /// **'Yes, it happened ✨'**
  String get collaborationDetailItHappened;

  /// Re-entry CTA button label when the viewer's own answer was 'no' or 'not yet'.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get collaborationDetailUpdateStatus;

  /// Re-entry CTA button label when the viewer said 'yes' and the partner hasn't answered or said 'not yet'.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get collaborationDetailCheckAgain;

  /// Re-entry CTA button label when the viewer said 'yes' and the partner said 'no'.
  ///
  /// In en, this message translates to:
  /// **'Review status'**
  String get collaborationDetailReviewStatus;

  /// Post-completion CTA letting a participant who skipped the optional feedback step come back to it later.
  ///
  /// In en, this message translates to:
  /// **'Leave optional feedback'**
  String get collaborationDetailLeaveFeedbackLater;

  /// Title of the post-completion review CTA card.
  ///
  /// In en, this message translates to:
  /// **'Rate this Kolab'**
  String get collaborationDetailFeedbackCtaTitle;

  /// Body copy of the post-completion review CTA card.
  ///
  /// In en, this message translates to:
  /// **'Your review helps {partnerName} build trust on Kolabing.'**
  String collaborationDetailFeedbackCtaBody(String partnerName);

  /// Button label on the post-completion review CTA card.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get collaborationDetailFeedbackCtaButton;

  /// Shown post-completion once the viewer has submitted optional feedback.
  ///
  /// In en, this message translates to:
  /// **'You\'ve shared your feedback ✓'**
  String get collaborationDetailFeedbackAlreadyLeft;

  /// Shown after the viewer submits feedback while the partner still has to.
  ///
  /// In en, this message translates to:
  /// **'You\'ve confirmed ✓'**
  String get collaborationDetailFeedbackConfirmedTitle;

  /// Body of the awaiting-partner confirmation state.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {partnerName} to confirm too. The Kolab completes once you both do.'**
  String collaborationDetailFeedbackConfirmedBody(String partnerName);

  /// Shown when the partner explicitly answered 'not yet' to the completion confirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting on {partnerName}'**
  String collaborationDetailPartnerSaidNotYetTitle(String partnerName);

  /// Body shown when the partner answered 'not yet'.
  ///
  /// In en, this message translates to:
  /// **'{partnerName} said the Kolab hasn\'t happened yet. The Kolab completes once you both confirm \'yes\'.'**
  String collaborationDetailPartnerSaidNotYetBody(String partnerName);

  /// Shown when the partner explicitly answered 'no' to the completion confirmation.
  ///
  /// In en, this message translates to:
  /// **'{partnerName} said it didn\'t happen'**
  String collaborationDetailPartnerSaidNoTitle(String partnerName);

  /// Body shown when the partner answered 'no'.
  ///
  /// In en, this message translates to:
  /// **'{partnerName} said this Kolab didn\'t happen. Contact support if you need help resolving it.'**
  String collaborationDetailPartnerSaidNoBody(String partnerName);

  /// Subtle line on the My Kolabs Active card after the viewer submits feedback.
  ///
  /// In en, this message translates to:
  /// **'You confirmed — waiting for partner'**
  String get collaborationCardWaitingForPartner;

  /// Confirmation that a review was submitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted ✓'**
  String get collaborationDetailReviewSubmitted;

  /// Post-completion review prompt title.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get collaborationDetailLeaveReview;

  /// XP reward badge for leaving a review.
  ///
  /// In en, this message translates to:
  /// **'+10 XP'**
  String get collaborationDetailXpBadge;

  /// Post-completion review prompt body.
  ///
  /// In en, this message translates to:
  /// **'Help {partnerName} build trust on Kolabing.'**
  String collaborationDetailReviewHelp(String partnerName);

  /// Button to open the review sheet.
  ///
  /// In en, this message translates to:
  /// **'Leave review +10 XP ✨'**
  String get collaborationDetailLeaveReviewCta;

  /// Community main screen: bottom nav label for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get communityMainNavHome;

  /// Community main screen: bottom nav label for the Explore tab
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get communityMainNavExplore;

  /// Community main screen: bottom nav label for the My Kolabs tab
  ///
  /// In en, this message translates to:
  /// **'My Kolabs'**
  String get communityMainNavMyKolabs;

  /// No description provided for @communityMainNavCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityMainNavCommunity;

  /// Community main screen: bottom nav label for the Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get communityMainNavProfile;

  /// Community main screen: tooltip on the create-opportunity floating action button
  ///
  /// In en, this message translates to:
  /// **'Create Opportunity'**
  String get communityMainCreateOpportunityTooltip;

  /// Community profile: sign-out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get communityProfileSignOutTitle;

  /// Community profile: sign-out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get communityProfileSignOutBody;

  /// Community profile: confirm button in the sign-out dialog
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get communityProfileSignOutConfirm;

  /// Community profile: sign-out button in the account section (uppercase)
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get communityProfileSignOutButton;

  /// Community profile: delete-account confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get communityProfileDeleteAccountTitle;

  /// Community profile: delete-account confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get communityProfileDeleteAccountBody;

  /// Community profile: confirm button in the delete-account dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get communityProfileDeleteAccountConfirm;

  /// Community profile: delete-account text link in the account section
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get communityProfileDeleteAccountLink;

  /// Community profile: title of the change-photo bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get communityProfileChangePhotoTitle;

  /// Community profile: option to take a new photo with the camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get communityProfileTakePhoto;

  /// Community profile: subtitle for the take-photo option
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get communityProfileTakePhotoSubtitle;

  /// Community profile: option to choose an existing photo from the gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get communityProfileChooseFromGallery;

  /// Community profile: subtitle for the choose-from-gallery option
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo'**
  String get communityProfileChooseFromGallerySubtitle;

  /// Community profile: snackbar shown while the profile photo is uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get communityProfileUploadingPhoto;

  /// Community profile: snackbar shown when the photo upload succeeds
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get communityProfilePhotoUpdated;

  /// Community profile: snackbar shown when the photo upload fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo: {error}'**
  String communityProfilePhotoUpdateFailed(String error);

  /// Community profile: action label to dismiss the error snackbar
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get communityProfileDismiss;

  /// Community profile: error message shown when the profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get communityProfileLoadFailed;

  /// Community profile: title of the error state
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get communityProfileErrorTitle;

  /// Community profile: retry button in the error state (uppercase)
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get communityProfileTryAgain;

  /// Community profile: fallback label shown when the community type is unknown
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityProfileCommunityFallback;

  /// Community profile: gamification level chip showing level number, title and total XP
  ///
  /// In en, this message translates to:
  /// **'LVL {level} · {title} · {xp} XP'**
  String communityProfileLevelChip(int level, String title, int xp);

  /// Community profile: section title for the about text
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get communityProfileAboutSection;

  /// Community profile: section title for contact information
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get communityProfileContactInfoSection;

  /// Community profile: section title for editable community details
  ///
  /// In en, this message translates to:
  /// **'Community Details'**
  String get communityProfileDetailsSection;

  /// Community profile: placeholder when community size is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get communityProfileSizeNotSet;

  /// Community profile: section title for notification preferences
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get communityProfileNotificationsSection;

  /// Community profile: notification toggle label for messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get communityProfileNotifMessages;

  /// Community profile: notification toggle label for application alerts
  ///
  /// In en, this message translates to:
  /// **'Application Alerts'**
  String get communityProfileNotifApplications;

  /// Community profile: notification toggle label for kolab updates
  ///
  /// In en, this message translates to:
  /// **'Kolab Updates'**
  String get communityProfileNotifKolabUpdates;

  /// Community profile: notification toggle label for rewards and wallet
  ///
  /// In en, this message translates to:
  /// **'Rewards & Wallet'**
  String get communityProfileNotifRewards;

  /// Community profile: notification toggle label for marketing and tips
  ///
  /// In en, this message translates to:
  /// **'Marketing & Tips'**
  String get communityProfileNotifMarketing;

  /// Community profile: section title for account settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get communityProfileAccountSection;

  /// Create opportunity screen: app bar title in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit Kolab'**
  String get createOpportunityEditTitle;

  /// Create opportunity screen: app bar title in create mode
  ///
  /// In en, this message translates to:
  /// **'Create a Kolab'**
  String get createOpportunityCreateTitle;

  /// Create opportunity step 0: header (uppercase)
  ///
  /// In en, this message translates to:
  /// **'BASIC INFORMATION'**
  String get createOpportunityStep0Title;

  /// Create opportunity step 0: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'Describe your kolab idea'**
  String get createOpportunityStep0Subtitle;

  /// Create opportunity step 0: label for the title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createOpportunityTitleLabel;

  /// Create opportunity step 0: hint for the title field
  ///
  /// In en, this message translates to:
  /// **'e.g., Restaurant Week Promotion'**
  String get createOpportunityTitleHint;

  /// Create opportunity step 0: label for the description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createOpportunityDescriptionLabel;

  /// Create opportunity step 0: hint for the description field
  ///
  /// In en, this message translates to:
  /// **'Describe your kolab opportunity in detail. What are you looking for?'**
  String get createOpportunityDescriptionHint;

  /// Create opportunity step 0: label for the categories selector
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get createOpportunityCategoriesLabel;

  /// Create opportunity step 0: hint under the categories label
  ///
  /// In en, this message translates to:
  /// **'Select up to 5 categories'**
  String get createOpportunityCategoriesHint;

  /// Create opportunity step 0: label for the kolab photo uploader
  ///
  /// In en, this message translates to:
  /// **'Kolab Photo'**
  String get createOpportunityPhotoLabel;

  /// Create opportunity step 0: hint under the photo label
  ///
  /// In en, this message translates to:
  /// **'Optional, but recommended for Explore.'**
  String get createOpportunityPhotoHint;

  /// Create opportunity step 1: header (uppercase)
  ///
  /// In en, this message translates to:
  /// **'WHAT DO YOU NEED FROM THE BUSINESS?'**
  String get createOpportunityStep1Title;

  /// Create opportunity step 1: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'Select what your community expects in this kolab'**
  String get createOpportunityStep1Subtitle;

  /// Create opportunity step 1: venue offer toggle title
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get createOpportunityOfferVenueTitle;

  /// Create opportunity step 1: venue offer toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'You need a venue for the event'**
  String get createOpportunityOfferVenueSubtitle;

  /// Create opportunity step 1: food and drink offer toggle title
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get createOpportunityOfferFoodTitle;

  /// Create opportunity step 1: food and drink offer toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'You\'d like food or beverages provided'**
  String get createOpportunityOfferFoodSubtitle;

  /// Create opportunity step 1: discount offer toggle title
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get createOpportunityOfferDiscountTitle;

  /// Create opportunity step 1: discount offer toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Special discount for your community'**
  String get createOpportunityOfferDiscountSubtitle;

  /// Create opportunity step 1: label for the discount percentage field
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage'**
  String get createOpportunityDiscountPercentageLabel;

  /// Create opportunity step 1: hint for the discount percentage field
  ///
  /// In en, this message translates to:
  /// **'e.g., 20'**
  String get createOpportunityDiscountPercentageHint;

  /// Create opportunity step 1: products offer toggle title
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get createOpportunityOfferProductsTitle;

  /// Create opportunity step 1: products offer toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'You\'d like products or samples'**
  String get createOpportunityOfferProductsSubtitle;

  /// Create opportunity step 1: hint for a product name input
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get createOpportunityProductNameHint;

  /// Create opportunity step 1: button to add another product row (uppercase)
  ///
  /// In en, this message translates to:
  /// **'ADD PRODUCT'**
  String get createOpportunityAddProduct;

  /// Create opportunity step 1: other offer toggle title
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createOpportunityOfferOtherTitle;

  /// Create opportunity step 1: other offer toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Other support from the business'**
  String get createOpportunityOfferOtherSubtitle;

  /// Create opportunity step 1: label for the other-offer details field
  ///
  /// In en, this message translates to:
  /// **'Other Offer Details'**
  String get createOpportunityOfferOtherDetailsLabel;

  /// Create opportunity step 1: hint for the other-offer details field
  ///
  /// In en, this message translates to:
  /// **'Describe what the business offers'**
  String get createOpportunityOfferOtherDetailsHint;

  /// Create opportunity step 2: header (uppercase)
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY DELIVERABLES'**
  String get createOpportunityStep2Title;

  /// Create opportunity step 2: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'What will the community provide in return?'**
  String get createOpportunityStep2Subtitle;

  /// Create opportunity step 2: social media deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Social Media Content'**
  String get createOpportunityDelivSocialTitle;

  /// Create opportunity step 2: social media deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Instagram Post, Instagram Story, Reel / Short Video, TikTok Video, Photo Content (UGC for brand use)'**
  String get createOpportunityDelivSocialSubtitle;

  /// Create opportunity step 2: event activation deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Event Activation'**
  String get createOpportunityDelivEventTitle;

  /// Create opportunity step 2: event activation deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Brand integration or mention during our event'**
  String get createOpportunityDelivEventSubtitle;

  /// Create opportunity step 2: product placement deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Product Placement'**
  String get createOpportunityDelivProductTitle;

  /// Create opportunity step 2: product placement deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Product showcase or visibility during our event'**
  String get createOpportunityDelivProductSubtitle;

  /// Create opportunity step 2: community reach deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Community Reach'**
  String get createOpportunityDelivReachTitle;

  /// Create opportunity step 2: community reach deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Minimum attendee guarantee, access to our members, feature, community discount code'**
  String get createOpportunityDelivReachSubtitle;

  /// Create opportunity step 2: review and feedback deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Review & Feedback'**
  String get createOpportunityDelivReviewTitle;

  /// Create opportunity step 2: review and feedback deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Google/social reviews, testimonials or member feedback'**
  String get createOpportunityDelivReviewSubtitle;

  /// Create opportunity step 2: other deliverable toggle title
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createOpportunityDelivOtherTitle;

  /// Create opportunity step 2: other deliverable toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Write your own deliverable'**
  String get createOpportunityDelivOtherSubtitle;

  /// Create opportunity step 2: label for the other-deliverable details field
  ///
  /// In en, this message translates to:
  /// **'Other Deliverable Details'**
  String get createOpportunityDelivOtherDetailsLabel;

  /// Create opportunity step 2: hint for the other-deliverable details field
  ///
  /// In en, this message translates to:
  /// **'Describe what the community will deliver'**
  String get createOpportunityDelivOtherDetailsHint;

  /// Create opportunity step 3: header (uppercase)
  ///
  /// In en, this message translates to:
  /// **'LOCATION & AVAILABILITY'**
  String get createOpportunityStep3Title;

  /// Create opportunity step 3: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'When is your community available for this kolab?'**
  String get createOpportunityStep3Subtitle;

  /// Create opportunity step 3: label for the availability mode selector
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get createOpportunityAvailabilityLabel;

  /// Create opportunity step 3: label for the venue mode selector
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get createOpportunityVenueLabel;

  /// Create opportunity step 3: label for the address field
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get createOpportunityAddressLabel;

  /// Create opportunity step 3: hint for the address field
  ///
  /// In en, this message translates to:
  /// **'Enter the venue address'**
  String get createOpportunityAddressHint;

  /// Create opportunity step 3: label for the preferred city dropdown
  ///
  /// In en, this message translates to:
  /// **'Preferred City'**
  String get createOpportunityPreferredCityLabel;

  /// Create opportunity step 3: error shown when the cities list fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading cities: {error}'**
  String createOpportunityCitiesLoadError(String error);

  /// Create opportunity step 3: hint for the city dropdown
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get createOpportunitySelectCityHint;

  /// Create opportunity step 3: date picker label for the start of availability
  ///
  /// In en, this message translates to:
  /// **'Available From'**
  String get createOpportunityAvailableFromLabel;

  /// Create opportunity step 3: date picker label for the end of availability
  ///
  /// In en, this message translates to:
  /// **'Available Until'**
  String get createOpportunityAvailableUntilLabel;

  /// Create opportunity step 3: label for the time picker
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get createOpportunityTimeLabel;

  /// Create opportunity step 3: label for the recurring day-of-week selector
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get createOpportunityDayOfWeekLabel;

  /// Create opportunity step 3: placeholder shown in the time picker before a time is chosen
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get createOpportunitySelectTime;

  /// Create opportunity step 4: header (uppercase)
  ///
  /// In en, this message translates to:
  /// **'REVIEW YOUR OPPORTUNITY'**
  String get createOpportunityStep4Title;

  /// Create opportunity step 4: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'Make sure everything looks correct before publishing'**
  String get createOpportunityStep4Subtitle;

  /// Create opportunity step 4: fallback title shown when no title is set
  ///
  /// In en, this message translates to:
  /// **'Untitled Opportunity'**
  String get createOpportunityReviewUntitled;

  /// Create opportunity step 4: fallback shown when no description is set
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get createOpportunityReviewNoDescription;

  /// Create opportunity step 4: review section title for the business offer
  ///
  /// In en, this message translates to:
  /// **'Business Offer'**
  String get createOpportunityReviewBusinessOffer;

  /// Create opportunity step 4: review section title for the community deliverables
  ///
  /// In en, this message translates to:
  /// **'Community Deliverables'**
  String get createOpportunityReviewDeliverables;

  /// Create opportunity step 4: fallback shown when no city is selected
  ///
  /// In en, this message translates to:
  /// **'No city selected'**
  String get createOpportunityReviewNoCity;

  /// Create opportunity step 4: hint inviting the user to tap a section to edit it
  ///
  /// In en, this message translates to:
  /// **'Tap any section above to edit'**
  String get createOpportunityReviewEditHint;

  /// Create opportunity screen: back navigation button (uppercase)
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get createOpportunityBackButton;

  /// Create opportunity screen: continue navigation button (uppercase)
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get createOpportunityContinueButton;

  /// Create opportunity screen: publish button (uppercase)
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get createOpportunityPublishButton;

  /// Create opportunity screen: save-as-draft button (uppercase)
  ///
  /// In en, this message translates to:
  /// **'SAVE DRAFT'**
  String get createOpportunitySaveDraftButton;

  /// My opportunities screen: status tab label for published opportunities
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get myOpportunitiesTabPublished;

  /// My opportunities screen: status tab label for draft opportunities
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get myOpportunitiesTabDraft;

  /// My opportunities screen: error snackbar when publishing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to publish opportunity'**
  String get myOpportunitiesPublishError;

  /// My opportunities screen: success snackbar when an opportunity is published
  ///
  /// In en, this message translates to:
  /// **'Opportunity published!'**
  String get myOpportunitiesPublishSuccess;

  /// My opportunities screen: snackbar when the share sheet is unavailable and the link is copied
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable. Link copied instead.'**
  String get myOpportunitiesShareUnavailable;

  /// My opportunities screen: snackbar when the share sheet cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open the share sheet.'**
  String get myOpportunitiesShareFailed;

  /// My opportunities screen: error snackbar when closing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to close opportunity'**
  String get myOpportunitiesCloseError;

  /// My opportunities screen: success snackbar when an opportunity is closed
  ///
  /// In en, this message translates to:
  /// **'Opportunity closed'**
  String get myOpportunitiesCloseSuccess;

  /// My opportunities screen: delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Opportunity'**
  String get myOpportunitiesDeleteTitle;

  /// My opportunities screen: delete confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this opportunity? This action cannot be undone.'**
  String get myOpportunitiesDeleteBody;

  /// My opportunities screen: confirm button in the delete dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myOpportunitiesDeleteConfirm;

  /// My opportunities screen: error snackbar when deleting fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete opportunity'**
  String get myOpportunitiesDeleteError;

  /// My opportunities screen: success snackbar when an opportunity is deleted
  ///
  /// In en, this message translates to:
  /// **'Opportunity deleted'**
  String get myOpportunitiesDeleteSuccess;

  /// My opportunities screen: tooltip on the create floating action button
  ///
  /// In en, this message translates to:
  /// **'Create New Opportunity'**
  String get myOpportunitiesCreateNewTooltip;

  /// My opportunities screen: page header title (uppercase)
  ///
  /// In en, this message translates to:
  /// **'MY OPPORTUNITIES'**
  String get myOpportunitiesHeaderTitle;

  /// My opportunities screen: page header subtitle
  ///
  /// In en, this message translates to:
  /// **'Create and manage your opportunities'**
  String get myOpportunitiesHeaderSubtitle;

  /// My opportunities screen: count of opportunities in the current list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 opportunity} other{{count} opportunities}}'**
  String myOpportunitiesCount(num count);

  /// My opportunities screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No opportunities yet'**
  String get myOpportunitiesEmptyTitle;

  /// My opportunities screen: empty state body
  ///
  /// In en, this message translates to:
  /// **'Create your first opportunity and start connecting.'**
  String get myOpportunitiesEmptyBody;

  /// My opportunities screen: create button in the empty state
  ///
  /// In en, this message translates to:
  /// **'Create Opportunity'**
  String get myOpportunitiesEmptyCreateButton;

  /// My opportunities screen: error state title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get myOpportunitiesErrorTitle;

  /// My opportunity card: number of applications received
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String myOpportunityCardApplicationsCount(num count);

  /// My opportunity card: fallback title shown when no title is set
  ///
  /// In en, this message translates to:
  /// **'Untitled Opportunity'**
  String get myOpportunityCardUntitled;

  /// My opportunity card: view action button label
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get myOpportunityCardActionView;

  /// My opportunity card: edit action button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get myOpportunityCardActionEdit;

  /// My opportunity card: publish action button label
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get myOpportunityCardActionPublish;

  /// My opportunity card: share action button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get myOpportunityCardActionShare;

  /// My opportunity card: close action button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get myOpportunityCardActionClose;

  /// My opportunity card: delete action button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myOpportunityCardActionDelete;

  /// Opportunity publish success dialog: title when saved as draft
  ///
  /// In en, this message translates to:
  /// **'Draft Saved!'**
  String get opportunityPublishSuccessDraftTitle;

  /// Opportunity publish success dialog: title when published
  ///
  /// In en, this message translates to:
  /// **'Opportunity Published!'**
  String get opportunityPublishSuccessPublishedTitle;

  /// Opportunity publish success dialog: body when saved as draft
  ///
  /// In en, this message translates to:
  /// **'Your opportunity has been saved as a draft. You can edit and publish it later.'**
  String get opportunityPublishSuccessDraftBody;

  /// Opportunity publish success dialog: body when published
  ///
  /// In en, this message translates to:
  /// **'Your opportunity is now live. Businesses can start applying!'**
  String get opportunityPublishSuccessPublishedBody;

  /// Opportunity publish success dialog: share button (uppercase)
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get opportunityPublishSuccessShare;

  /// Opportunity publish success dialog: button to view my opportunities (uppercase)
  ///
  /// In en, this message translates to:
  /// **'View my opportunities'**
  String get opportunityPublishSuccessViewOpportunities;

  /// Event detail screen: title of the delete-event confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get eventDetailDeleteTitle;

  /// Event detail screen: body of the delete-event confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String eventDetailDeleteConfirm(String name);

  /// Event detail screen: destructive confirm button in the delete dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventDetailDeleteAction;

  /// Event detail screen: snackbar shown after an event is deleted
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventDetailDeletedSnack;

  /// Event detail screen: title shown when the event cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventDetailNotFound;

  /// Event detail screen: section heading above the photo gallery
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get eventDetailPhotosTitle;

  /// Event detail screen: section heading above the video list
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get eventDetailVideosTitle;

  /// Event detail screen: outlined button to delete the event
  ///
  /// In en, this message translates to:
  /// **'DELETE EVENT'**
  String get eventDetailDeleteButton;

  /// Event detail screen: info row label for the partner of the Kolab (Kolab is the brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'Kolab with'**
  String get eventDetailKolabWithLabel;

  /// Event detail screen: info row label for the event date
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDetailDateLabel;

  /// Event detail screen: info row label for the attendee count
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get eventDetailAttendeesLabel;

  /// Event detail screen: number of attendees shown as a value
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String eventDetailAttendeesCount(num count);

  /// Event detail screen: title of a recap video item (1-based index)
  ///
  /// In en, this message translates to:
  /// **'Recap video {number}'**
  String eventDetailRecapVideoTitle(num number);

  /// Event detail screen: subtitle under a recap video item
  ///
  /// In en, this message translates to:
  /// **'Tap to open the uploaded video'**
  String get eventDetailRecapVideoSubtitle;

  /// Event detail screen: snackbar shown when a video URL fails to open
  ///
  /// In en, this message translates to:
  /// **'Could not open the video link'**
  String get eventDetailVideoOpenError;

  /// Add event modal: header title
  ///
  /// In en, this message translates to:
  /// **'Add Past Event'**
  String get addEventTitle;

  /// Add event modal: snackbar when the photo limit is reached
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos allowed'**
  String get addEventMaxPhotos;

  /// Add event modal: snackbar when the video limit is reached
  ///
  /// In en, this message translates to:
  /// **'Maximum 1 video allowed'**
  String get addEventMaxVideos;

  /// Add event modal: validation snackbar requiring a photo before submit
  ///
  /// In en, this message translates to:
  /// **'Please add at least one photo'**
  String get addEventAtLeastOnePhoto;

  /// Add event modal: snackbar on successful creation
  ///
  /// In en, this message translates to:
  /// **'Event added successfully'**
  String get addEventSuccess;

  /// Add event modal: snackbar when creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add event'**
  String get addEventFailure;

  /// Add event modal: label for the event name field
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get addEventNameLabel;

  /// Add event modal: hint for the event name field
  ///
  /// In en, this message translates to:
  /// **'e.g., Summer Music Festival'**
  String get addEventNameHint;

  /// Add event modal: validation error for empty event name
  ///
  /// In en, this message translates to:
  /// **'Please enter event name'**
  String get addEventNameError;

  /// Add event modal: label for the partner field (Kolab is the brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'Kolab With'**
  String get addEventPartnerLabel;

  /// Add event modal: hint for the partner field
  ///
  /// In en, this message translates to:
  /// **'e.g., Rock Community Istanbul'**
  String get addEventPartnerHint;

  /// Add event modal: validation error for empty partner name
  ///
  /// In en, this message translates to:
  /// **'Please enter partner name'**
  String get addEventPartnerError;

  /// Add event modal: label for the date picker
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get addEventDateLabel;

  /// Add event modal: label for the attendee count field
  ///
  /// In en, this message translates to:
  /// **'Attendee Count'**
  String get addEventAttendeeCountLabel;

  /// Add event modal: hint for the attendee count field
  ///
  /// In en, this message translates to:
  /// **'e.g., 250'**
  String get addEventAttendeeCountHint;

  /// Add event modal: validation error for empty attendee count
  ///
  /// In en, this message translates to:
  /// **'Please enter attendee count'**
  String get addEventAttendeeCountError;

  /// Add event modal: validation error for an invalid attendee count
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get addEventAttendeeCountInvalid;

  /// Add event modal: label for the photos picker
  ///
  /// In en, this message translates to:
  /// **'Event Photos'**
  String get addEventPhotosLabel;

  /// Add event modal: counter of selected photos out of the max of 5
  ///
  /// In en, this message translates to:
  /// **'({count}/5)'**
  String addEventPhotosCounter(num count);

  /// Add event modal: label inside the add-photo tile
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addEventAddPhotoButton;

  /// Add event modal: label for the optional recap video picker
  ///
  /// In en, this message translates to:
  /// **'Recap Video (Optional)'**
  String get addEventVideoLabel;

  /// Add event modal: helper text under the recap video label
  ///
  /// In en, this message translates to:
  /// **'Add one short video to show how the event felt.'**
  String get addEventVideoDescription;

  /// Add event modal: button to add a recap video
  ///
  /// In en, this message translates to:
  /// **'ADD VIDEO'**
  String get addEventAddVideoButton;

  /// Add event modal: submit button
  ///
  /// In en, this message translates to:
  /// **'ADD EVENT'**
  String get addEventSubmitButton;

  /// Past events section: section heading
  ///
  /// In en, this message translates to:
  /// **'Past Events'**
  String get pastEventsTitle;

  /// Past events section: compact button to add an event
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get pastEventsAddButton;

  /// Past events section: error state message
  ///
  /// In en, this message translates to:
  /// **'Failed to load events'**
  String get pastEventsLoadError;

  /// Past events section: empty state title
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get pastEventsEmptyTitle;

  /// Past events section: empty state subtitle (kolabs is the brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'Share your past kolabs with the community'**
  String get pastEventsEmptySubtitle;

  /// Past events section: empty state add button label
  ///
  /// In en, this message translates to:
  /// **'+ Add a past event'**
  String get pastEventsEmptyAddButton;

  /// Fallback label/role name for an attendee when no display name is available
  ///
  /// In en, this message translates to:
  /// **'Attendee'**
  String get attendeeRoleLabel;

  /// Attendee bottom nav: Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get attendeeNavHome;

  /// No description provided for @attendeeNavCommunities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get attendeeNavCommunities;

  /// Attendee bottom nav: QR Scan tab
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get attendeeNavScan;

  /// Attendee bottom nav: Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get attendeeNavProfile;

  /// Attendee: title of the sheet showing the user's own profile QR code
  ///
  /// In en, this message translates to:
  /// **'My profile QR'**
  String get attendeeMyQrTitle;

  /// Attendee: helper text under the user's own profile QR code
  ///
  /// In en, this message translates to:
  /// **'Show this to a host to check in or connect.'**
  String get attendeeMyQrSubtitle;

  /// Attendee app bar: tooltip for the my-profile-QR action
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get attendeeMyQrTooltip;

  /// Attendee: shown when the user's profile id/handle is missing so no QR can be rendered
  ///
  /// In en, this message translates to:
  /// **'Your profile QR isn\'t ready yet.'**
  String get attendeeMyQrUnavailable;

  /// Attendee home greeting above the user name
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get attendeeHomeWelcomeBack;

  /// Attendee home section header for nearby events list
  ///
  /// In en, this message translates to:
  /// **'NEARBY EVENTS'**
  String get attendeeHomeNearbyEvents;

  /// Search radius value in kilometers
  ///
  /// In en, this message translates to:
  /// **'{radius} km'**
  String attendeeHomeRadiusKm(String radius);

  /// Loading message while resolving the device location
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get attendeeHomeGettingLocation;

  /// Loading message while fetching nearby events
  ///
  /// In en, this message translates to:
  /// **'Searching for events...'**
  String get attendeeHomeSearchingEvents;

  /// Info bar describing the active search radius
  ///
  /// In en, this message translates to:
  /// **'Showing events within {radius} km'**
  String attendeeHomeShowingWithinRadius(String radius);

  /// Count of events found within the radius
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String attendeeHomeEventsFound(num count);

  /// Button to load more events in the feed
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get attendeeHomeLoadMore;

  /// Attendee home stat card label: points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get attendeeHomeStatPoints;

  /// Attendee home stat card label: challenges
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get attendeeHomeStatChallenges;

  /// Attendee home stat card label: events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get attendeeHomeStatEvents;

  /// Heading shown when location access is needed
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get attendeeHomeLocationRequired;

  /// Button to retry loading location or events
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get attendeeHomeTryAgain;

  /// Button to open the device app settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get attendeeHomeOpenSettings;

  /// Empty state heading when no events are found nearby
  ///
  /// In en, this message translates to:
  /// **'No Events Nearby'**
  String get attendeeHomeNoEventsNearby;

  /// Empty state hint when no events are found nearby
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search radius\nor check back later for new events.'**
  String get attendeeHomeNoEventsNearbyHint;

  /// Button to open the radius filter sheet
  ///
  /// In en, this message translates to:
  /// **'Adjust Radius'**
  String get attendeeHomeAdjustRadius;

  /// Error state heading when events fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load events'**
  String get attendeeHomeFailedToLoadEvents;

  /// Title of the radius filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get attendeeHomeSearchRadius;

  /// Button to apply the selected search radius
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get attendeeHomeApply;

  /// Error message when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get attendeeHomeLocationDenied;

  /// Error message when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Please enable them in settings.'**
  String get attendeeHomeLocationDeniedForever;

  /// Error message when device location services are off
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get attendeeHomeLocationServicesDisabled;

  /// Error message when fetching the location throws
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String attendeeHomeLocationError(String error);

  /// Attendee profile section header for stats
  ///
  /// In en, this message translates to:
  /// **'YOUR STATS'**
  String get attendeeProfileYourStats;

  /// Attendee profile stat card label: total points
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get attendeeProfileTotalPoints;

  /// Attendee profile stat card label: challenges
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get attendeeProfileChallenges;

  /// Attendee profile stat card label: events attended
  ///
  /// In en, this message translates to:
  /// **'Events Attended'**
  String get attendeeProfileEventsAttended;

  /// Attendee profile settings item: edit profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get attendeeProfileEditProfile;

  /// Attendee profile settings item: notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get attendeeProfileNotifications;

  /// Attendee profile settings item: help and support
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get attendeeProfileHelpSupport;

  /// Attendee profile sign out button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get attendeeProfileSignOut;

  /// Confirmation message in the sign out dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get attendeeProfileSignOutConfirm;

  /// Attendee profile stat label: friends count
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get attendeeProfileStatFriends;

  /// Attendee profile stat label: events attended count
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get attendeeProfileStatEvents;

  /// Attendee profile stat label: chat threads count
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get attendeeProfileStatChats;

  /// Attendee profile stat label: total points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get attendeeProfileStatPoints;

  /// Attendee profile section header for the communities the user belongs to
  ///
  /// In en, this message translates to:
  /// **'MY COMMUNITIES'**
  String get attendeeProfileMyCommunities;

  /// Attendee profile empty state for the communities section
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any communities yet.'**
  String get attendeeProfileNoCommunities;

  /// No description provided for @attendeeProfileFindFriends.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get attendeeProfileFindFriends;

  /// Attendee profile section header for the friends preview
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get attendeeProfileFriends;

  /// Link to open the full friends list from the attendee profile
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get attendeeProfileSeeAll;

  /// Title of the edit-profile screen
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// Button to pick a new profile photo
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfileChangePhoto;

  /// Field label for the user's display name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editProfileNameLabel;

  /// Placeholder for the name field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get editProfileNameHint;

  /// Validation error when the name field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get editProfileNameRequired;

  /// Field label for the user's city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editProfileCityLabel;

  /// Placeholder for the city picker
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get editProfileCityHint;

  /// Placeholder for the city search field
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get editProfileCitySearchHint;

  /// Empty state when the city search returns nothing
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get editProfileNoCitiesFound;

  /// Error message when the cities list fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load cities'**
  String get editProfileCityLoadError;

  /// Save button on the edit-profile screen
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// Success message after saving the profile
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileSaved;

  /// Generic error message when saving the profile fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Please try again.'**
  String get editProfileSaveError;

  /// Member public profile stat label: friends count
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get memberProfileFriends;

  /// Badges screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesScreenTitle;

  /// Badges screen section header for earned badges
  ///
  /// In en, this message translates to:
  /// **'EARNED BADGES'**
  String get badgesScreenEarnedBadges;

  /// Badges screen section header for all badges
  ///
  /// In en, this message translates to:
  /// **'ALL BADGES'**
  String get badgesScreenAllBadges;

  /// Badges screen stats header label under the earned count
  ///
  /// In en, this message translates to:
  /// **'Badges Earned'**
  String get badgesScreenBadgesEarned;

  /// Badges screen error state heading
  ///
  /// In en, this message translates to:
  /// **'Failed to load badges'**
  String get badgesScreenFailedToLoad;

  /// Generic retry button used across gamification error states
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get gamificationTryAgain;

  /// Leaderboard screen app bar title for the global leaderboard
  ///
  /// In en, this message translates to:
  /// **'Global Leaderboard'**
  String get leaderboardScreenGlobalTitle;

  /// Leaderboard screen app bar title (event fallback)
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardScreenTitle;

  /// Leaderboard screen section header for the rest of the rankings list
  ///
  /// In en, this message translates to:
  /// **'RANKINGS'**
  String get leaderboardScreenRankings;

  /// Label on the current user's rank card
  ///
  /// In en, this message translates to:
  /// **'Your Ranking'**
  String get leaderboardScreenYourRanking;

  /// Unit label next to a points value on the rank card
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get leaderboardScreenPoints;

  /// Leaderboard empty state heading
  ///
  /// In en, this message translates to:
  /// **'No Rankings Yet'**
  String get leaderboardScreenNoRankings;

  /// Leaderboard empty state hint
  ///
  /// In en, this message translates to:
  /// **'Be the first to earn points\nand claim the top spot!'**
  String get leaderboardScreenNoRankingsHint;

  /// Leaderboard screen error state heading
  ///
  /// In en, this message translates to:
  /// **'Failed to load leaderboard'**
  String get leaderboardScreenFailedToLoad;

  /// Stats screen app bar title
  ///
  /// In en, this message translates to:
  /// **'My Stats'**
  String get statsScreenTitle;

  /// Stats screen label under the total points value
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get statsScreenTotalPoints;

  /// Stats screen stat card label: events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get statsScreenEvents;

  /// Stats screen stat card label: challenges
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get statsScreenChallenges;

  /// Stats screen stat card label: badges
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get statsScreenBadges;

  /// Stats screen section header for detailed stats
  ///
  /// In en, this message translates to:
  /// **'DETAILED STATS'**
  String get statsScreenDetailedStats;

  /// Stats screen detailed stat row: rewards won
  ///
  /// In en, this message translates to:
  /// **'Rewards Won'**
  String get statsScreenRewardsWon;

  /// Stats screen detailed stat row: rewards redeemed
  ///
  /// In en, this message translates to:
  /// **'Rewards Redeemed'**
  String get statsScreenRewardsRedeemed;

  /// Stats screen detailed stat row: events discovered
  ///
  /// In en, this message translates to:
  /// **'Events Discovered'**
  String get statsScreenEventsDiscovered;

  /// Stats screen detailed stat row: spins used
  ///
  /// In en, this message translates to:
  /// **'Spins Used'**
  String get statsScreenSpinsUsed;

  /// Stats screen section header for quick actions
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get statsScreenQuickActions;

  /// Stats screen quick action button: rewards
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get statsScreenRewards;

  /// Snackbar message when tapping share on the stats screen
  ///
  /// In en, this message translates to:
  /// **'Game card sharing coming soon!'**
  String get statsScreenShareComingSoon;

  /// Stats screen error state heading
  ///
  /// In en, this message translates to:
  /// **'Failed to load stats'**
  String get statsScreenFailedToLoad;

  /// Generic retry button after an error
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// Create challenge screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get createChallengeTitle;

  /// Snackbar shown after a challenge is created
  ///
  /// In en, this message translates to:
  /// **'Challenge created successfully!'**
  String get createChallengeSuccess;

  /// Label for the challenge name field
  ///
  /// In en, this message translates to:
  /// **'Challenge Name'**
  String get createChallengeNameLabel;

  /// Hint for the challenge name field
  ///
  /// In en, this message translates to:
  /// **'Enter challenge name'**
  String get createChallengeNameHint;

  /// Validation error when challenge name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a challenge name'**
  String get createChallengeNameRequired;

  /// Validation error when challenge name is too short
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get createChallengeNameTooShort;

  /// Label for the challenge description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createChallengeDescriptionLabel;

  /// Hint for the challenge description field
  ///
  /// In en, this message translates to:
  /// **'Describe what attendees need to do'**
  String get createChallengeDescriptionHint;

  /// Label for the difficulty selector
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get createChallengeDifficultyLabel;

  /// Label for the points field
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get createChallengePointsLabel;

  /// Hint for the points field
  ///
  /// In en, this message translates to:
  /// **'Points awarded'**
  String get createChallengePointsHint;

  /// Validation error for invalid points number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get createChallengePointsInvalid;

  /// Validation error when points exceed the maximum
  ///
  /// In en, this message translates to:
  /// **'Maximum 100 points'**
  String get createChallengePointsMax;

  /// Button that resets points to the difficulty default
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get createChallengeResetDefault;

  /// Helper text describing default points per difficulty
  ///
  /// In en, this message translates to:
  /// **'Default: Easy=5, Medium=15, Hard=30 points'**
  String get createChallengePointsDefaultHint;

  /// Submit button on the create challenge screen
  ///
  /// In en, this message translates to:
  /// **'CREATE CHALLENGE'**
  String get createChallengeSubmit;

  /// Points value shown under a difficulty option
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String createChallengePointsValue(int points);

  /// Default app bar title for the event challenges screen
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get eventChallengesTitle;

  /// Tab label for all challenges
  ///
  /// In en, this message translates to:
  /// **'All Challenges'**
  String get eventChallengesTabAll;

  /// Tab label for custom challenges
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get eventChallengesTabCustom;

  /// Empty state for the all challenges tab
  ///
  /// In en, this message translates to:
  /// **'No challenges available for this event'**
  String get eventChallengesEmptyAll;

  /// Empty custom challenges state shown to organizers
  ///
  /// In en, this message translates to:
  /// **'Create custom challenges for your event'**
  String get eventChallengesEmptyCustomOrganizer;

  /// Empty custom challenges state for attendees
  ///
  /// In en, this message translates to:
  /// **'No custom challenges yet'**
  String get eventChallengesEmptyCustom;

  /// Floating action button label to create a challenge
  ///
  /// In en, this message translates to:
  /// **'New Challenge'**
  String get eventChallengesNewChallenge;

  /// Points awarded badge in the challenge details sheet
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String eventChallengesPointsAwarded(int points);

  /// Badge marking a system-defined challenge
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get eventChallengesSystemBadge;

  /// Button to start a challenge from the details sheet
  ///
  /// In en, this message translates to:
  /// **'START CHALLENGE'**
  String get eventChallengesStartChallenge;

  /// Event discovery screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Discover Events'**
  String get eventDiscoveryTitle;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get eventDiscoveryPermissionDenied;

  /// Error when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Please enable them in settings.'**
  String get eventDiscoveryPermissionDeniedForever;

  /// Error when device location services are off
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get eventDiscoveryServicesDisabled;

  /// Error when getting location fails
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String eventDiscoveryLocationFailed(String error);

  /// Loading message while getting location
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get eventDiscoveryGettingLocation;

  /// Loading message while searching for events
  ///
  /// In en, this message translates to:
  /// **'Searching for events...'**
  String get eventDiscoverySearching;

  /// Banner showing the active search radius
  ///
  /// In en, this message translates to:
  /// **'Showing events within {radius} km'**
  String eventDiscoveryRadiusInfo(String radius);

  /// Count of events found
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String eventDiscoveryFoundCount(int count);

  /// Button to load more events
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get eventDiscoveryLoadMore;

  /// Title of the location error state
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get eventDiscoveryLocationRequired;

  /// Button to open app settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get eventDiscoveryOpenSettings;

  /// Title of the empty discovery state
  ///
  /// In en, this message translates to:
  /// **'No Events Nearby'**
  String get eventDiscoveryEmptyTitle;

  /// Body of the empty discovery state
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search radius\nor check back later for new events.'**
  String get eventDiscoveryEmptyBody;

  /// Button to open the radius filter
  ///
  /// In en, this message translates to:
  /// **'Adjust Radius'**
  String get eventDiscoveryAdjustRadius;

  /// Title of the discovery error state
  ///
  /// In en, this message translates to:
  /// **'Failed to discover events'**
  String get eventDiscoveryErrorTitle;

  /// Title of the radius filter sheet
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get eventDiscoverySearchRadius;

  /// Radius value with kilometre unit
  ///
  /// In en, this message translates to:
  /// **'{radius} km'**
  String eventDiscoveryRadiusKm(String radius);

  /// Apply button in the radius filter sheet
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get eventDiscoveryApply;

  /// App bar title of the event QR code screen
  ///
  /// In en, this message translates to:
  /// **'Event Check-in'**
  String get eventQrTitle;

  /// Instructions under the QR code
  ///
  /// In en, this message translates to:
  /// **'Attendees can scan this QR code to check in to your event'**
  String get eventQrInstructions;

  /// Button to view event check-ins
  ///
  /// In en, this message translates to:
  /// **'View Check-ins'**
  String get eventQrViewCheckins;

  /// Loading message while the QR code is generated
  ///
  /// In en, this message translates to:
  /// **'Generating QR Code...'**
  String get eventQrGenerating;

  /// Title of the QR generation error state
  ///
  /// In en, this message translates to:
  /// **'Failed to generate QR code'**
  String get eventQrErrorTitle;

  /// Button to copy the check-in token
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get eventQrCopyToken;

  /// Snackbar confirming the token was copied
  ///
  /// In en, this message translates to:
  /// **'Token copied to clipboard'**
  String get eventQrTokenCopied;

  /// App bar title of the initiate challenge screen
  ///
  /// In en, this message translates to:
  /// **'Start Challenge'**
  String get initiateChallengeTitle;

  /// Error when initiating a challenge fails
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate challenge'**
  String get initiateChallengeFailed;

  /// Title of the success dialog
  ///
  /// In en, this message translates to:
  /// **'Challenge Started!'**
  String get initiateChallengeSuccessTitle;

  /// Body of the success dialog
  ///
  /// In en, this message translates to:
  /// **'The verifier will be notified to confirm your challenge completion.'**
  String get initiateChallengeSuccessBody;

  /// Points awarded badge in the challenge info card
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String initiateChallengePointsAwarded(int points);

  /// Section heading for the instructions
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get initiateChallengeHowItWorks;

  /// Instruction step 1
  ///
  /// In en, this message translates to:
  /// **'Enter the verifier\'s profile ID'**
  String get initiateChallengeStep1;

  /// Instruction step 2
  ///
  /// In en, this message translates to:
  /// **'Complete the challenge with the verifier present'**
  String get initiateChallengeStep2;

  /// Instruction step 3
  ///
  /// In en, this message translates to:
  /// **'The verifier confirms your completion'**
  String get initiateChallengeStep3;

  /// Instruction step 4
  ///
  /// In en, this message translates to:
  /// **'Earn your points!'**
  String get initiateChallengeStep4;

  /// Label for the verifier profile ID field
  ///
  /// In en, this message translates to:
  /// **'Verifier Profile ID'**
  String get initiateChallengeVerifierLabel;

  /// Hint for the verifier profile ID field
  ///
  /// In en, this message translates to:
  /// **'Enter the verifier\'s profile ID'**
  String get initiateChallengeVerifierHint;

  /// Validation error when the verifier ID is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter the verifier\'s profile ID'**
  String get initiateChallengeVerifierRequired;

  /// Helper text under the verifier field
  ///
  /// In en, this message translates to:
  /// **'Ask another attendee for their profile ID to verify your challenge'**
  String get initiateChallengeVerifierHelper;

  /// Submit button on the initiate challenge screen
  ///
  /// In en, this message translates to:
  /// **'START CHALLENGE'**
  String get initiateChallengeSubmit;

  /// Fallback event name when none is returned
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get qrScannerEventFallback;

  /// Error when check-in fails
  ///
  /// In en, this message translates to:
  /// **'Failed to check in'**
  String get qrScannerCheckinFailed;

  /// Title of the check-in success dialog
  ///
  /// In en, this message translates to:
  /// **'Check-in Successful!'**
  String get qrScannerSuccessTitle;

  /// Subtitle above the event name in the success dialog
  ///
  /// In en, this message translates to:
  /// **'You have checked in to'**
  String get qrScannerSuccessSubtitle;

  /// Title of the check-in error dialog
  ///
  /// In en, this message translates to:
  /// **'Check-in Failed'**
  String get qrScannerErrorTitle;

  /// Close button in the check-in error dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get qrScannerClose;

  /// Title of the QR scanner sheet
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScannerTitle;

  /// Loading message while checking in
  ///
  /// In en, this message translates to:
  /// **'Checking in...'**
  String get qrScannerCheckingIn;

  /// Primary instruction in the QR scanner
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the event QR code'**
  String get qrScannerInstructionTitle;

  /// Secondary instruction in the QR scanner
  ///
  /// In en, this message translates to:
  /// **'The QR code will be displayed by the event organizer'**
  String get qrScannerInstructionSubtitle;

  /// App bar title of the reward wallet screen
  ///
  /// In en, this message translates to:
  /// **'My Rewards'**
  String get rewardWalletTitle;

  /// Title of the empty rewards state
  ///
  /// In en, this message translates to:
  /// **'No Rewards Yet'**
  String get rewardWalletEmptyTitle;

  /// Body of the empty rewards state
  ///
  /// In en, this message translates to:
  /// **'Complete challenges and spin the wheel\nto win exciting rewards!'**
  String get rewardWalletEmptyBody;

  /// Title of the rewards error state
  ///
  /// In en, this message translates to:
  /// **'Failed to load rewards'**
  String get rewardWalletErrorTitle;

  /// Fallback challenge name in the completion card
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeCompletionDefaultName;

  /// Fallback challenger name in the completion card
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get challengeCompletionDefaultChallenger;

  /// Reject action button on a pending completion
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get challengeCompletionReject;

  /// Verify action button on a pending completion
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get challengeCompletionVerify;

  /// Status badge for a verified completion
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get challengeCompletionStatusVerified;

  /// Status badge for a rejected completion
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get challengeCompletionStatusRejected;

  /// Status badge for a pending completion
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get challengeCompletionStatusPending;

  /// Media step header when promoting a venue
  ///
  /// In en, this message translates to:
  /// **'SHOW OFF YOUR VENUE'**
  String get mediaTitleVenue;

  /// Media step header when promoting a product
  ///
  /// In en, this message translates to:
  /// **'SHOW YOUR PRODUCT'**
  String get mediaTitleProduct;

  /// Media step subtitle explaining photo limits
  ///
  /// In en, this message translates to:
  /// **'Add photos so communities can see what you\'re offering. (Min 1, Max 5)'**
  String get mediaSubtitle;

  /// Button to reuse photos from the existing library
  ///
  /// In en, this message translates to:
  /// **'SELECT FROM LIBRARY'**
  String get mediaSelectFromLibrary;

  /// Title of the existing-photo picker sheet
  ///
  /// In en, this message translates to:
  /// **'Select existing photos'**
  String get mediaSelectExistingTitle;

  /// Confirm button when selecting a single existing photo
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get mediaUsePhoto;

  /// Confirm button when selecting multiple existing photos
  ///
  /// In en, this message translates to:
  /// **'Use photos'**
  String get mediaUsePhotos;

  /// Snackbar when selected photos are duplicates
  ///
  /// In en, this message translates to:
  /// **'Those photos are already in this Kolab.'**
  String get mediaPhotosAlreadyAdded;

  /// Snackbar confirming how many existing photos were added
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added {count} existing photo.} other{Added {count} existing photos.}}'**
  String mediaPhotosAdded(num count);

  /// Snackbar shown when a photo upload fails
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String mediaUploadFailed(String error);

  /// Label on the add-photo grid tile
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get mediaAddPhoto;

  /// Placeholder label shown when a photo fails to load
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String mediaPhotoSlot(int number);

  /// Offering step section header
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU\'RE OFFERING'**
  String get offeringTitle;

  /// Offering step instruction under the header
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get offeringSelectAllThatApply;

  /// Community needs picker section header
  ///
  /// In en, this message translates to:
  /// **'WHAT DO YOU NEED?'**
  String get needsScreenTitle;

  /// Offering option: venue, title
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get offeringVenueTitle;

  /// Offering option: venue, subtitle
  ///
  /// In en, this message translates to:
  /// **'Provide your space for the kolab'**
  String get offeringVenueSubtitle;

  /// Offering option: food and drink, title
  ///
  /// In en, this message translates to:
  /// **'Food & Drink included'**
  String get offeringFoodDrinkTitle;

  /// Offering option: food and drink, subtitle
  ///
  /// In en, this message translates to:
  /// **'Meals or beverages for community members'**
  String get offeringFoodDrinkSubtitle;

  /// Offering option: discount, title
  ///
  /// In en, this message translates to:
  /// **'Discount for community members'**
  String get offeringDiscountTitle;

  /// Offering option: discount, subtitle
  ///
  /// In en, this message translates to:
  /// **'Exclusive pricing for participants'**
  String get offeringDiscountSubtitle;

  /// Offering option: products, title
  ///
  /// In en, this message translates to:
  /// **'Products / Samples'**
  String get offeringProductsTitle;

  /// Offering option: products, subtitle
  ///
  /// In en, this message translates to:
  /// **'Free product samples or giveaways'**
  String get offeringProductsSubtitle;

  /// Offering option: social media, title
  ///
  /// In en, this message translates to:
  /// **'Social Media Exposure'**
  String get offeringSocialMediaTitle;

  /// Offering option: social media, subtitle
  ///
  /// In en, this message translates to:
  /// **'Feature on your channels'**
  String get offeringSocialMediaSubtitle;

  /// Offering option: content creation, title
  ///
  /// In en, this message translates to:
  /// **'Content Creation'**
  String get offeringContentCreationTitle;

  /// Offering option: content creation, subtitle
  ///
  /// In en, this message translates to:
  /// **'Professional photos/video'**
  String get offeringContentCreationSubtitle;

  /// Offering option: sponsorship, title
  ///
  /// In en, this message translates to:
  /// **'Collaboration budget'**
  String get offeringSponsorshipTitle;

  /// Offering option: sponsorship, subtitle
  ///
  /// In en, this message translates to:
  /// **'Financial support for the kolab'**
  String get offeringSponsorshipSubtitle;

  /// Offering option: other, title
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get offeringOtherTitle;

  /// Offering option: other, subtitle
  ///
  /// In en, this message translates to:
  /// **'Something else to offer'**
  String get offeringOtherSubtitle;

  /// Section label for the base offer field
  ///
  /// In en, this message translates to:
  /// **'BASE OFFER'**
  String get offeringBaseOfferLabel;

  /// Helper text under the base offer label
  ///
  /// In en, this message translates to:
  /// **'What every community will see on your card. Be specific so leaders can evaluate at a glance.'**
  String get offeringBaseOfferHelper;

  /// Hint text for the base offer field
  ///
  /// In en, this message translates to:
  /// **'e.g. 20% off Tuesdays, free meeting room for groups of 10+'**
  String get offeringBaseOfferHint;

  /// Section label for extra negotiation terms
  ///
  /// In en, this message translates to:
  /// **'EXTRA TERMS (OPTIONAL)'**
  String get offeringExtraTermsLabel;

  /// Helper text for the extra terms section
  ///
  /// In en, this message translates to:
  /// **'Better terms you only unlock once a community proposes a kolab. They see these after sending you a Kolab.'**
  String get offeringExtraTermsHelper;

  /// Button to add an extra negotiation term
  ///
  /// In en, this message translates to:
  /// **'ADD EXTRA TERM'**
  String get offeringAddExtraTerm;

  /// Prefix shown before a negotiation trigger condition
  ///
  /// In en, this message translates to:
  /// **'IF {condition}'**
  String offeringTriggerIfPrefix(String condition);

  /// Title of the extra-term editor sheet
  ///
  /// In en, this message translates to:
  /// **'Add an extra term'**
  String get offeringTriggerSheetTitle;

  /// Subtitle of the extra-term editor sheet
  ///
  /// In en, this message translates to:
  /// **'Surfaces only after a community sends a Kolab proposal.'**
  String get offeringTriggerSheetSubtitle;

  /// Label for the trigger condition field
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get offeringTriggerWhenLabel;

  /// Hint for the trigger condition field
  ///
  /// In en, this message translates to:
  /// **'e.g. recurring monthly events'**
  String get offeringTriggerWhenHint;

  /// Label for the trigger offer field
  ///
  /// In en, this message translates to:
  /// **'Then offer'**
  String get offeringTriggerThenLabel;

  /// Hint for the trigger offer field
  ///
  /// In en, this message translates to:
  /// **'e.g. free venue rental from the 3rd event onward'**
  String get offeringTriggerThenHint;

  /// Confirm button in the extra-term editor sheet
  ///
  /// In en, this message translates to:
  /// **'ADD TERM'**
  String get offeringAddTerm;

  /// Past events step subtitle
  ///
  /// In en, this message translates to:
  /// **'Show communities what events have been hosted at your venue before.'**
  String get pastEventsSubtitle;

  /// Button label while profile events load
  ///
  /// In en, this message translates to:
  /// **'Loading profile events...'**
  String get pastEventsLoadingProfileEvents;

  /// Button to import events from the profile
  ///
  /// In en, this message translates to:
  /// **'Select from profile'**
  String get pastEventsSelectFromProfile;

  /// Button to add a new past event entry
  ///
  /// In en, this message translates to:
  /// **'Add a past event'**
  String get pastEventsAddPastEvent;

  /// Snackbar when there are no more events to import
  ///
  /// In en, this message translates to:
  /// **'All profile events are already added.'**
  String get pastEventsAllAlreadyAdded;

  /// Snackbar confirming how many events were imported
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Imported {count} profile event.} other{Imported {count} profile events.}}'**
  String pastEventsImported(num count);

  /// Snackbar when imported events had media trimmed to the per-event limits
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Imported {count} profile event. Each past event keeps up to 3 photos and 1 video — extra media was trimmed.} other{Imported {count} profile events. Each past event keeps up to 3 photos and 1 video — extra media was trimmed.}}'**
  String pastEventsImportedMediaTrimmed(num count);

  /// Header for each past event card
  ///
  /// In en, this message translates to:
  /// **'Event {number}'**
  String pastEventsEventNumber(int number);

  /// Label for the event name field
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get pastEventsEventNameLabel;

  /// Hint for the event name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Wellness Meetup'**
  String get pastEventsEventNameHint;

  /// Label for the event date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pastEventsDateLabel;

  /// Label for the partner name field
  ///
  /// In en, this message translates to:
  /// **'Partner Name'**
  String get pastEventsPartnerNameLabel;

  /// Hint for the partner name field
  ///
  /// In en, this message translates to:
  /// **'e.g. City Runners Club'**
  String get pastEventsPartnerNameHint;

  /// Label for the event photos section
  ///
  /// In en, this message translates to:
  /// **'Photos (max 3)'**
  String get pastEventsPhotosLabel;

  /// Label for the event recap video section
  ///
  /// In en, this message translates to:
  /// **'Recap Video (max 1)'**
  String get pastEventsRecapVideoLabel;

  /// Chip label for an attached recap video
  ///
  /// In en, this message translates to:
  /// **'Recap video'**
  String get pastEventsRecapVideoChip;

  /// Snackbar when a past-event media upload fails
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String pastEventsUploadFailed(String error);

  /// Product details step section header
  ///
  /// In en, this message translates to:
  /// **'YOUR PRODUCT OR SERVICE'**
  String get productDetailsSectionHeader;

  /// Label for the listing title field
  ///
  /// In en, this message translates to:
  /// **'Listing Title'**
  String get productDetailsListingTitleLabel;

  /// Hint for the listing title field
  ///
  /// In en, this message translates to:
  /// **'e.g. Organic Cold Brew - Perfect for Community Events'**
  String get productDetailsListingTitleHint;

  /// Label for the product name field
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productDetailsProductNameLabel;

  /// Hint for the product name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Organic Cold Brew Coffee'**
  String get productDetailsProductNameHint;

  /// Label for the product type selector
  ///
  /// In en, this message translates to:
  /// **'Product Type'**
  String get productDetailsProductTypeLabel;

  /// Label for the description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDetailsDescriptionLabel;

  /// Hint for the description field
  ///
  /// In en, this message translates to:
  /// **'Describe your product or service...'**
  String get productDetailsDescriptionHint;

  /// Label for the offer headline field
  ///
  /// In en, this message translates to:
  /// **'Offer Headline'**
  String get productDetailsOfferHeadlineLabel;

  /// Helper text for the offer headline field
  ///
  /// In en, this message translates to:
  /// **'One short line communities will see on your card.'**
  String get productDetailsOfferHeadlineHelper;

  /// Hint for the offer headline field
  ///
  /// In en, this message translates to:
  /// **'e.g. Free with any 5+ order'**
  String get productDetailsOfferHeadlineHint;

  /// Label for the city dropdown
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get productDetailsCityLabel;

  /// Hint for the city dropdown
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get productDetailsSelectCityHint;

  /// Error shown when the city list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load cities'**
  String get productDetailsFailedToLoadCities;

  /// Venue details step section header
  ///
  /// In en, this message translates to:
  /// **'PROMOTION DETAILS'**
  String get venueDetailsSectionHeader;

  /// Label for the venue listing title field
  ///
  /// In en, this message translates to:
  /// **'Listing Title'**
  String get venueDetailsListingTitleLabel;

  /// Hint for the venue listing title field
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunset rooftop social for local creators'**
  String get venueDetailsListingTitleHint;

  /// Label for the campaign description field
  ///
  /// In en, this message translates to:
  /// **'Campaign Description'**
  String get venueDetailsCampaignDescriptionLabel;

  /// Hint for the campaign description field
  ///
  /// In en, this message translates to:
  /// **'Tell communities what kind of experience you want to host and why your venue is a great fit.'**
  String get venueDetailsCampaignDescriptionHint;

  /// Label for the venue offer headline field
  ///
  /// In en, this message translates to:
  /// **'Offer Headline'**
  String get venueDetailsOfferHeadlineLabel;

  /// Helper text for the venue offer headline field
  ///
  /// In en, this message translates to:
  /// **'One short line communities will see on your card.'**
  String get venueDetailsOfferHeadlineHelper;

  /// Hint for the venue offer headline field
  ///
  /// In en, this message translates to:
  /// **'e.g. 20% off Tuesdays for groups of 10+'**
  String get venueDetailsOfferHeadlineHint;

  /// Label on the linked primary venue summary card
  ///
  /// In en, this message translates to:
  /// **'PRIMARY VENUE'**
  String get venueDetailsPrimaryVenue;

  /// Fallback word used when no venue type is set
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venueDetailsVenueFallback;

  /// Venue type and capacity summary line
  ///
  /// In en, this message translates to:
  /// **'{type} • Capacity {capacity}'**
  String venueDetailsTypeCapacity(String type, String capacity);

  /// Community info step: section header for community type selection
  ///
  /// In en, this message translates to:
  /// **'YOUR COMMUNITY TYPE'**
  String get communityInfoTypeHeader;

  /// Community info step: subtitle under the community type header
  ///
  /// In en, this message translates to:
  /// **'Help businesses understand your audience. Select up to 3.'**
  String get communityInfoTypeSubtitle;

  /// Community info step: label for the community size field
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY SIZE'**
  String get communityInfoCommunitySizeLabel;

  /// Community info step: hint for the community size number field
  ///
  /// In en, this message translates to:
  /// **'e.g., 500'**
  String get communityInfoCommunitySizeHint;

  /// Community info step: label for the expected attendees field
  ///
  /// In en, this message translates to:
  /// **'EXPECTED ATTENDEES'**
  String get communityInfoExpectedAttendeesLabel;

  /// Community info step: hint for the expected attendees number field
  ///
  /// In en, this message translates to:
  /// **'e.g., 50'**
  String get communityInfoExpectedAttendeesHint;

  /// Event details step: section header
  ///
  /// In en, this message translates to:
  /// **'KOLAB DETAILS'**
  String get eventDetailsHeader;

  /// Event details step: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'Describe your kolab and what you offer'**
  String get eventDetailsSubtitle;

  /// Event details step: label for the title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventDetailsTitleLabel;

  /// Event details step: hint for the kolab title field
  ///
  /// In en, this message translates to:
  /// **'e.g., Fitness Community x Local Cafe'**
  String get eventDetailsTitleHint;

  /// Event details step: label for the description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventDetailsDescriptionLabel;

  /// Event details step: hint for the description field
  ///
  /// In en, this message translates to:
  /// **'Describe what you are looking for and how this kolab would work...'**
  String get eventDetailsDescriptionHint;

  /// Event details step: section header for the deliverables the community offers
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU OFFER IN RETURN'**
  String get eventDetailsOffersHeader;

  /// Logistics step: availability section header
  ///
  /// In en, this message translates to:
  /// **'AVAILABILITY'**
  String get logisticsAvailabilityHeader;

  /// Logistics step: subtitle under the availability header
  ///
  /// In en, this message translates to:
  /// **'When is your community available for this kolab?'**
  String get logisticsAvailabilitySubtitle;

  /// Logistics step: location section header
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get logisticsLocationHeader;

  /// Logistics step: label for the preferred city dropdown
  ///
  /// In en, this message translates to:
  /// **'Preferred City'**
  String get logisticsPreferredCityLabel;

  /// Logistics step: error shown when the cities list fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading cities: {error}'**
  String logisticsCitiesLoadError(String error);

  /// Logistics step: hint for the city dropdown
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get logisticsSelectCityHint;

  /// Logistics step: label for the optional neighbourhood/area field
  ///
  /// In en, this message translates to:
  /// **'Preferred Neighbourhood / Area (optional)'**
  String get logisticsPreferredAreaLabel;

  /// Logistics step: hint for the neighbourhood/area autocomplete field
  ///
  /// In en, this message translates to:
  /// **'e.g., Shoreditch, Kreuzberg'**
  String get logisticsPreferredAreaHint;

  /// Logistics step: date picker label for the start of availability
  ///
  /// In en, this message translates to:
  /// **'Available From'**
  String get logisticsAvailableFromLabel;

  /// Logistics step: date picker label for the end of availability
  ///
  /// In en, this message translates to:
  /// **'Available Until'**
  String get logisticsAvailableUntilLabel;

  /// Logistics step: label for the time picker
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get logisticsTimeLabel;

  /// Logistics step: label for the recurring day-of-week selector
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get logisticsDayOfWeekLabel;

  /// Logistics step: placeholder shown in the date picker before a date is chosen
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get logisticsSelectDate;

  /// Logistics step: placeholder shown in the time picker before a time is chosen
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get logisticsSelectTime;

  /// Photo step: section header
  ///
  /// In en, this message translates to:
  /// **'ADD A PHOTO'**
  String get photoAddHeader;

  /// Photo step: subtitle under the header
  ///
  /// In en, this message translates to:
  /// **'This will appear on your kolab card in Explore.'**
  String get photoAddSubtitle;

  /// Photo step: option to use the community profile photo
  ///
  /// In en, this message translates to:
  /// **'Use your community profile photo'**
  String get photoUseProfilePhoto;

  /// Photo step: OR divider between the two photo options
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get photoDividerOr;

  /// Photo step: button to pick an existing gallery or past-event photo
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery or past events'**
  String get photoChooseFromGallery;

  /// Photo step: title inside the upload drop zone
  ///
  /// In en, this message translates to:
  /// **'Upload a photo'**
  String get photoUploadTitle;

  /// Photo step: max file size hint inside the upload drop zone
  ///
  /// In en, this message translates to:
  /// **'Max 5MB'**
  String get photoUploadMaxSize;

  /// Photo step: snackbar shown when the photo upload fails
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String photoUploadFailed(String error);

  /// Photo step: title of the existing-photo picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Use a gallery or past-event photo'**
  String get photoPickerSheetTitle;

  /// Photo step: confirm button label in the existing-photo picker sheet
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get photoPickerConfirmLabel;

  /// Photo step: title of the uploaded-photo confirmation card
  ///
  /// In en, this message translates to:
  /// **'Uploaded photo selected'**
  String get photoUploadedSelectedTitle;

  /// Photo step: subtitle of the uploaded-photo confirmation card
  ///
  /// In en, this message translates to:
  /// **'This image will appear on your kolab card in Explore.'**
  String get photoUploadedSelectedSubtitle;

  /// Photo step: button to revert to the community profile photo
  ///
  /// In en, this message translates to:
  /// **'Use profile photo'**
  String get photoUseProfilePhotoButton;

  /// Photo step: button to replace the uploaded photo
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get photoReplacePhotoButton;

  /// AppBar title on the new-kolab intent selection screen
  ///
  /// In en, this message translates to:
  /// **'NEW KOLAB'**
  String get intentSelectionAppBarTitle;

  /// Headline for community users on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get intentSelectionCommunityTitle;

  /// Headline for business users on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'What would you like to promote?'**
  String get intentSelectionBusinessTitle;

  /// Subtitle for community users on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to kolab with businesses.'**
  String get intentSelectionCommunitySubtitle;

  /// Subtitle for business users on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to promote to communities.'**
  String get intentSelectionBusinessSubtitle;

  /// Intent option title: find a venue or sponsor
  ///
  /// In en, this message translates to:
  /// **'Find a Venue or Brand'**
  String get intentSelectionFindVenueTitle;

  /// Intent option subtitle: find a venue or sponsor
  ///
  /// In en, this message translates to:
  /// **'for my community event'**
  String get intentSelectionFindVenueSubtitle;

  /// Badge indicating a free option
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get intentSelectionBadgeFree;

  /// Intent option title: promote my venue
  ///
  /// In en, this message translates to:
  /// **'Promote my Venue'**
  String get intentSelectionPromoteVenueTitle;

  /// Intent option subtitle: promote my venue
  ///
  /// In en, this message translates to:
  /// **'Get communities to host events at your location'**
  String get intentSelectionPromoteVenueSubtitle;

  /// Intent option title: promote a product or service
  ///
  /// In en, this message translates to:
  /// **'Promote a Product or Service'**
  String get intentSelectionPromoteProductTitle;

  /// Intent option subtitle: promote a product or service
  ///
  /// In en, this message translates to:
  /// **'Get communities to feature your products at their events'**
  String get intentSelectionPromoteProductSubtitle;

  /// Error shown when the profile fails to load on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile'**
  String get intentSelectionProfileLoadError;

  /// Hint shown below the profile load error on the intent selection screen
  ///
  /// In en, this message translates to:
  /// **'Please try again to continue creating a kolab.'**
  String get intentSelectionProfileLoadErrorHint;

  /// Locked-state title for business users without a subscription
  ///
  /// In en, this message translates to:
  /// **'An active subscription is required to create Kolabs.'**
  String get intentSelectionLockedTitle;

  /// Locked-state subtitle for business users without a subscription
  ///
  /// In en, this message translates to:
  /// **'Upgrade your business plan to publish venue or product opportunities for communities.'**
  String get intentSelectionLockedSubtitle;

  /// Button to upgrade the subscription so the user can create kolabs
  ///
  /// In en, this message translates to:
  /// **'Upgrade to create'**
  String get intentSelectionUpgradeButton;

  /// Fallback message when the kolab flow opens without a selected intent
  ///
  /// In en, this message translates to:
  /// **'No intent selected'**
  String get kolabFlowNoIntentSelected;

  /// AppBar title for the community-seeking kolab flow
  ///
  /// In en, this message translates to:
  /// **'FIND A PARTNER'**
  String get kolabFlowTitleFindPartner;

  /// AppBar title for the venue promotion kolab flow
  ///
  /// In en, this message translates to:
  /// **'PROMOTE VENUE'**
  String get kolabFlowTitlePromoteVenue;

  /// AppBar title for the product promotion kolab flow
  ///
  /// In en, this message translates to:
  /// **'PROMOTE PRODUCT'**
  String get kolabFlowTitlePromoteProduct;

  /// Success dialog title after publishing a kolab
  ///
  /// In en, this message translates to:
  /// **'Kolab Published!'**
  String get kolabFlowPublishedTitle;

  /// Success dialog title after saving a kolab draft
  ///
  /// In en, this message translates to:
  /// **'Draft Saved!'**
  String get kolabFlowDraftSavedTitle;

  /// Success dialog message after publishing a kolab
  ///
  /// In en, this message translates to:
  /// **'Your kolab is now visible in Explore.'**
  String get kolabFlowPublishedMessage;

  /// Success dialog message after saving a kolab draft
  ///
  /// In en, this message translates to:
  /// **'You can continue editing later.'**
  String get kolabFlowDraftSavedMessage;

  /// Title of the My Kolabs hub screen
  ///
  /// In en, this message translates to:
  /// **'MY KOLABS'**
  String get myKolabsHubTitle;

  /// My Kolabs hub tab: offers
  ///
  /// In en, this message translates to:
  /// **'OFFERS'**
  String get myKolabsHubTabOffers;

  /// My Kolabs hub tab: requests
  ///
  /// In en, this message translates to:
  /// **'REQUESTS'**
  String get myKolabsHubTabRequests;

  /// My Kolabs hub tab: active
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get myKolabsHubTabActive;

  /// My Kolabs hub tab: finished
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get myKolabsHubTabFinished;

  /// Empty-state title for the active kolabs tab
  ///
  /// In en, this message translates to:
  /// **'No active kolabs'**
  String get myKolabsHubActiveEmptyTitle;

  /// Empty-state message for the active kolabs tab
  ///
  /// In en, this message translates to:
  /// **'Once an application is accepted by both sides, the kolab shows up here while it\'s underway.'**
  String get myKolabsHubActiveEmptyMessage;

  /// Empty-state title for the finished kolabs tab
  ///
  /// In en, this message translates to:
  /// **'Nothing finished yet'**
  String get myKolabsHubFinishedEmptyTitle;

  /// Empty-state message for the finished kolabs tab
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled kolabs will be collected here.'**
  String get myKolabsHubFinishedEmptyMessage;

  /// Tooltip for the create-kolab floating action button
  ///
  /// In en, this message translates to:
  /// **'Create Kolab'**
  String get myKolabsHubCreateTooltip;

  /// Subtitle showing how many previously uploaded photos can be selected
  ///
  /// In en, this message translates to:
  /// **'Select up to {count, plural, =1{1 previously uploaded photo} other{{count} previously uploaded photos}}.'**
  String existingPhotoPickerSubtitle(num count);

  /// Empty state when there are no reusable photos in the picker
  ///
  /// In en, this message translates to:
  /// **'No reusable photos yet.'**
  String get existingPhotoPickerEmpty;

  /// Action bar button to save the kolab as a draft
  ///
  /// In en, this message translates to:
  /// **'SAVE DRAFT'**
  String get kolabActionBarSaveDraft;

  /// Action bar button to publish the kolab
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get kolabActionBarPublish;

  /// Review card section header: title and description
  ///
  /// In en, this message translates to:
  /// **'Title & Description'**
  String get kolabReviewSectionTitleDescription;

  /// Review card section header: what you need
  ///
  /// In en, this message translates to:
  /// **'What You Need'**
  String get kolabReviewSectionWhatYouNeed;

  /// Review card section header: community info
  ///
  /// In en, this message translates to:
  /// **'Community Info'**
  String get kolabReviewSectionCommunityInfo;

  /// Review card section header: offers in return
  ///
  /// In en, this message translates to:
  /// **'Offers in Return'**
  String get kolabReviewSectionOffersInReturn;

  /// Review card section header: location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get kolabReviewSectionLocation;

  /// Review card section header: campaign and venue
  ///
  /// In en, this message translates to:
  /// **'Campaign & Venue'**
  String get kolabReviewSectionCampaignVenue;

  /// Review card section header: media
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get kolabReviewSectionMedia;

  /// Review card section header: what you offer
  ///
  /// In en, this message translates to:
  /// **'What You Offer'**
  String get kolabReviewSectionWhatYouOffer;

  /// Review card section header: seeking communities
  ///
  /// In en, this message translates to:
  /// **'Seeking Communities'**
  String get kolabReviewSectionSeekingCommunities;

  /// Review card section header: past events
  ///
  /// In en, this message translates to:
  /// **'Past Events'**
  String get kolabReviewSectionPastEvents;

  /// Review card section header: product info
  ///
  /// In en, this message translates to:
  /// **'Product Info'**
  String get kolabReviewSectionProductInfo;

  /// Review card section header: availability
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get kolabReviewSectionAvailability;

  /// Review card field label: title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get kolabReviewFieldTitle;

  /// Review card field label: description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get kolabReviewFieldDescription;

  /// Review card field label: types
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get kolabReviewFieldTypes;

  /// Review card field label: community size
  ///
  /// In en, this message translates to:
  /// **'Community Size'**
  String get kolabReviewFieldCommunitySize;

  /// Review card field label: typical attendance
  ///
  /// In en, this message translates to:
  /// **'Typical Attendance'**
  String get kolabReviewFieldTypicalAttendance;

  /// Review card field label: city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get kolabReviewFieldCity;

  /// Review card field label: area
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get kolabReviewFieldArea;

  /// Review card field label: venue
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get kolabReviewFieldVenue;

  /// Review card field label: type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get kolabReviewFieldType;

  /// Review card field label: capacity
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get kolabReviewFieldCapacity;

  /// Review card field label: address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get kolabReviewFieldAddress;

  /// Review card field label: photos / videos
  ///
  /// In en, this message translates to:
  /// **'Photos / Videos'**
  String get kolabReviewFieldPhotosVideos;

  /// Review card field label: events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get kolabReviewFieldEvents;

  /// Review card field label: name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get kolabReviewFieldName;

  /// Review card field label: schedule
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get kolabReviewFieldSchedule;

  /// Empty hint when no needs are selected
  ///
  /// In en, this message translates to:
  /// **'No needs selected'**
  String get kolabReviewEmptyNeeds;

  /// Empty hint when no community info is provided
  ///
  /// In en, this message translates to:
  /// **'No community info provided'**
  String get kolabReviewEmptyCommunityInfo;

  /// Empty hint when no offers are selected
  ///
  /// In en, this message translates to:
  /// **'No offers selected'**
  String get kolabReviewEmptyOffers;

  /// Empty hint when no offerings are listed
  ///
  /// In en, this message translates to:
  /// **'No offerings listed'**
  String get kolabReviewEmptyOfferings;

  /// Empty hint when no communities are selected
  ///
  /// In en, this message translates to:
  /// **'No communities selected'**
  String get kolabReviewEmptyCommunities;

  /// Value shown when no media has been added
  ///
  /// In en, this message translates to:
  /// **'No media added'**
  String get kolabReviewNoMedia;

  /// Value shown when no past events have been added
  ///
  /// In en, this message translates to:
  /// **'No past events added'**
  String get kolabReviewNoPastEvents;

  /// Count of media items in the review card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String kolabReviewMediaCount(num count);

  /// Count of past events in the review card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String kolabReviewEventsCount(num count);

  /// Availability start date line in the review card
  ///
  /// In en, this message translates to:
  /// **'From: {date}'**
  String kolabReviewAvailabilityFrom(String date);

  /// Availability end date line in the review card
  ///
  /// In en, this message translates to:
  /// **'To: {date}'**
  String kolabReviewAvailabilityTo(String date);

  /// Fallback title for a kolab card with no title
  ///
  /// In en, this message translates to:
  /// **'Untitled Kolab'**
  String get myKolabCardUntitled;

  /// My kolab card action button: view
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get myKolabCardActionView;

  /// My kolab card action button: edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get myKolabCardActionEdit;

  /// My kolab card action button: publish
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get myKolabCardActionPublish;

  /// My kolab card action button: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get myKolabCardActionClose;

  /// My kolab card action button: delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get myKolabCardActionDelete;

  /// My kolab card status badge: published
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED'**
  String get myKolabCardStatusPublished;

  /// My kolab card status badge: closed
  ///
  /// In en, this message translates to:
  /// **'CLOSED'**
  String get myKolabCardStatusClosed;

  /// My kolab card status badge: completed
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get myKolabCardStatusCompleted;

  /// My kolab card status badge: draft
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get myKolabCardStatusDraft;

  /// Title of the profile event picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Choose from your profile events'**
  String get profileEventPickerTitle;

  /// Subtitle showing how many profile events can be imported
  ///
  /// In en, this message translates to:
  /// **'Select up to {count, plural, =1{1 event} other{{count} events}} to import.'**
  String profileEventPickerSubtitle(num count);

  /// Button to import selected profile events
  ///
  /// In en, this message translates to:
  /// **'Import events'**
  String get profileEventPickerImport;

  /// App bar title on the notifications listing screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// Action button to mark all notifications as read
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsScreenMarkAllRead;

  /// Title shown when the notifications list is empty
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsScreenEmptyTitle;

  /// Subtitle shown when the notifications list is empty
  ///
  /// In en, this message translates to:
  /// **'When you receive messages or application updates, they\'ll show up here.'**
  String get notificationsScreenEmptyBody;

  /// Tooltip for the notification bell icon button
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationBellTooltip;

  /// Business onboarding final: email field empty validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get businessFinalEmailRequired;

  /// Business onboarding final: invalid email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get businessFinalEmailInvalid;

  /// Business onboarding final: password field empty validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get businessFinalPasswordRequired;

  /// Business onboarding final: password too short validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get businessFinalPasswordTooShort;

  /// Business onboarding final: confirm password empty validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get businessFinalConfirmPasswordRequired;

  /// Business onboarding final: passwords mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get businessFinalPasswordsMismatch;

  /// Business onboarding final: generic signup failure banner title
  ///
  /// In en, this message translates to:
  /// **'Sign-up failed'**
  String get businessFinalSignupFailed;

  /// Business onboarding final: network error snackbar message
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get businessFinalNoInternet;

  /// Business onboarding final: confirmation after copying error details
  ///
  /// In en, this message translates to:
  /// **'Error details copied to clipboard'**
  String get businessFinalErrorCopied;

  /// Business onboarding final: copy error details button
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get businessFinalCopyDetails;

  /// Business onboarding final: title when user is already authenticated
  ///
  /// In en, this message translates to:
  /// **'Finish business onboarding'**
  String get businessFinalTitleAuthenticated;

  /// Business onboarding final: title for new account creation
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get businessFinalTitleNewAccount;

  /// Business onboarding final: subtitle when authenticated
  ///
  /// In en, this message translates to:
  /// **'Review your imported details one last time and save your business profile.'**
  String get businessFinalSubtitleAuthenticated;

  /// Business onboarding final: subtitle for new account
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to complete registration'**
  String get businessFinalSubtitleNewAccount;

  /// Business onboarding final: edit summary button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get businessFinalEdit;

  /// Business onboarding final: email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get businessFinalEmailLabel;

  /// Business onboarding final: email field hint placeholder
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get businessFinalEmailHint;

  /// Business onboarding final: password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get businessFinalPasswordLabel;

  /// Business onboarding final: password field hint
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get businessFinalPasswordHint;

  /// Business onboarding final: confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get businessFinalConfirmPasswordLabel;

  /// Business onboarding final: confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get businessFinalConfirmPasswordHint;

  /// Business onboarding final: info box for already-authenticated flow
  ///
  /// In en, this message translates to:
  /// **'Your account is already created. Tapping the button below will save this onboarding data to the business onboarding endpoint.'**
  String get businessFinalAuthenticatedInfo;

  /// Business onboarding final: complete button when authenticated
  ///
  /// In en, this message translates to:
  /// **'COMPLETE ONBOARDING'**
  String get businessFinalCompleteButton;

  /// Business onboarding final: create account button
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get businessFinalCreateAccountButton;

  /// Business onboarding final: bottom note for authenticated flow
  ///
  /// In en, this message translates to:
  /// **'We only save the selected Google photos when the onboarding request succeeds.'**
  String get businessFinalTermsAuthenticated;

  /// Business onboarding final: terms and privacy note
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms of Service and Privacy Policy'**
  String get businessFinalTermsNewAccount;

  /// Business onboarding step 2: photo permission denied error
  ///
  /// In en, this message translates to:
  /// **'Please allow Photos access in Settings to add venue images.'**
  String get businessStep2PhotoAccessDenied;

  /// Business onboarding step 2: generic photo library error
  ///
  /// In en, this message translates to:
  /// **'We could not open your photo library. Please try again.'**
  String get businessStep2PhotoLibraryError;

  /// Business onboarding step 2: incomplete form error before continuing
  ///
  /// In en, this message translates to:
  /// **'Complete the required business details, add at least one venue photo, and enter venue capacity before continuing.'**
  String get businessStep2IncompleteError;

  /// Business onboarding step 2: phone must start with plus error
  ///
  /// In en, this message translates to:
  /// **'Must start with + (e.g. +34612345678)'**
  String get businessStep2PhoneMustStartPlus;

  /// Business onboarding step 2: phone digits-only error
  ///
  /// In en, this message translates to:
  /// **'Use E.164 format with digits only'**
  String get businessStep2PhoneDigitsOnly;

  /// Business onboarding step 2: phone too short error
  ///
  /// In en, this message translates to:
  /// **'Enter at least 9 digits after +'**
  String get businessStep2PhoneTooShort;

  /// Business onboarding step 2: phone too long error
  ///
  /// In en, this message translates to:
  /// **'Phone number too long'**
  String get businessStep2PhoneTooLong;

  /// Business onboarding step 2: screen title
  ///
  /// In en, this message translates to:
  /// **'Review your business details'**
  String get businessStep2Title;

  /// Business onboarding step 2: screen subtitle
  ///
  /// In en, this message translates to:
  /// **'We imported what we could from Google. Review it, fill in capacity, and curate the final venue gallery before you finish.'**
  String get businessStep2Subtitle;

  /// Business onboarding step 2: imported-from-Google banner
  ///
  /// In en, this message translates to:
  /// **'Imported from Google. You can edit every field before saving.'**
  String get businessStep2ImportedBanner;

  /// Business onboarding step 2: add brand logo upload label
  ///
  /// In en, this message translates to:
  /// **'Add logo (optional)'**
  String get businessStep2AddLogo;

  /// Business onboarding step 2: venue address field label
  ///
  /// In en, this message translates to:
  /// **'Venue Address'**
  String get businessStep2VenueAddressLabel;

  /// Business onboarding step 2: business name field label
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessStep2BusinessNameLabel;

  /// Business onboarding step 2: business name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get businessStep2BusinessNameHint;

  /// Business onboarding step 2: business type field label
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessStep2BusinessTypeLabel;

  /// Business onboarding step 2: business type selection helper
  ///
  /// In en, this message translates to:
  /// **'Select up to 3 categories that describe your business.'**
  String get businessStep2BusinessTypeHint;

  /// Business onboarding step 2: business types load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load business types'**
  String get businessStep2BusinessTypesLoadError;

  /// Business onboarding step 2: venue type field label
  ///
  /// In en, this message translates to:
  /// **'Venue Type'**
  String get businessStep2VenueTypeLabel;

  /// Business onboarding step 2: capacity field label
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get businessStep2CapacityLabel;

  /// Business onboarding step 2: capacity helper text
  ///
  /// In en, this message translates to:
  /// **'Google does not provide venue capacity, so you still need to enter it manually.'**
  String get businessStep2CapacityHelper;

  /// Business onboarding step 2: capacity field hint
  ///
  /// In en, this message translates to:
  /// **'How many people can you host?'**
  String get businessStep2CapacityHint;

  /// Business onboarding step 2: venue photos field label
  ///
  /// In en, this message translates to:
  /// **'Venue Photos'**
  String get businessStep2VenuePhotosLabel;

  /// Business onboarding step 2: about field label
  ///
  /// In en, this message translates to:
  /// **'About Your Business'**
  String get businessStep2AboutLabel;

  /// Business onboarding step 2: about field hint
  ///
  /// In en, this message translates to:
  /// **'Share what makes your business special'**
  String get businessStep2AboutHint;

  /// Business onboarding step 2: phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get businessStep2PhoneLabel;

  /// Business onboarding step 2: Instagram field label (brand name, untranslated)
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get businessStep2InstagramLabel;

  /// Business onboarding step 2: website field label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get businessStep2WebsiteLabel;

  /// Business onboarding step 2: change venue button
  ///
  /// In en, this message translates to:
  /// **'Change venue'**
  String get businessStep2ChangeVenue;

  /// Business onboarding step 3: photo permission denied error
  ///
  /// In en, this message translates to:
  /// **'Please allow Photos access in Settings to add venue images.'**
  String get businessStep3PhotoAccessDenied;

  /// Business onboarding step 3: generic photo library error
  ///
  /// In en, this message translates to:
  /// **'We could not open your photo library. Please try again.'**
  String get businessStep3PhotoLibraryError;

  /// Business onboarding step 3: no photos added error
  ///
  /// In en, this message translates to:
  /// **'Add at least one venue photo to continue'**
  String get businessStep3NoPhotosError;

  /// Business onboarding step 3: screen title
  ///
  /// In en, this message translates to:
  /// **'Add venue photos'**
  String get businessStep3Title;

  /// Business onboarding step 3: screen subtitle (Kolab is a brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'These become your reusable venue gallery, so you won’t need to upload them again every time you create a venue Kolab.'**
  String get businessStep3Subtitle;

  /// Business onboarding step 3: add photo tile label
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get businessStep3AddPhoto;

  /// Business onboarding step 5: pick address from suggestions error
  ///
  /// In en, this message translates to:
  /// **'Pick your venue address from the suggestions'**
  String get businessStep5PickAddressError;

  /// Business onboarding step 5: Google import fallback message
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t import from Google, please fill in manually.'**
  String get businessStep5ImportFallback;

  /// Business onboarding step 5: screen title
  ///
  /// In en, this message translates to:
  /// **'Choose your venue'**
  String get businessStep5Title;

  /// Business onboarding step 5: screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Search for your business venue and we will import the details we can from Google before you review them.'**
  String get businessStep5Subtitle;

  /// Business onboarding step 5: address search field hint
  ///
  /// In en, this message translates to:
  /// **'Search venue address'**
  String get businessStep5SearchHint;

  /// Business onboarding step 5: empty query hint
  ///
  /// In en, this message translates to:
  /// **'Start typing your venue address to see suggestions.'**
  String get businessStep5HintStartTyping;

  /// Business onboarding step 5: no matches hint
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Try adding the city to the address.'**
  String get businessStep5HintNoMatches;

  /// Business onboarding step 5: suggestions load error
  ///
  /// In en, this message translates to:
  /// **'We could not load venue suggestions right now.'**
  String get businessStep5SuggestionsError;

  /// Business onboarding step 5: importing overlay message
  ///
  /// In en, this message translates to:
  /// **'Importing your business info from Google'**
  String get businessStep5Importing;

  /// Business onboarding step 5: imported photos preview title
  ///
  /// In en, this message translates to:
  /// **'Photos from Google'**
  String get businessStep5PreviewTitle;

  /// Business onboarding step 5: imported photos preview subtitle
  ///
  /// In en, this message translates to:
  /// **'We imported these photos for your venue. Tap the X to remove any you do not want before continuing. You can add your own later.'**
  String get businessStep5PreviewSubtitle;

  /// Business onboarding step 5: no imported photos left hint
  ///
  /// In en, this message translates to:
  /// **'No photos left. Continue to add your own, or go back to pick a different venue.'**
  String get businessStep5NoPhotosLeft;

  /// Business onboarding step 5: selected address card heading
  ///
  /// In en, this message translates to:
  /// **'Selected address'**
  String get businessStep5SelectedAddress;

  /// Community onboarding final screen title
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get communityFinalTitle;

  /// Community onboarding final screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to complete registration'**
  String get communityFinalSubtitle;

  /// Edit button under the summary card
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get communityFinalEdit;

  /// Email field label on community final screen
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get communityFinalEmailLabel;

  /// Email field hint on community final screen
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get communityFinalEmailHint;

  /// Password field label on community final screen
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get communityFinalPasswordLabel;

  /// Password field hint on community final screen
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get communityFinalPasswordHint;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get communityFinalConfirmPasswordLabel;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get communityFinalConfirmPasswordHint;

  /// Validation error when email is empty
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get communityFinalEmailRequired;

  /// Validation error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get communityFinalEmailInvalid;

  /// Validation error when password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get communityFinalPasswordRequired;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get communityFinalPasswordMinLength;

  /// Validation error when confirm password is empty
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get communityFinalConfirmPasswordRequired;

  /// Validation error when passwords differ
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get communityFinalPasswordsMismatch;

  /// Network error snackbar message
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get communityFinalNoInternet;

  /// Register button on community final screen
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get communityFinalCreateAccountButton;

  /// Terms and privacy notice below register button
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms of Service and Privacy Policy'**
  String get communityFinalTermsNotice;

  /// Community onboarding step 1 title
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get communityStep1Title;

  /// Community onboarding step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your profile'**
  String get communityStep1Subtitle;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get communityStep1DisplayNameLabel;

  /// Display name field hint
  ///
  /// In en, this message translates to:
  /// **'Your name or handle'**
  String get communityStep1NameHint;

  /// Validation snackbar when display name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your display name'**
  String get communityStep1NameRequired;

  /// Community onboarding step 2 title
  ///
  /// In en, this message translates to:
  /// **'What type of community are you?'**
  String get communityStep2Title;

  /// Community onboarding step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Help businesses understand your community'**
  String get communityStep2Subtitle;

  /// Validation snackbar when community type not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a community type'**
  String get communityStep2TypeRequired;

  /// Error message when community types fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load community types'**
  String get communityStep2LoadError;

  /// Community onboarding step 3 title
  ///
  /// In en, this message translates to:
  /// **'Where are you located?'**
  String get communityStep3Title;

  /// Community onboarding step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Find opportunities in your area'**
  String get communityStep3Subtitle;

  /// City search field hint
  ///
  /// In en, this message translates to:
  /// **'Search cities...'**
  String get communityStep3SearchHint;

  /// Section label above popular cities list
  ///
  /// In en, this message translates to:
  /// **'Popular Cities:'**
  String get communityStep3PopularCities;

  /// Empty state when no cities match search
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get communityStep3NoCitiesFound;

  /// Error message when cities fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load cities'**
  String get communityStep3LoadError;

  /// Validation snackbar when city not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get communityStep3CityRequired;

  /// Community onboarding step 4 title
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get communityStep4Title;

  /// Community onboarding step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your social links (all optional)'**
  String get communityStep4Subtitle;

  /// About/bio field label
  ///
  /// In en, this message translates to:
  /// **'About / Bio'**
  String get communityStep4AboutLabel;

  /// About/bio field hint
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get communityStep4AboutHint;

  /// Hint for social handle fields (Instagram, TikTok)
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get communityStep4UsernameHint;

  /// Website field label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get communityStep4WebsiteLabel;

  /// Website field hint placeholder
  ///
  /// In en, this message translates to:
  /// **'www.example.com'**
  String get communityStep4WebsiteHint;

  /// Error shown when selected image exceeds size limit
  ///
  /// In en, this message translates to:
  /// **'Image must be less than 5MB'**
  String get photoUploadFileTooLarge;

  /// Generic error when image selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get photoUploadSelectFailed;

  /// Error with retry suggestion when image selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select image. Please try again.'**
  String get photoUploadSelectFailedRetry;

  /// Error when photo library permission is denied
  ///
  /// In en, this message translates to:
  /// **'Please allow Photos access in Settings to upload an image.'**
  String get photoUploadPhotosAccessDenied;

  /// Error when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Please allow Camera access in Settings to take a photo.'**
  String get photoUploadCameraAccessDenied;

  /// Bottom sheet option to pick from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get photoUploadChooseLibrary;

  /// Bottom sheet option to take a photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get photoUploadTakePhoto;

  /// Bottom sheet option to change the current photo
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get photoUploadChangePhoto;

  /// Bottom sheet option to remove the current photo
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get photoUploadRemovePhoto;

  /// Label under photo prompting to change it
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get photoUploadTapToChange;

  /// Button to add a venue photo
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get venuePhotoAddPhoto;

  /// Attribution label for Google-imported photos
  ///
  /// In en, this message translates to:
  /// **'Powered by Google'**
  String get venuePhotoPoweredByGoogle;

  /// Empty state title for venue photos
  ///
  /// In en, this message translates to:
  /// **'Add venue photos'**
  String get venuePhotoEmptyTitle;

  /// Empty state description for venue photos
  ///
  /// In en, this message translates to:
  /// **'Keep imported Google photos, upload your own, remove what you do not want, and set the final order here.'**
  String get venuePhotoEmptyDescription;

  /// Source badge for a Google-imported photo
  ///
  /// In en, this message translates to:
  /// **'Google import'**
  String get venuePhotoSourceGoogle;

  /// Source badge for a previously saved photo
  ///
  /// In en, this message translates to:
  /// **'Saved photo'**
  String get venuePhotoSourceSaved;

  /// Source badge for a newly uploaded photo
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get venuePhotoSourceUpload;

  /// Position label showing photo index within total
  ///
  /// In en, this message translates to:
  /// **'Photo {position} of {total}'**
  String venuePhotoPositionLabel(num position, num total);

  /// Tooltip to move a photo earlier in order
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get venuePhotoMoveEarlier;

  /// Tooltip to move a photo later in order
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get venuePhotoMoveLater;

  /// Tooltip to remove a photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get venuePhotoRemovePhoto;

  /// Button to view photo author credits
  ///
  /// In en, this message translates to:
  /// **'Photo credits'**
  String get venuePhotoCredits;

  /// Title of the photo credits bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Google photo credits'**
  String get venuePhotoCreditsSheetTitle;

  /// Profile reviews screen AppBar title when no profile name is available
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profileReviewsTitle;

  /// Profile reviews screen AppBar title including the profile owner's name
  ///
  /// In en, this message translates to:
  /// **'{name} Reviews'**
  String profileReviewsTitleNamed(String name);

  /// Error message shown when the profile reviews list fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews.'**
  String get profileReviewsLoadError;

  /// Empty state message when a profile has no reviews
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get profileReviewsEmpty;

  /// Empty state body explaining when reviews will appear.
  ///
  /// In en, this message translates to:
  /// **'Reviews appear here once this profile completes its first Kolab.'**
  String get profileReviewsEmptyBody;

  /// Button to load the next page of profile reviews
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get profileReviewsLoadMore;

  /// Title shown in the reputation summary card when a profile has no reviews
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get publicProfileReputationEmptyTitle;

  /// Body text shown in the reputation summary card when a profile has no reviews
  ///
  /// In en, this message translates to:
  /// **'Completed Kolabs will appear here once partners leave reviews.'**
  String get publicProfileReputationEmptyBody;

  /// Review count shown in the reputation summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String publicProfileReputationReviewsCount(int count);

  /// Unique partner count shown in the reputation summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 partner} other{{count} partners}}'**
  String publicProfileReputationPartnersCount(int count);

  /// Completed Kolabs count shown in the reputation summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed} other{{count} completed}}'**
  String reputationCompletedKolabsCount(int count);

  /// Section title for the about/bio section on a public profile
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get publicProfileAbout;

  /// Error title shown when a public profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get publicProfileLoadError;

  /// Section title for the list of a profile's past collaborations (Kolabs is the brand term, kept untranslated)
  ///
  /// In en, this message translates to:
  /// **'Past Kolabs'**
  String get publicProfilePastKolabs;

  /// Empty state when a profile has no past collaborations
  ///
  /// In en, this message translates to:
  /// **'No past kolabs yet'**
  String get publicProfileNoPastKolabs;

  /// Section title for a profile's social media links
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get publicProfileSocialLinks;

  /// Secondary CTA on the public profile bottom bar to dismiss without proposing
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get publicProfileSaveForLater;

  /// Primary CTA for a business to send a collaboration proposal to a community (Kolab is the brand term, kept untranslated). Displayed uppercase
  ///
  /// In en, this message translates to:
  /// **'SEND A KOLAB PROPOSAL'**
  String get publicProfileSendKolabProposal;

  /// Section title for the recent reviews preview on a public profile
  ///
  /// In en, this message translates to:
  /// **'Recent Reviews'**
  String get publicProfileRecentReviews;

  /// Button to open the full reviews list from the recent reviews section
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get publicProfileViewMore;

  /// Stat label for total points on a member (attendee) public profile
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get memberProfilePoints;

  /// Stat label for the number of events a member has attended on their public profile
  ///
  /// In en, this message translates to:
  /// **'Events attended'**
  String get memberProfileEventsAttended;

  /// Stat label and section title for a member's earned badges on their public profile
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get memberProfileBadges;

  /// Empty state shown in the badges section of a member public profile when they have not earned any badges
  ///
  /// In en, this message translates to:
  /// **'No badges yet'**
  String get memberProfileNoBadges;

  /// Snackbar shown after the referral code is copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referralCodeCopied;

  /// App bar title on the referral program screen
  ///
  /// In en, this message translates to:
  /// **'REFERRAL PROGRAM'**
  String get referralScreenTitle;

  /// Label above the large referral code display
  ///
  /// In en, this message translates to:
  /// **'YOUR REFERRAL CODE'**
  String get referralScreenYourCode;

  /// Button label to copy the referral code
  ///
  /// In en, this message translates to:
  /// **'COPY CODE'**
  String get referralScreenCopyCode;

  /// Button label to share the referral code
  ///
  /// In en, this message translates to:
  /// **'SHARE CODE'**
  String get referralScreenShareCode;

  /// Section header for the how-it-works steps
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get referralScreenHowItWorks;

  /// Title of referral step 1
  ///
  /// In en, this message translates to:
  /// **'Share your unique code'**
  String get referralScreenStep1Title;

  /// Description of referral step 1
  ///
  /// In en, this message translates to:
  /// **'Send your referral code to friends and colleagues.'**
  String get referralScreenStep1Desc;

  /// Title of referral step 2
  ///
  /// In en, this message translates to:
  /// **'A business subscribes using your code'**
  String get referralScreenStep2Title;

  /// Description of referral step 2
  ///
  /// In en, this message translates to:
  /// **'When they sign up and choose a plan, they enter your code.'**
  String get referralScreenStep2Desc;

  /// Title of referral step 3 for business users
  ///
  /// In en, this message translates to:
  /// **'You earn 1 free month of subscription'**
  String get referralScreenStep3TitleBusiness;

  /// Title of referral step 3 for community users
  ///
  /// In en, this message translates to:
  /// **'You earn 50-100 points (EUR 10-EUR 20)'**
  String get referralScreenStep3TitleCommunity;

  /// Description of referral step 3 for business users
  ///
  /// In en, this message translates to:
  /// **'Your next billing cycle is automatically extended.'**
  String get referralScreenStep3DescBusiness;

  /// Description of referral step 3 for community users
  ///
  /// In en, this message translates to:
  /// **'Points are added to your wallet and can be withdrawn.'**
  String get referralScreenStep3DescCommunity;

  /// Section header for the reward tiers table
  ///
  /// In en, this message translates to:
  /// **'REWARD TIERS'**
  String get referralScreenRewardTiers;

  /// Tier table condition for businesses
  ///
  /// In en, this message translates to:
  /// **'Each successful referral'**
  String get referralScreenTierBusinessCondition;

  /// Tier table reward for businesses
  ///
  /// In en, this message translates to:
  /// **'1 free month'**
  String get referralScreenTierBusinessReward;

  /// Tier table condition for a referral lasting 1 month
  ///
  /// In en, this message translates to:
  /// **'Referred user stays 1 month'**
  String get referralScreenTier1MonthCondition;

  /// Tier table reward for a referral lasting 1 month
  ///
  /// In en, this message translates to:
  /// **'50 pts (EUR 10)'**
  String get referralScreenTier1MonthReward;

  /// Tier table condition for a referral lasting 4 months
  ///
  /// In en, this message translates to:
  /// **'Referred user stays 4 months'**
  String get referralScreenTier4MonthCondition;

  /// Tier table reward for a referral lasting 4 months
  ///
  /// In en, this message translates to:
  /// **'100 pts (EUR 20)'**
  String get referralScreenTier4MonthReward;

  /// App bar title on the XP and badges wallet screen
  ///
  /// In en, this message translates to:
  /// **'XP & REPUTATION'**
  String get walletScreenTitle;

  /// Section header for the ways-to-earn XP card
  ///
  /// In en, this message translates to:
  /// **'WAYS TO EARN XP'**
  String get walletScreenWaysToEarn;

  /// Section header for the badges grid
  ///
  /// In en, this message translates to:
  /// **'BADGES'**
  String get walletScreenBadges;

  /// Section header for the cash referral milestone card
  ///
  /// In en, this message translates to:
  /// **'CASH REFERRAL'**
  String get walletScreenCashReferral;

  /// Section header for the XP ledger history
  ///
  /// In en, this message translates to:
  /// **'XP HISTORY'**
  String get walletScreenXpHistory;

  /// Label under the large XP total in the wallet card
  ///
  /// In en, this message translates to:
  /// **'XP POINTS'**
  String get walletScreenXpPoints;

  /// Total XP label in the wallet card
  ///
  /// In en, this message translates to:
  /// **'Total XP: {count}'**
  String walletScreenTotalXp(num count);

  /// Progress label showing XP remaining until the next tier
  ///
  /// In en, this message translates to:
  /// **'{count} XP to {tier}'**
  String walletScreenXpToNext(num count, String tier);

  /// Positive XP amount badge (earned points)
  ///
  /// In en, this message translates to:
  /// **'+{count} XP'**
  String walletScreenXpGain(num count);

  /// XP amount badge for a ledger entry (e.g. negative or neutral)
  ///
  /// In en, this message translates to:
  /// **'{count} XP'**
  String walletScreenXpAmount(num count);

  /// Ways-to-earn mission: complete a kolab
  ///
  /// In en, this message translates to:
  /// **'Complete a kolab'**
  String get walletScreenMissionCompleteKolab;

  /// Ways-to-earn mission: post a review
  ///
  /// In en, this message translates to:
  /// **'Post a review'**
  String get walletScreenMissionPostReview;

  /// Ways-to-earn mission: share user-generated content
  ///
  /// In en, this message translates to:
  /// **'Share content (UGC)'**
  String get walletScreenMissionShareContent;

  /// Ways-to-earn mission: refer a business
  ///
  /// In en, this message translates to:
  /// **'Refer a business'**
  String get walletScreenMissionReferBusiness;

  /// Empty placeholder when no badges exist
  ///
  /// In en, this message translates to:
  /// **'No badges available'**
  String get walletScreenNoBadges;

  /// Title of the cash referral milestone card
  ///
  /// In en, this message translates to:
  /// **'Earn €75 Cash'**
  String get walletScreenEarnCashTitle;

  /// Subtitle of the cash referral milestone card
  ///
  /// In en, this message translates to:
  /// **'Refer 3 businesses on a 4-month plan'**
  String get walletScreenEarnCashSubtitle;

  /// Shown when the referral cash milestone is reached
  ///
  /// In en, this message translates to:
  /// **'Milestone reached! Request your cash reward.'**
  String get walletScreenMilestoneReached;

  /// Progress text toward the referral cash milestone
  ///
  /// In en, this message translates to:
  /// **'{conversions} / {goal} businesses referred · {remaining} more to go'**
  String walletScreenMilestoneProgress(
    num conversions,
    num goal,
    num remaining,
  );

  /// Default share message containing the referral code
  ///
  /// In en, this message translates to:
  /// **'Join Kolabing with my code: {code}'**
  String walletScreenShareMessage(String code);

  /// Button label to share the referral link
  ///
  /// In en, this message translates to:
  /// **'SHARE LINK'**
  String get walletScreenShareLink;

  /// Button label to request the 75 EUR cash reward
  ///
  /// In en, this message translates to:
  /// **'REQUEST €75'**
  String get walletScreenRequestCash;

  /// Empty placeholder when the XP ledger is empty
  ///
  /// In en, this message translates to:
  /// **'No XP activity yet — complete a kolab!'**
  String get walletScreenNoXpActivity;

  /// Button to load more XP ledger entries
  ///
  /// In en, this message translates to:
  /// **'LOAD MORE'**
  String get walletScreenLoadMore;

  /// App bar title on the withdrawal request screen
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get withdrawalScreenTitle;

  /// Fallback error when a withdrawal request fails
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request failed'**
  String get withdrawalRequestFailed;

  /// Validation error when IBAN is empty
  ///
  /// In en, this message translates to:
  /// **'IBAN is required'**
  String get withdrawalIbanRequired;

  /// Validation error when IBAN length is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid IBAN (15-34 characters)'**
  String get withdrawalIbanInvalid;

  /// Validation error when account holder name is empty
  ///
  /// In en, this message translates to:
  /// **'Account holder name is required'**
  String get withdrawalAccountHolderRequired;

  /// Title of the withdrawal success state
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get withdrawalSuccessTitle;

  /// Body of the withdrawal success state
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal request has been submitted successfully. Processing within 5-7 business days.'**
  String get withdrawalSuccessMessage;

  /// Button to return to the wallet after submitting a withdrawal
  ///
  /// In en, this message translates to:
  /// **'BACK TO WALLET'**
  String get withdrawalBackToWallet;

  /// Label above the available withdrawal amount
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw'**
  String get withdrawalAvailableLabel;

  /// Field label for the IBAN input
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get withdrawalIbanLabel;

  /// Hint text showing an example IBAN
  ///
  /// In en, this message translates to:
  /// **'e.g. DE89 3704 0044 0532 0130 00'**
  String get withdrawalIbanHint;

  /// Field label for the account holder name input
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT HOLDER NAME'**
  String get withdrawalAccountHolderLabel;

  /// Hint text for the account holder name input
  ///
  /// In en, this message translates to:
  /// **'Full name on bank account'**
  String get withdrawalAccountHolderHint;

  /// Submit button label including the amount to withdraw
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW EUR {amount}'**
  String withdrawalSubmitButton(String amount);

  /// Eyebrow label on the referral banner card
  ///
  /// In en, this message translates to:
  /// **'EARN BY SHARING'**
  String get referralBannerEarnBySharing;

  /// Tagline on the referral banner card
  ///
  /// In en, this message translates to:
  /// **'Refer 3 businesses → earn €75 cash'**
  String get referralBannerTagline;

  /// Button on the referral banner that opens the share sheet
  ///
  /// In en, this message translates to:
  /// **'Share referral code'**
  String get referralBannerShareButton;

  /// Referral banner step 1 label (verb)
  ///
  /// In en, this message translates to:
  /// **'Refer'**
  String get referralBannerStepReferLabel;

  /// Referral banner step 1 value (who to refer)
  ///
  /// In en, this message translates to:
  /// **'3 businesses'**
  String get referralBannerStepReferValue;

  /// Referral banner step 2 label (verb)
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get referralBannerStepEarnLabel;

  /// Referral banner reward amount
  ///
  /// In en, this message translates to:
  /// **'€75'**
  String get referralBannerStepEarnAmount;

  /// Referral banner reward suffix (e.g. cash)
  ///
  /// In en, this message translates to:
  /// **'cash'**
  String get referralBannerStepEarnSuffix;

  /// Title of the referral code bottom sheet
  ///
  /// In en, this message translates to:
  /// **'YOUR REFERRAL CODE'**
  String get referralSheetYourCode;

  /// Instructions in the referral code bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Ask businesses to use this code during signup.'**
  String get referralSheetInstructions;

  /// Copy button in the referral code bottom sheet
  ///
  /// In en, this message translates to:
  /// **'COPY CODE'**
  String get referralSheetCopyCode;

  /// Share button in the referral code bottom sheet
  ///
  /// In en, this message translates to:
  /// **'SHARE CODE'**
  String get referralSheetShareCode;

  /// Snackbar when the share sheet is unavailable and the code is copied instead
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable. Referral code copied.'**
  String get referralSheetShareUnavailable;

  /// Snackbar when opening the share sheet fails and the code is copied instead
  ///
  /// In en, this message translates to:
  /// **'Could not open share sheet. Referral code copied.'**
  String get referralSheetShareFailed;

  /// Theme selector section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeSelectorTitle;

  /// Theme option label: follow system theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSelectorSystemLabel;

  /// Theme option description for system mode
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get themeSelectorSystemDescription;

  /// Theme option label: light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeSelectorLightLabel;

  /// Theme option description for light mode
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeSelectorLightDescription;

  /// Theme option label: dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeSelectorDarkLabel;

  /// Theme option description for dark mode
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeSelectorDarkDescription;

  /// Referral code text field label
  ///
  /// In en, this message translates to:
  /// **'Referral Code (optional)'**
  String get referralCodeFieldLabel;

  /// Referral code text field hint
  ///
  /// In en, this message translates to:
  /// **'Paste referral code'**
  String get referralCodeFieldHint;

  /// Quick filter chip fallback label for city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get discoveryQuickFilterCity;

  /// Quick filter chip fallback label for Kolab type
  ///
  /// In en, this message translates to:
  /// **'Kolab Type'**
  String get discoveryQuickFilterKolabType;

  /// Quick filter chip fallback label for what a community offers
  ///
  /// In en, this message translates to:
  /// **'What They Offer'**
  String get discoveryQuickFilterWhatTheyOffer;

  /// Quick filter chip fallback label for availability
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get discoveryQuickFilterAvailability;

  /// Quick filter chip fallback label for need type
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get discoveryQuickFilterNeed;

  /// Quick filter chip fallback label for community type
  ///
  /// In en, this message translates to:
  /// **'Community Type'**
  String get discoveryQuickFilterCommunityType;

  /// Quick filter chip fallback label for audience size
  ///
  /// In en, this message translates to:
  /// **'Audience Size'**
  String get discoveryQuickFilterAudienceSize;

  /// Profile gallery section header
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileGallerySectionTitle;

  /// Add photo button in profile gallery header
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileGallerySectionAdd;

  /// Profile gallery upload-in-progress label
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get profileGallerySectionUploading;

  /// Title of the add-photo bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Add Gallery Photo'**
  String get profileGallerySheetTitle;

  /// Take photo option in add-photo sheet
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get profileGallerySheetTakePhoto;

  /// Subtitle for take-photo option
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get profileGallerySheetTakePhotoSubtitle;

  /// Choose-from-gallery option in add-photo sheet
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profileGallerySheetChooseGallery;

  /// Subtitle for choose-from-gallery option
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo'**
  String get profileGallerySheetChooseGallerySubtitle;

  /// Empty gallery title for a business profile
  ///
  /// In en, this message translates to:
  /// **'Showcase your venue'**
  String get profileGalleryEmptyTitleBusiness;

  /// Empty gallery title for a community profile
  ///
  /// In en, this message translates to:
  /// **'Showcase your community'**
  String get profileGalleryEmptyTitleCommunity;

  /// Empty gallery body for a business profile
  ///
  /// In en, this message translates to:
  /// **'Add venue photos so kolab partners can see your space before they apply.'**
  String get profileGalleryEmptyBodyBusiness;

  /// Empty gallery body for a community profile
  ///
  /// In en, this message translates to:
  /// **'Add photos from your events so new kolab partners understand your community.'**
  String get profileGalleryEmptyBodyCommunity;

  /// Delete photo confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get profileGalleryDeleteTitle;

  /// Delete photo confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this photo?'**
  String get profileGalleryDeleteBody;

  /// Delete confirm button in delete photo dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileGalleryDeleteConfirm;

  /// Search field hint in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Search by title, description, or creator...'**
  String get exploreFilterSearchHint;

  /// City section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get exploreFilterCity;

  /// City field hint in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Type a city'**
  String get exploreFilterCityHint;

  /// Availability section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get exploreFilterAvailability;

  /// Kolab type section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Kolab Type'**
  String get exploreFilterKolabType;

  /// What-they-offer section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'What They Offer'**
  String get exploreFilterWhatTheyOffer;

  /// Venue type section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Venue Type'**
  String get exploreFilterVenueType;

  /// Product type section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Product Type'**
  String get exploreFilterProductType;

  /// Expected deliverables section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Expected Deliverables'**
  String get exploreFilterExpectedDeliverables;

  /// Minimum community size requirement section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Minimum Community Size Requirement'**
  String get exploreFilterMinCommunitySize;

  /// Need section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get exploreFilterNeed;

  /// Community type section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Community Type'**
  String get exploreFilterCommunityType;

  /// Audience size section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Audience Size'**
  String get exploreFilterAudienceSize;

  /// Offers-in-return section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Offers In Return'**
  String get exploreFilterOffersInReturn;

  /// Venue preference section label in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Venue Preference'**
  String get exploreFilterVenuePreference;

  /// Explore filter sheet header title
  ///
  /// In en, this message translates to:
  /// **'Search & Filter'**
  String get exploreFilterTitle;

  /// Clear all filters action in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get exploreFilterClearAll;

  /// Empty result message in the city autocomplete
  ///
  /// In en, this message translates to:
  /// **'No matching cities found'**
  String get exploreFilterNoMatchingCities;

  /// Error message when city suggestions fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load city suggestions'**
  String get exploreFilterCitySuggestionsError;

  /// Results count footer in the explore filter sheet
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Showing all opportunities} =1{1 result found} other{{count} results found}}'**
  String exploreFilterResultsCount(num count);

  /// Match-score badge on an explore swipe card
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String exploreSwipeCardMatch(num score);

  /// Fallback category label for a business offer card
  ///
  /// In en, this message translates to:
  /// **'Business Offer'**
  String get exploreSwipeCardBusinessOffer;

  /// Fallback category label for a community request card
  ///
  /// In en, this message translates to:
  /// **'Community Request'**
  String get exploreSwipeCardCommunityRequest;

  /// Count of past Kolabs on a swipe card (Kolabs is a brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'{count} Kolabs'**
  String exploreSwipeCardKolabsCount(num count);

  /// Number of previous Kolabs on a swipe card (Kolab is a brand term, untranslated)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 previous Kolab} other{{count} previous Kolabs}}'**
  String exploreSwipeCardPreviousKolabs(num count);

  /// View details row on an explore swipe card
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get exploreSwipeCardViewDetails;

  /// Fallback name shown when the creator is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get exploreDetailUnknownCreator;

  /// Hint shown on a blurred community identity in the detail sheet
  ///
  /// In en, this message translates to:
  /// **'Subscribe to reveal this community'**
  String get exploreDetailSubscribeToReveal;

  /// Fallback type badge label when the creator type is unknown
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get exploreDetailCreatorBadge;

  /// Summary card title for what a community is looking for
  ///
  /// In en, this message translates to:
  /// **'What they are looking for'**
  String get exploreDetailLookingFor;

  /// Summary card title for what a community offers
  ///
  /// In en, this message translates to:
  /// **'What they offer'**
  String get exploreDetailWhatTheyOffer;

  /// Summary card title for community size
  ///
  /// In en, this message translates to:
  /// **'Community size'**
  String get exploreDetailCommunitySize;

  /// Community size value (members in the community)
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String exploreDetailScaleCommunity(num count);

  /// Typical attendance value (expected attendees)
  ///
  /// In en, this message translates to:
  /// **'~{count} expected to attend'**
  String exploreDetailScaleExpected(num count);

  /// Offer summary section title in the detail sheet
  ///
  /// In en, this message translates to:
  /// **'What\'s Offered'**
  String get exploreDetailWhatsOffered;

  /// Available days section title in the detail sheet
  ///
  /// In en, this message translates to:
  /// **'Available Days'**
  String get exploreDetailAvailableDays;

  /// Primary CTA when applying requires a subscription
  ///
  /// In en, this message translates to:
  /// **'UNLOCK TO APPLY'**
  String get exploreDetailUnlockToApply;

  /// Primary CTA to apply to an opportunity
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get exploreDetailApplyNow;

  /// Secondary link to open the creator's public profile
  ///
  /// In en, this message translates to:
  /// **'View creator profile'**
  String get exploreDetailViewCreatorProfile;

  /// Past event photos section title in the detail sheet
  ///
  /// In en, this message translates to:
  /// **'Past event photos'**
  String get exploreDetailPastEventPhotos;

  /// Subtitle under the past event photos section
  ///
  /// In en, this message translates to:
  /// **'Recent moments from this community'**
  String get exploreDetailRecentMoments;

  /// Subscription screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionScreenTitle;

  /// Snackbar error when starting an Apple IAP purchase fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start App Store purchase'**
  String get subscriptionScreenAppleError;

  /// Snackbar error when creating the Stripe checkout session fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create checkout session'**
  String get subscriptionScreenCheckoutError;

  /// Helper text shown when a referral code is validated and applied
  ///
  /// In en, this message translates to:
  /// **'Referral code applied.'**
  String get subscriptionReferralCodeApplied;

  /// Snackbar confirming the subscription was reactivated
  ///
  /// In en, this message translates to:
  /// **'Subscription reactivated successfully'**
  String get subscriptionReactivateSuccess;

  /// Snackbar confirming the subscription cancellation is scheduled
  ///
  /// In en, this message translates to:
  /// **'Subscription will cancel at the end of billing period'**
  String get subscriptionCancelScheduledToast;

  /// Title of the cancel-subscription confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get subscriptionCancelDialogTitle;

  /// Body text of the cancel-subscription confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Your subscription will remain active until the end of the current billing period. You can resubscribe at any time.\n\nAre you sure you want to cancel?'**
  String get subscriptionCancelDialogBody;

  /// Dialog button to keep the subscription (dismiss cancel)
  ///
  /// In en, this message translates to:
  /// **'Keep Subscription'**
  String get subscriptionKeepButton;

  /// Button to cancel the subscription
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get subscriptionCancelButton;

  /// Status card / plan title for an active premium business subscription
  ///
  /// In en, this message translates to:
  /// **'Premium Business'**
  String get subscriptionStatusPremiumTitle;

  /// Status card subtitle when subscription is active
  ///
  /// In en, this message translates to:
  /// **'Your subscription is active'**
  String get subscriptionStatusActiveSubtitle;

  /// Status card title when subscription is scheduled to cancel
  ///
  /// In en, this message translates to:
  /// **'Subscription Ending'**
  String get subscriptionStatusEndingTitle;

  /// Status card subtitle when subscription is ending at period end
  ///
  /// In en, this message translates to:
  /// **'Active until end of billing period'**
  String get subscriptionStatusEndingSubtitle;

  /// Status card / warning title when a payment failed (past due)
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get subscriptionStatusPastDueTitle;

  /// Status card subtitle when subscription is past due
  ///
  /// In en, this message translates to:
  /// **'Please update your payment method'**
  String get subscriptionStatusPastDueSubtitle;

  /// Status card title when there is no active subscription
  ///
  /// In en, this message translates to:
  /// **'No Active Plan'**
  String get subscriptionStatusNoPlanTitle;

  /// Status card subtitle when there is no active subscription
  ///
  /// In en, this message translates to:
  /// **'Subscribe to publish opportunities'**
  String get subscriptionStatusNoPlanSubtitle;

  /// Section title for the premium benefits list
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits'**
  String get subscriptionBenefitsTitle;

  /// Benefit item title: publish opportunities
  ///
  /// In en, this message translates to:
  /// **'Publish Opportunities'**
  String get subscriptionBenefitPublishTitle;

  /// Benefit item description: publish kolab offers
  ///
  /// In en, this message translates to:
  /// **'Create and publish kolab offers'**
  String get subscriptionBenefitPublishDesc;

  /// Benefit item title: connect with communities
  ///
  /// In en, this message translates to:
  /// **'Connect with Communities'**
  String get subscriptionBenefitConnectTitle;

  /// Benefit item description: reach communities and creators
  ///
  /// In en, this message translates to:
  /// **'Reach local communities and creators'**
  String get subscriptionBenefitConnectDesc;

  /// Benefit item title: receive applications
  ///
  /// In en, this message translates to:
  /// **'Receive Applications'**
  String get subscriptionBenefitApplicationsTitle;

  /// Benefit item description: applications from communities
  ///
  /// In en, this message translates to:
  /// **'Get applications from interested communities'**
  String get subscriptionBenefitApplicationsDesc;

  /// Benefit item title: track performance
  ///
  /// In en, this message translates to:
  /// **'Track Performance'**
  String get subscriptionBenefitTrackTitle;

  /// Benefit item description: monitor kolab metrics
  ///
  /// In en, this message translates to:
  /// **'Monitor your kolab metrics'**
  String get subscriptionBenefitTrackDesc;

  /// Price unit suffix appended after the amount (per month)
  ///
  /// In en, this message translates to:
  /// **'EUR/month'**
  String get subscriptionPerMonthUnit;

  /// Section title for plan details when subscribed
  ///
  /// In en, this message translates to:
  /// **'Plan Details'**
  String get subscriptionPlanDetailsTitle;

  /// Detail row label: plan name
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subscriptionDetailPlanLabel;

  /// Detail row label: price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get subscriptionDetailPriceLabel;

  /// Monthly price value shown in plan details
  ///
  /// In en, this message translates to:
  /// **'49 EUR/month'**
  String get subscriptionPriceMonthly;

  /// Detail row label: current billing period start
  ///
  /// In en, this message translates to:
  /// **'Current Period'**
  String get subscriptionDetailCurrentPeriodLabel;

  /// Detail row label: renewal date
  ///
  /// In en, this message translates to:
  /// **'Renews On'**
  String get subscriptionDetailRenewsOnLabel;

  /// Detail row label: days remaining in period
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get subscriptionDetailDaysRemainingLabel;

  /// Days remaining value with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String subscriptionDaysValue(num count);

  /// Warning banner body when subscription payment is past due
  ///
  /// In en, this message translates to:
  /// **'Your last payment failed. Update your payment method to continue publishing opportunities.'**
  String get subscriptionPastDueWarningBody;

  /// Warning banner title when cancellation is scheduled
  ///
  /// In en, this message translates to:
  /// **'Cancellation Scheduled'**
  String get subscriptionCancelPendingTitle;

  /// Warning banner body showing the active-until date for a scheduled cancellation
  ///
  /// In en, this message translates to:
  /// **'Your subscription is active until {endDate}. After that, you will not be able to publish new opportunities.'**
  String subscriptionCancelPendingBody(String endDate);

  /// Fallback phrase used in place of a date when the billing period end is unknown
  ///
  /// In en, this message translates to:
  /// **'end of billing period'**
  String get subscriptionEndOfBillingPeriod;

  /// Button to reactivate a subscription scheduled to cancel
  ///
  /// In en, this message translates to:
  /// **'REACTIVATE SUBSCRIPTION'**
  String get subscriptionReactivateButton;

  /// Subscribe button label (iOS, no price)
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE'**
  String get subscriptionSubscribeButton;

  /// Subscribe button label with price (Android/Stripe)
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE FOR 49 EUR/MONTH'**
  String get subscriptionSubscribePricedButton;

  /// Button to update payment method when past due
  ///
  /// In en, this message translates to:
  /// **'UPDATE PAYMENT METHOD'**
  String get subscriptionUpdatePaymentButton;

  /// Button to manage billing for an active subscription
  ///
  /// In en, this message translates to:
  /// **'MANAGE BILLING'**
  String get subscriptionManageBillingButton;

  /// Placeholder while the App Store product price is loading
  ///
  /// In en, this message translates to:
  /// **'Loading App Store price...'**
  String get subscriptionLoadingApplePrice;

  /// Shown when the App Store subscription product is unavailable
  ///
  /// In en, this message translates to:
  /// **'Subscription unavailable'**
  String get subscriptionUnavailable;

  /// App Store localized price followed by per-month suffix
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String subscriptionPricePerMonth(String price);

  /// Paywall snackbar error when starting an Apple IAP purchase fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start App Store purchase'**
  String get subscriptionPaywallAppleError;

  /// Paywall snackbar error when creating the Stripe checkout session fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create checkout session'**
  String get subscriptionPaywallCheckoutError;

  /// Paywall bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get subscriptionPaywallTitle;

  /// Paywall description explaining the free request was used up
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 1 free kolab request. Subscribe to create unlimited requests and connect with more communities.'**
  String get subscriptionPaywallDescription;

  /// Paywall benefit row: unlimited requests
  ///
  /// In en, this message translates to:
  /// **'Publish unlimited kolab requests'**
  String get subscriptionPaywallBenefitUnlimited;

  /// Paywall benefit row: connect with communities
  ///
  /// In en, this message translates to:
  /// **'Connect with local communities'**
  String get subscriptionPaywallBenefitConnect;

  /// Paywall benefit row: manage applications
  ///
  /// In en, this message translates to:
  /// **'Receive and manage applications'**
  String get subscriptionPaywallBenefitApplications;

  /// Per-month suffix shown after the price in the paywall
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get subscriptionPaywallPerMonth;

  /// No description provided for @subscriptionPlanMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionPlanMonthlyLabel;

  /// No description provided for @subscriptionPlanThreeMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get subscriptionPlanThreeMonthsLabel;

  /// No description provided for @subscriptionPlanBestValueBadge.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get subscriptionPlanBestValueBadge;

  /// No description provided for @subscriptionPlanPer3Months.
  ///
  /// In en, this message translates to:
  /// **'/ 3 months'**
  String get subscriptionPlanPer3Months;

  /// Per-month-equivalent price for a multi-month plan
  ///
  /// In en, this message translates to:
  /// **'≈ {price}/mo'**
  String subscriptionPlanPerMonthEq(String price);

  /// Savings percent of a multi-month plan vs paying monthly
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String subscriptionPlanSavePercent(int percent);

  /// Paywall primary subscribe button label
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE NOW'**
  String get subscriptionPaywallSubscribeButton;

  /// Paywall dismiss button label
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get subscriptionPaywallNotNowButton;

  /// iOS button to restore previous in-app purchases
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get subscriptionRestorePurchasesButton;

  /// Past events step section header (kolab creation flow)
  ///
  /// In en, this message translates to:
  /// **'PAST KOLABS (OPTIONAL)'**
  String get pastEventsStepHeader;

  /// Message shared from the referral screen/banner. {code} is the user's referral code.
  ///
  /// In en, this message translates to:
  /// **'Share Kolabing and earn — register your business with my referral code {code} during signup.'**
  String referralShareMessage(String code);

  /// No description provided for @dashboardBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS DASHBOARD'**
  String get dashboardBusinessTitle;

  /// No description provided for @dashboardCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY DASHBOARD'**
  String get dashboardCommunityTitle;

  /// Dashboard greeting. {name} is the user's display name.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String dashboardWelcomeBack(String name);

  /// No description provided for @dashboardErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard data'**
  String get dashboardErrorLoad;

  /// No description provided for @dashboardStatPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get dashboardStatPublished;

  /// No description provided for @dashboardStatPendingApplications.
  ///
  /// In en, this message translates to:
  /// **'Pending Applications'**
  String get dashboardStatPendingApplications;

  /// No description provided for @dashboardStatActiveKolabs.
  ///
  /// In en, this message translates to:
  /// **'Active Kolabs'**
  String get dashboardStatActiveKolabs;

  /// No description provided for @dashboardStatCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardStatCompleted;

  /// No description provided for @dashboardStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashboardStatPending;

  /// No description provided for @dashboardStatAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get dashboardStatAccepted;

  /// No description provided for @dashboardCreateKolabRequest.
  ///
  /// In en, this message translates to:
  /// **'CREATE KOLAB REQUEST'**
  String get dashboardCreateKolabRequest;

  /// No description provided for @dashboardFindAKolab.
  ///
  /// In en, this message translates to:
  /// **'Find a Kolab'**
  String get dashboardFindAKolab;

  /// No description provided for @dashboardMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My applications'**
  String get dashboardMyApplications;

  /// No description provided for @dashboardUpcomingKolabs.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING KOLABS'**
  String get dashboardUpcomingKolabs;

  /// No description provided for @dashboardMonthlyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH\'S GOAL'**
  String get dashboardMonthlyGoalTitle;

  /// Monthly collaboration goal progress, e.g. '1 of 1 Kolabs'.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {goal} Kolabs'**
  String dashboardMonthlyGoalProgress(int completed, int goal);

  /// No description provided for @dashboardNoUpcomingKolabs.
  ///
  /// In en, this message translates to:
  /// **'No upcoming kolabs yet'**
  String get dashboardNoUpcomingKolabs;

  /// No description provided for @dashboardDefaultBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get dashboardDefaultBusinessName;

  /// No description provided for @dashboardDefaultCommunityName.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get dashboardDefaultCommunityName;

  /// No description provided for @dashboardPositioningTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill your business with the right people.'**
  String get dashboardPositioningTitle;

  /// No description provided for @dashboardPositioningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create experiences that turn communities into visits, content and loyalty.'**
  String get dashboardPositioningSubtitle;

  /// No description provided for @dashboardActivityPillLabel.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS ACTIVITY'**
  String get dashboardActivityPillLabel;

  /// No description provided for @dashboardLiveOffersLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE OFFERS'**
  String get dashboardLiveOffersLabel;

  /// No description provided for @dashboardNewAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW APPS'**
  String get dashboardNewAppsLabel;

  /// No description provided for @dashboardActiveStatLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get dashboardActiveStatLabel;

  /// No description provided for @dashboardCompletedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get dashboardCompletedStatLabel;

  /// No description provided for @dashboardGrowSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'GROW YOUR BUSINESS'**
  String get dashboardGrowSectionTitle;

  /// No description provided for @dashboardGrowCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Kolab'**
  String get dashboardGrowCreateTitle;

  /// No description provided for @dashboardGrowCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a new offer for communities to apply'**
  String get dashboardGrowCreateSubtitle;

  /// No description provided for @dashboardGrowReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review applications'**
  String get dashboardGrowReviewTitle;

  /// Grow-section subtitle when there are pending applications.
  ///
  /// In en, this message translates to:
  /// **'{count} pending review'**
  String dashboardGrowReviewSubtitlePending(int count);

  /// No description provided for @dashboardGrowReviewSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending applications'**
  String get dashboardGrowReviewSubtitleEmpty;

  /// No description provided for @dashboardGrowFindSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse community requests'**
  String get dashboardGrowFindSubtitle;

  /// No description provided for @dashboardGrowViewKolabsTitle.
  ///
  /// In en, this message translates to:
  /// **'View your Kolabs'**
  String get dashboardGrowViewKolabsTitle;

  /// Grow-section subtitle summarizing active/completed collaborations.
  ///
  /// In en, this message translates to:
  /// **'{active} active · {completed} completed'**
  String dashboardGrowViewKolabsSubtitle(int active, int completed);

  /// No description provided for @dashboardEmptyUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Kolab to start filling your calendar'**
  String get dashboardEmptyUpcomingSubtitle;

  /// No description provided for @dashboardHeroCreateKolabButton.
  ///
  /// In en, this message translates to:
  /// **'+ CREATE A KOLAB'**
  String get dashboardHeroCreateKolabButton;

  /// Event hub: button to open the event chat thread
  ///
  /// In en, this message translates to:
  /// **'Open event chat'**
  String get eventHubOpenChat;

  /// Event hub: section header for confirmed attendees
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get eventHubAttendeesTitle;

  /// Event hub: section header for the waitlist
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get eventHubWaitlistTitle;

  /// Event hub: empty attendees state
  ///
  /// In en, this message translates to:
  /// **'No one has signed up yet.'**
  String get eventHubNoAttendees;

  /// Event hub: count of confirmed attendees
  ///
  /// In en, this message translates to:
  /// **'{count} going'**
  String eventHubGoingCount(num count);

  /// Event hub: count of waitlisted attendees
  ///
  /// In en, this message translates to:
  /// **'{count} on waitlist'**
  String eventHubWaitlistCount(num count);

  /// Event hub: capacity label
  ///
  /// In en, this message translates to:
  /// **'capacity {count}'**
  String eventHubCapacity(num count);

  /// Event hub: remaining spots
  ///
  /// In en, this message translates to:
  /// **'{count} spot(s) left'**
  String eventHubSpotsLeft(num count);

  /// Event hub: unlimited capacity label
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get eventHubUnlimited;

  /// RSVP button: join as going
  ///
  /// In en, this message translates to:
  /// **'I\'m going'**
  String get eventHubImGoing;

  /// RSVP button: currently going, tap to leave
  ///
  /// In en, this message translates to:
  /// **'Going ✓  ·  tap to leave'**
  String get eventHubGoingTapToLeave;

  /// RSVP button: join the waitlist when full
  ///
  /// In en, this message translates to:
  /// **'Join waitlist'**
  String get eventHubJoinWaitlist;

  /// RSVP button: currently waitlisted, tap to leave
  ///
  /// In en, this message translates to:
  /// **'On waitlist  ·  tap to leave'**
  String get eventHubOnWaitlistTapToLeave;

  /// Event hub: viewer waitlist position
  ///
  /// In en, this message translates to:
  /// **'You\'re #{position} on the waitlist'**
  String eventHubWaitlistPosition(num position);

  /// Event detail: tap the host community to open its public profile
  ///
  /// In en, this message translates to:
  /// **'View community'**
  String get eventDetailViewCommunity;

  /// Event hub: edit the event
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eventHubEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @eventHubDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get eventHubDelete;

  /// Event hub leader menu: open the QR scanner to check attendees in
  ///
  /// In en, this message translates to:
  /// **'Scan check-ins'**
  String get eventHubScanCheckIns;

  /// No description provided for @eventHubDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this event?'**
  String get eventHubDeleteConfirmTitle;

  /// No description provided for @eventHubDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" — anyone going or waitlisted will be notified it\'s cancelled.'**
  String eventHubDeleteConfirmBody(String name);

  /// No description provided for @eventHubDeleteScopeThis.
  ///
  /// In en, this message translates to:
  /// **'This event only'**
  String get eventHubDeleteScopeThis;

  /// No description provided for @eventHubDeleteScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and the following events'**
  String get eventHubDeleteScopeFollowing;

  /// No description provided for @eventHubDeleteScopeSeries.
  ///
  /// In en, this message translates to:
  /// **'The entire series'**
  String get eventHubDeleteScopeSeries;

  /// No description provided for @eventHubDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventHubDeleted;

  /// No description provided for @eventHubExtendSeries.
  ///
  /// In en, this message translates to:
  /// **'Extend series (+3 months)'**
  String get eventHubExtendSeries;

  /// No description provided for @eventHubExtended.
  ///
  /// In en, this message translates to:
  /// **'Series extended — {count} new dates'**
  String eventHubExtended(int count);

  /// No description provided for @eventHubExtendedNone.
  ///
  /// In en, this message translates to:
  /// **'No new dates to add'**
  String get eventHubExtendedNone;

  /// Event hub: add photos to the event gallery
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get eventHubAddPhotos;

  /// Create event form: app bar title
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventFormNewTitle;

  /// Edit event form: app bar title
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventFormEditTitle;

  /// Event form: save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventFormSave;

  /// Event form: publish a new event
  ///
  /// In en, this message translates to:
  /// **'Publish event'**
  String get eventFormPublish;

  /// No description provided for @eventFormRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get eventFormRepeatLabel;

  /// No description provided for @eventFormRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get eventFormRepeatNone;

  /// No description provided for @eventFormRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get eventFormRepeatWeekly;

  /// No description provided for @eventFormRepeatBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get eventFormRepeatBiweekly;

  /// No description provided for @eventFormRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get eventFormRepeatMonthly;

  /// No description provided for @eventFormRepeatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get eventFormRepeatEnds;

  /// No description provided for @eventFormRepeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get eventFormRepeatNever;

  /// No description provided for @eventFormRepeatAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get eventFormRepeatAfter;

  /// No description provided for @eventFormRepeatEvents.
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get eventFormRepeatEvents;

  /// No description provided for @eventFormRepeatOnDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get eventFormRepeatOnDate;

  /// No description provided for @eventFormRepeatChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat for this series'**
  String get eventFormRepeatChatLabel;

  /// No description provided for @eventFormRepeatChatPerEvent.
  ///
  /// In en, this message translates to:
  /// **'One chat per event'**
  String get eventFormRepeatChatPerEvent;

  /// No description provided for @eventFormRepeatChatShared.
  ///
  /// In en, this message translates to:
  /// **'One shared series chat'**
  String get eventFormRepeatChatShared;

  /// No description provided for @eventFormPublishSeries.
  ///
  /// In en, this message translates to:
  /// **'Publish series'**
  String get eventFormPublishSeries;

  /// No description provided for @eventFormApplyTo.
  ///
  /// In en, this message translates to:
  /// **'Apply changes to'**
  String get eventFormApplyTo;

  /// No description provided for @eventFormErrWeekday.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get eventFormErrWeekday;

  /// No description provided for @eventFormErrEndsCount.
  ///
  /// In en, this message translates to:
  /// **'Enter how many events'**
  String get eventFormErrEndsCount;

  /// No description provided for @eventFormErrEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Pick an end date after the start'**
  String get eventFormErrEndsOn;

  /// Event form: name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get eventFormNameLabel;

  /// Event form: name field hint
  ///
  /// In en, this message translates to:
  /// **'Saturday 10K'**
  String get eventFormNameHint;

  /// Event form: start date label
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventFormStartsLabel;

  /// Event form: end date label
  ///
  /// In en, this message translates to:
  /// **'Ends (optional)'**
  String get eventFormEndsLabel;

  /// Event form: start date picker hint
  ///
  /// In en, this message translates to:
  /// **'Pick start date & time'**
  String get eventFormPickStart;

  /// Event form: end date picker hint
  ///
  /// In en, this message translates to:
  /// **'Pick end date & time'**
  String get eventFormPickEnd;

  /// Event form: location label
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get eventFormLocationLabel;

  /// Event form: location hint
  ///
  /// In en, this message translates to:
  /// **'Ciutadella Park'**
  String get eventFormLocationHint;

  /// Event form: city label (the event's location city)
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get eventFormCityLabel;

  /// Event form: city picker placeholder when no city is chosen
  ///
  /// In en, this message translates to:
  /// **'Select a city'**
  String get eventFormCityHint;

  /// Event form: Google Places location search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search venue or address'**
  String get eventFormLocationSearchHint;

  /// Event form: location autocomplete empty-query hint
  ///
  /// In en, this message translates to:
  /// **'Start typing the venue or address to see suggestions.'**
  String get eventFormLocationStartTyping;

  /// Event form: location autocomplete no-results hint
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Try adding the city to the address.'**
  String get eventFormLocationNoMatches;

  /// Event form: location autocomplete error message
  ///
  /// In en, this message translates to:
  /// **'We could not load location suggestions right now.'**
  String get eventFormLocationError;

  /// Event form: read-only hint showing the city derived from the picked place
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String eventFormCityDetected(String city);

  /// Event form: hint when the picked place has no resolvable city
  ///
  /// In en, this message translates to:
  /// **'No city detected for this place. The event won\'t appear in city discovery.'**
  String get eventFormCityNotDetected;

  /// Event form: capacity label
  ///
  /// In en, this message translates to:
  /// **'Capacity (optional)'**
  String get eventFormCapacityLabel;

  /// Event form: capacity limit toggle label
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get eventFormLimit;

  /// Event form: tier-gate section label
  ///
  /// In en, this message translates to:
  /// **'Who can join'**
  String get eventFormWhoCanJoin;

  /// Event form: open to all members option
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get eventFormAllMembers;

  /// Event form: restrict to selected tiers option
  ///
  /// In en, this message translates to:
  /// **'Selected tiers'**
  String get eventFormSelectedTiers;

  /// Event form: section label for who can see the event.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get eventFormVisibilityLabel;

  /// Event visibility option: anyone can see it in city discovery.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get eventFormVisibilityPublic;

  /// Helper text for the Public visibility option.
  ///
  /// In en, this message translates to:
  /// **'Appears in city discovery — anyone can find it.'**
  String get eventFormVisibilityPublicHint;

  /// Event visibility option: visible to community members only.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get eventFormVisibilityMembers;

  /// Helper text for the Members visibility option.
  ///
  /// In en, this message translates to:
  /// **'Only your community members can see it.'**
  String get eventFormVisibilityMembersHint;

  /// Event visibility option: visible to selected membership tiers only.
  ///
  /// In en, this message translates to:
  /// **'Specific tier'**
  String get eventFormVisibilityTier;

  /// Helper text for the Specific tier visibility option.
  ///
  /// In en, this message translates to:
  /// **'Only members on the selected tiers can see it.'**
  String get eventFormVisibilityTierHint;

  /// Event form: photos section label
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get eventFormPhotos;

  /// Event form: pick photos from gallery
  ///
  /// In en, this message translates to:
  /// **'Add from gallery'**
  String get eventFormAddFromGallery;

  /// Event form: note that photos upload after creation
  ///
  /// In en, this message translates to:
  /// **'Photos can be added once the event is created.'**
  String get eventFormPhotosAfterCreate;

  /// Event form: name validation error
  ///
  /// In en, this message translates to:
  /// **'Event name needs at least 3 characters.'**
  String get eventFormErrName;

  /// Event form: missing start error
  ///
  /// In en, this message translates to:
  /// **'Pick a start date & time.'**
  String get eventFormErrStart;

  /// Event form: start-in-past error
  ///
  /// In en, this message translates to:
  /// **'Start must be in the future.'**
  String get eventFormErrStartFuture;

  /// Event form: end-before-start error
  ///
  /// In en, this message translates to:
  /// **'End must be after the start.'**
  String get eventFormErrEndAfterStart;

  /// Event form: invalid capacity error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid capacity, or turn off the limit.'**
  String get eventFormErrCapacity;

  /// Event form: error when 'Specific tier' visibility is chosen but no tier is selected.
  ///
  /// In en, this message translates to:
  /// **'Select at least one tier for this event.'**
  String get eventFormErrTier;

  /// Event form: photos uploaded confirmation
  ///
  /// In en, this message translates to:
  /// **'Photos uploaded.'**
  String get eventFormPhotosUploaded;

  /// Gallery: too many photos selected in one batch
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} photos at a time.'**
  String eventPhotosMaxPerAdd(int max);

  /// Gallery: total photo cap already reached
  ///
  /// In en, this message translates to:
  /// **'This gallery already has {count} of {max} photos.'**
  String eventPhotosTotalCapReached(int count, int max);

  /// Gallery: only some of the picked photos fit under the total cap
  ///
  /// In en, this message translates to:
  /// **'Only {allowed} more photos can be added (max {max} total).'**
  String eventPhotosTotalCapPartial(int allowed, int max);

  /// Event form: pick photos from the community's past-event gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from community gallery'**
  String get eventFormAddFromCommunity;

  /// Event form: title of the community gallery picker sheet
  ///
  /// In en, this message translates to:
  /// **'Community gallery'**
  String get eventFormCommunityGalleryTitle;

  /// Event form: empty state for the community gallery picker
  ///
  /// In en, this message translates to:
  /// **'No photos in the community gallery yet.'**
  String get eventFormCommunityGalleryEmpty;

  /// Event form: confirm button for adding selected community-gallery photos
  ///
  /// In en, this message translates to:
  /// **'Add {count} photos'**
  String eventFormCommunityGalleryAdd(int count);

  /// Community: action to share a join-invite link
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get communityShareInvite;

  /// Community: invite share message body
  ///
  /// In en, this message translates to:
  /// **'Join {name} on Kolabing: {url}'**
  String communityShareInviteMessage(String name, String url);

  /// Community: invite link copied to clipboard fallback
  ///
  /// In en, this message translates to:
  /// **'Invite link copied.'**
  String get communityShareInviteCopied;

  /// Notification settings screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsTitle;

  /// Notification settings: messages toggle
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifSettingsMessages;

  /// Notification settings: messages toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'New chat messages in your communities and events'**
  String get notifSettingsMessagesSubtitle;

  /// Notification settings: applications toggle
  ///
  /// In en, this message translates to:
  /// **'New applications'**
  String get notifSettingsApplications;

  /// Notification settings: applications subtitle
  ///
  /// In en, this message translates to:
  /// **'When someone applies to your Kolab'**
  String get notifSettingsApplicationsSubtitle;

  /// Notification settings: collaboration updates toggle
  ///
  /// In en, this message translates to:
  /// **'Collaboration updates'**
  String get notifSettingsCollaborations;

  /// Notification settings: collaboration updates subtitle
  ///
  /// In en, this message translates to:
  /// **'Status changes on your Kolabs'**
  String get notifSettingsCollaborationsSubtitle;

  /// Notification settings: marketing toggle
  ///
  /// In en, this message translates to:
  /// **'Tips & updates'**
  String get notifSettingsMarketing;

  /// Notification settings: marketing subtitle
  ///
  /// In en, this message translates to:
  /// **'Occasional product tips and news'**
  String get notifSettingsMarketingSubtitle;

  /// Notification settings: save failure message
  ///
  /// In en, this message translates to:
  /// **'Could not save your preference. Try again.'**
  String get notifSettingsSaveError;

  /// Chat inbox screen app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// Tooltip on the app-bar chat inbox icon.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatInboxTooltip;

  /// Fallback title for a chat thread with no name or participants.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatThreadFallbackTitle;

  /// Fallback label above an incoming chat bubble when the sender's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get chatSenderFallback;

  /// Subtitle for a chat thread that has messages.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get chatThreadTapToOpen;

  /// Subtitle for a chat thread with no messages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatThreadNoMessagesYet;

  /// Empty state title on the chat inbox.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatInboxEmptyTitle;

  /// Empty state body on the chat inbox.
  ///
  /// In en, this message translates to:
  /// **'Conversations show up here once a Kolab, community, or event chat gets going.'**
  String get chatInboxEmptyBody;

  /// Chat inbox section label for the community main chat.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get chatSectionMain;

  /// Chat inbox section label for custom community chats.
  ///
  /// In en, this message translates to:
  /// **'Community chats'**
  String get chatSectionCommunityChats;

  /// Chat inbox section label for event chats.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get chatSectionEvents;

  /// Chat inbox section label for collaboration (Kolab) chats.
  ///
  /// In en, this message translates to:
  /// **'Kolabs'**
  String get chatSectionKolabs;

  /// Hint text in the chat message composer field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatComposerHint;

  /// Empty state inside an open chat thread with no messages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi 👋'**
  String get chatThreadEmptyMessage;

  /// Title of the create-chat dialog in the Chats tab.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatManageNewChatTitle;

  /// Title of the rename-chat dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get chatManageRenameTitle;

  /// Label for the chat name field.
  ///
  /// In en, this message translates to:
  /// **'Chat name'**
  String get chatManageNameLabel;

  /// Hint for the chat name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Exec, Socials, Philanthropy'**
  String get chatManageNameHint;

  /// Create button in the new-chat dialog.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get chatManageCreate;

  /// Rename action label.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get chatManageRename;

  /// Delete action label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatManageDelete;

  /// Label on the create-chat button in the Chats tab.
  ///
  /// In en, this message translates to:
  /// **'Create chat'**
  String get chatManageCreateChat;

  /// Snackbar after a chat is created.
  ///
  /// In en, this message translates to:
  /// **'Created \"{name}\"'**
  String chatManageChatCreated(String name);

  /// Snackbar after a chat is renamed.
  ///
  /// In en, this message translates to:
  /// **'Chat renamed'**
  String get chatManageChatRenamed;

  /// Snackbar after a chat is deleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatManageChatDeleted;

  /// Snackbar when the custom chat cap is reached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of {count} custom chats.'**
  String chatManageChatLimit(int count);

  /// Confirm dialog title for deleting a chat.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get chatManageDeleteTitle;

  /// Confirm dialog body for deleting a chat (notes it is recoverable).
  ///
  /// In en, this message translates to:
  /// **'Members will lose access to \"{name}\". You can recover it later if you change your mind.'**
  String chatManageDeleteBody(String name);

  /// Title of the community picker shown before creating a chat when the viewer manages more than one community.
  ///
  /// In en, this message translates to:
  /// **'Which community?'**
  String get chatManageWhichCommunity;

  /// Section label for open chats the viewer can join.
  ///
  /// In en, this message translates to:
  /// **'Chats you can join'**
  String get chatJoinSectionTitle;

  /// Join button label for an open chat.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get chatJoinAction;

  /// Snackbar after joining an open chat.
  ///
  /// In en, this message translates to:
  /// **'You joined \"{name}\"'**
  String chatJoinedSnack(String name);

  /// Tooltip on the info icon in an event chat header that opens the event detail.
  ///
  /// In en, this message translates to:
  /// **'Open event'**
  String get chatThreadOpenEvent;

  /// Title of the thread members / participants sheet.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get chatMembersTitle;

  /// Empty state in the members sheet.
  ///
  /// In en, this message translates to:
  /// **'No members to manage yet.'**
  String get chatMembersEmpty;

  /// Remove (ban) action label for a member.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatMemberRemove;

  /// Confirm dialog title for banning a member.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String chatMemberRemoveTitle(String name);

  /// Confirm dialog body for banning a member.
  ///
  /// In en, this message translates to:
  /// **'They\'ll lose access to this chat and won\'t be able to rejoin.'**
  String get chatMemberRemoveBody;

  /// Snackbar after a member is banned.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed'**
  String chatMemberRemoved(String name);

  /// Tooltip on the manage-members icon in the thread header.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get chatThreadManageMembers;

  /// Community detail tab: chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get communityDetailTabChats;

  /// Community detail tab: events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get communityDetailTabEvents;

  /// Community detail tab: members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityDetailTabMembers;

  /// Community detail tab: details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get communityDetailTabDetails;

  /// Community header subtitle: community type and member count.
  ///
  /// In en, this message translates to:
  /// **'{type} · {count} members'**
  String communityDetailTypeAndMembers(String type, int count);

  /// Member count label.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String communityDetailMembersCount(int count);

  /// Title shown when the community chats fail to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats'**
  String get communityDetailChatsLoadError;

  /// Empty state title for the community chats tab.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get communityDetailNoChatsTitle;

  /// Empty state body for the community chats tab.
  ///
  /// In en, this message translates to:
  /// **'This community’s conversations show up here.'**
  String get communityDetailNoChatsBody;

  /// Empty state title for the community events tab.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get communityDetailNoEventsTitle;

  /// Empty state body for the community events tab.
  ///
  /// In en, this message translates to:
  /// **'Events created for this community will show here.'**
  String get communityDetailNoEventsBody;

  /// Subtitle shown on an event a member's tier cannot access.
  ///
  /// In en, this message translates to:
  /// **'Locked — for another membership tier'**
  String get communityDetailEventLockedSubtitle;

  /// Snackbar shown when tapping a tier-locked event.
  ///
  /// In en, this message translates to:
  /// **'This event is for a different membership tier.'**
  String get communityDetailEventLockedSnack;

  /// Button opening the chapter (community-scoped) leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Chapter leaderboard'**
  String get communityDetailLeaderboardButton;

  /// Section label for the community description.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get communityDetailAboutLabel;

  /// Section label for the member's own membership details.
  ///
  /// In en, this message translates to:
  /// **'Your membership'**
  String get communityDetailMembershipLabel;

  /// Row label: the member's tier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get communityDetailRowTier;

  /// Row label: the community type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get communityDetailRowType;

  /// Row label: member count.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityDetailRowMembers;

  /// Row label: the member's role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get communityDetailRowRole;

  /// Role value shown when the member can manage the community.
  ///
  /// In en, this message translates to:
  /// **'Can manage'**
  String get communityDetailRoleCanManage;

  /// Fallback tier name when a member has no assigned tier.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get communityDetailTierFallback;

  /// Section label for the gallery and past events.
  ///
  /// In en, this message translates to:
  /// **'Gallery & past events'**
  String get communityDetailGalleryLabel;

  /// Placeholder body for the gallery section.
  ///
  /// In en, this message translates to:
  /// **'Photos and past events will live here once the events lifecycle ships (Phase 3).'**
  String get communityDetailGalleryBody;

  /// Empty state for the gallery and past events section when the community has no past events.
  ///
  /// In en, this message translates to:
  /// **'No past events to show yet.'**
  String get communityDetailGalleryEmpty;

  /// Shown on a membership card when the member has no tier.
  ///
  /// In en, this message translates to:
  /// **'No tier yet'**
  String get myCommunitiesNoTier;

  /// Badge shown when the member can manage the community.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get myCommunitiesAdminBadge;

  /// Empty state title for the member's communities list.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in any communities yet'**
  String get myCommunitiesEmptyTitle;

  /// Empty state body for the member's communities list.
  ///
  /// In en, this message translates to:
  /// **'Join a community to earn your place on its tiers and see member-only events and perks.'**
  String get myCommunitiesEmptyBody;

  /// Empty state title on the community leader hub.
  ///
  /// In en, this message translates to:
  /// **'Start your community'**
  String get communityHubEmptyTitle;

  /// Empty state body on the community leader hub.
  ///
  /// In en, this message translates to:
  /// **'Create a community to build a member roster and set up your own tiers. Your first community is free.'**
  String get communityHubEmptyBody;

  /// Button to create a community.
  ///
  /// In en, this message translates to:
  /// **'CREATE COMMUNITY'**
  String get communityHubCreateCommunity;

  /// Section label: tiers.
  ///
  /// In en, this message translates to:
  /// **'Tiers'**
  String get communityHubSectionTiers;

  /// Section label: members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityHubSectionMembers;

  /// Section label: events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get communityHubSectionEvents;

  /// Section label: chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get communityHubSectionChats;

  /// Hub header subtitle with type and member count.
  ///
  /// In en, this message translates to:
  /// **'{type}  ·  {count} members'**
  String communityHubTypeAndMembers(String type, int count);

  /// Empty state for the hub events section.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events yet.'**
  String get communityHubNoEvents;

  /// Button to create an event.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get communityHubCreateEvent;

  /// Dialog title to create a new community chat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get communityHubNewChatTitle;

  /// Label for the chat name field.
  ///
  /// In en, this message translates to:
  /// **'Chat name'**
  String get communityHubChatNameLabel;

  /// Hint for the chat name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Exec, Socials, Philanthropy'**
  String get communityHubChatNameHint;

  /// Generic create action in the community hub.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get communityHubCreate;

  /// Confirmation after creating a custom chat.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" created'**
  String communityHubChatCreated(String name);

  /// Error when the custom chat limit is reached.
  ///
  /// In en, this message translates to:
  /// **'You can have up to {count} chats'**
  String communityHubChatLimit(int count);

  /// Default label on the per-chat access picker.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get communityHubAccess;

  /// No description provided for @chatManageAccess.
  ///
  /// In en, this message translates to:
  /// **'Who can access'**
  String get chatManageAccess;

  /// No description provided for @chatManageMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get chatManageMembers;

  /// No description provided for @chatBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlock;

  /// No description provided for @chatUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatUnblock;

  /// No description provided for @chatBlockedTag.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get chatBlockedTag;

  /// No description provided for @chatRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Chat name'**
  String get chatRenameHint;

  /// No description provided for @chatRenamed.
  ///
  /// In en, this message translates to:
  /// **'Chat renamed'**
  String get chatRenamed;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All messages in \"{name}\" will be removed.'**
  String chatDeleteBody(String name);

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeleted;

  /// Access label when no tier can open the chat.
  ///
  /// In en, this message translates to:
  /// **'No tiers'**
  String get communityHubAccessNoTiers;

  /// Access label when every tier can open the chat.
  ///
  /// In en, this message translates to:
  /// **'All tiers'**
  String get communityHubAccessAllTiers;

  /// Access label when one tier can open the chat.
  ///
  /// In en, this message translates to:
  /// **'1 tier'**
  String get communityHubAccessOneTier;

  /// Access label for how many tiers can open the chat.
  ///
  /// In en, this message translates to:
  /// **'{count} tiers'**
  String communityHubAccessTierCount(int count);

  /// Snackbar shown when managing chat access with no tiers.
  ///
  /// In en, this message translates to:
  /// **'Create membership tiers first to gate chats.'**
  String get communityHubCreateTiersFirst;

  /// Title of the chat access dialog.
  ///
  /// In en, this message translates to:
  /// **'Who can access \"{name}\"?'**
  String communityHubAccessDialogTitle(String name);

  /// Fallback noun for an unnamed chat in the access dialog title.
  ///
  /// In en, this message translates to:
  /// **'chat'**
  String get communityHubAccessDialogChat;

  /// Explanatory body of the chat access dialog.
  ///
  /// In en, this message translates to:
  /// **'You and your managers always have access. Choose which member tiers can open this chat.'**
  String get communityHubAccessDialogBody;

  /// Confirmation after updating chat access.
  ///
  /// In en, this message translates to:
  /// **'Chat access updated'**
  String get communityHubChatAccessUpdated;

  /// Hint shown when a community has no chats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet. Your main chat + up to {count} custom chats live here.'**
  String communityHubNoChatsHint(int count);

  /// Button to create a custom chat.
  ///
  /// In en, this message translates to:
  /// **'Create chat'**
  String get communityHubCreateChat;

  /// Hint shown when the custom chat limit is reached.
  ///
  /// In en, this message translates to:
  /// **'Chat limit reached ({count} custom chats).'**
  String communityHubChatLimitReached(int count);

  /// Fallback name for the main community chat.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get communityHubChatMain;

  /// Fallback name for a community chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get communityHubChatFallback;

  /// Chip on the main community chat row.
  ///
  /// In en, this message translates to:
  /// **'MAIN'**
  String get communityHubChipMain;

  /// Tier detail line: assignment rule plus threshold and unit.
  ///
  /// In en, this message translates to:
  /// **'{rule} · {threshold} {unit}'**
  String communityHubTierDetail(String rule, int threshold, String unit);

  /// Chip on the default tier.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get communityHubChipDefault;

  /// Tier rank indicator.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String communityHubTierRank(int rank);

  /// Hint shown when a community has no tiers.
  ///
  /// In en, this message translates to:
  /// **'No tiers yet. Add tiers to give members a status ladder.'**
  String get communityHubNoTiersHint;

  /// Button to add a tier.
  ///
  /// In en, this message translates to:
  /// **'Add tier'**
  String get communityHubAddTier;

  /// Hint shown when a community has no members.
  ///
  /// In en, this message translates to:
  /// **'No members yet. Invite people or share your join link.'**
  String get communityHubNoMembersHint;

  /// Button to open the roster.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get communityHubManageMembers;

  /// Button to open the full roster, with the total member count.
  ///
  /// In en, this message translates to:
  /// **'Manage all {count} members'**
  String communityHubManageAllMembers(int count);

  /// Fallback name for a member without a display name.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get communityHubMemberFallback;

  /// Chip shown next to a member who can manage.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get communityHubChipAdmin;

  /// Error title when the community fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your community'**
  String get communityHubLoadError;

  /// Title of the Community Premium upsell dialog.
  ///
  /// In en, this message translates to:
  /// **'Community Premium'**
  String get createCommunityPremiumTitle;

  /// Body of the Community Premium upsell dialog.
  ///
  /// In en, this message translates to:
  /// **'Your free plan includes one community. Running more than one is part of Community Premium — coming soon.'**
  String get createCommunityPremiumBody;

  /// Create-community screen app-bar title.
  ///
  /// In en, this message translates to:
  /// **'New community'**
  String get createCommunityTitle;

  /// Label for the community name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get createCommunityNameLabel;

  /// Hint for the community name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kappa Delta — Beta Chi, or City Run Club'**
  String get createCommunityNameHint;

  /// Validation error for an empty community name.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get createCommunityNameRequired;

  /// Label for the community type field.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get createCommunityTypeLabel;

  /// Label for the join-policy selector.
  ///
  /// In en, this message translates to:
  /// **'Who can join'**
  String get createCommunityWhoCanJoin;

  /// Join policy option: open to anyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get createCommunityJoinAnyone;

  /// Join policy option: invite only.
  ///
  /// In en, this message translates to:
  /// **'Invite only'**
  String get createCommunityJoinInviteOnly;

  /// Submit button to create the community.
  ///
  /// In en, this message translates to:
  /// **'CREATE COMMUNITY'**
  String get createCommunitySubmit;

  /// App-bar title when editing a tier.
  ///
  /// In en, this message translates to:
  /// **'Edit tier'**
  String get tierEditorEditTitle;

  /// App-bar title when creating a tier.
  ///
  /// In en, this message translates to:
  /// **'New tier'**
  String get tierEditorNewTitle;

  /// Tooltip on the delete-tier icon.
  ///
  /// In en, this message translates to:
  /// **'Delete tier'**
  String get tierEditorDeleteTooltip;

  /// Title of the delete-tier confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete tier?'**
  String get tierEditorDeleteTitle;

  /// Body of the delete-tier confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? Members in it will need reassigning.'**
  String tierEditorDeleteBody(String name);

  /// Delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tierEditorDelete;

  /// Label for the tier name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tierEditorNameLabel;

  /// Hint for the tier name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Exec, Active, Captain, Coach'**
  String get tierEditorNameHint;

  /// Validation error for an empty tier name.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get tierEditorNameRequired;

  /// Label for the tier rank field.
  ///
  /// In en, this message translates to:
  /// **'Rank (higher = more senior)'**
  String get tierEditorRankLabel;

  /// Validation error for the tier rank field.
  ///
  /// In en, this message translates to:
  /// **'Enter a number (1 or higher)'**
  String get tierEditorRankRequired;

  /// Label for the tier colour picker.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get tierEditorColourLabel;

  /// Label for the tier assignment-rule selector.
  ///
  /// In en, this message translates to:
  /// **'How members get this tier'**
  String get tierEditorRuleLabel;

  /// Label for the tier threshold field.
  ///
  /// In en, this message translates to:
  /// **'Threshold ({unit})'**
  String tierEditorThresholdLabel(String unit);

  /// Validation error for the tier threshold field.
  ///
  /// In en, this message translates to:
  /// **'Enter a {unit} threshold'**
  String tierEditorThresholdRequired(String unit);

  /// Save button when editing a tier.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get tierEditorSave;

  /// Create button when adding a tier.
  ///
  /// In en, this message translates to:
  /// **'CREATE TIER'**
  String get tierEditorCreate;

  /// Roster screen app-bar title.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get rosterTitle;

  /// Tooltip on the invite-member icon.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get rosterInviteTooltip;

  /// Title of the invite-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get rosterInviteTitle;

  /// Body of the invite-member dialog.
  ///
  /// In en, this message translates to:
  /// **'Add a member by the email on their Kolabing account.'**
  String get rosterInviteBody;

  /// Label for the invite email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get rosterInviteEmailLabel;

  /// Hint for the invite email field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get rosterInviteEmailHint;

  /// Invite action.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get rosterInvite;

  /// Error for an invalid invite email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get rosterInviteInvalidEmail;

  /// Confirmation after adding a member.
  ///
  /// In en, this message translates to:
  /// **'Member added'**
  String get rosterMemberAdded;

  /// Error when no account matches the invited email.
  ///
  /// In en, this message translates to:
  /// **'No Kolabing account found for that email'**
  String get rosterNoAccountForEmail;

  /// Fallback name for a member without a display name.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get rosterMemberFallback;

  /// No description provided for @rosterViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get rosterViewProfile;

  /// Empty state title for the roster.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get rosterEmptyTitle;

  /// Empty state button to invite a member.
  ///
  /// In en, this message translates to:
  /// **'Invite a member'**
  String get rosterInviteMember;

  /// Title of the remove-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get rosterRemoveTitle;

  /// Body of the remove-member confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the community?'**
  String rosterRemoveBody(String name);

  /// Fallback noun for a member without a name in the remove dialog.
  ///
  /// In en, this message translates to:
  /// **'this member'**
  String get rosterRemoveBodyFallback;

  /// Remove action.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get rosterRemove;

  /// Label for the member tier selector.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get rosterTierLabel;

  /// Dropdown option for no tier.
  ///
  /// In en, this message translates to:
  /// **'No tier'**
  String get rosterNoTier;

  /// Title for the can-manage toggle.
  ///
  /// In en, this message translates to:
  /// **'Can manage this community'**
  String get rosterCanManageTitle;

  /// Subtitle for the can-manage toggle.
  ///
  /// In en, this message translates to:
  /// **'Admin capability — independent of tier'**
  String get rosterCanManageSubtitle;

  /// Label for the membership status selector.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get rosterStatusLabel;

  /// Save button in the member edit sheet.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get rosterSave;

  /// Title of the friends list screen / friends section.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// Title of the incoming friend requests section.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendRequestsTitle;

  /// CTA to send a friend request.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendAdd;

  /// Label when an outgoing friend request is awaiting response (tap to cancel).
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get friendPending;

  /// Accept an incoming friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendAccept;

  /// Decline an incoming friend request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendDecline;

  /// Label when the viewer is already friends (tap to remove).
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendFriends;

  /// Confirmation title before removing a friend.
  ///
  /// In en, this message translates to:
  /// **'Remove this friend?'**
  String get friendRemoveTitle;

  /// Confirm button to remove a friend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendRemoveConfirm;

  /// Generic error when a friend action fails.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get friendActionFailed;

  /// Empty state for the friends list.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmpty;

  /// Error state for the friends list.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load friends'**
  String get friendsLoadError;

  /// Fallback name for a friend without a name.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get friendUnknownName;

  /// Friends count label, singular.
  ///
  /// In en, this message translates to:
  /// **'1 friend'**
  String get friendCountOne;

  /// Friends count label, plural.
  ///
  /// In en, this message translates to:
  /// **'{count} friends'**
  String friendCountOther(int count);

  /// App bar title for the community discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Discover communities'**
  String get discoverCommunitiesTitle;

  /// Call to action to open the community discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Discover communities'**
  String get discoverCommunitiesCta;

  /// Button to join a community from a discovery card.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get discoverCommunitiesJoin;

  /// Label shown on a community card after the user has joined it.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get discoverCommunitiesJoined;

  /// Snackbar confirming the user joined a community.
  ///
  /// In en, this message translates to:
  /// **'You joined {name}'**
  String discoverCommunitiesJoinedToast(String name);

  /// Badge/message shown when a community is invite-only and cannot be self-joined.
  ///
  /// In en, this message translates to:
  /// **'Invite only'**
  String get discoverCommunitiesInviteOnly;

  /// Snackbar shown when trying to join an invite-only community.
  ///
  /// In en, this message translates to:
  /// **'{name} is invite only. Ask a member to add you.'**
  String discoverCommunitiesInviteOnlyMessage(String name);

  /// Snackbar shown when joining a community fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join right now. Please try again.'**
  String get discoverCommunitiesJoinError;

  /// Member count label on a discovery card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String discoverCommunitiesMembers(int count);

  /// Empty/coming-soon title on the community discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Nothing to discover yet'**
  String get discoverCommunitiesEmptyTitle;

  /// Empty/coming-soon body on the community discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Community discovery is coming soon. Check back to find and join communities near you.'**
  String get discoverCommunitiesEmptyBody;

  /// Error state on the community discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load communities. Please try again.'**
  String get discoverCommunitiesError;

  /// Generic Skip button label.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// Placeholder text inside the @handle input.
  ///
  /// In en, this message translates to:
  /// **'yourhandle'**
  String get handleFieldPlaceholder;

  /// Format hint shown under the handle field.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters: lowercase letters, numbers, underscores.'**
  String get handleFieldHint;

  /// Shown when the entered handle is malformed.
  ///
  /// In en, this message translates to:
  /// **'Use 3-20 lowercase letters, numbers or underscores.'**
  String get handleFieldFormatError;

  /// Shown while the handle availability check is running.
  ///
  /// In en, this message translates to:
  /// **'Checking availability…'**
  String get handleFieldChecking;

  /// Shown when the handle is available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get handleFieldAvailable;

  /// Shown when the handle is already in use.
  ///
  /// In en, this message translates to:
  /// **'That handle is taken.'**
  String get handleFieldTaken;

  /// Shown when the handle is taken, offering a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Taken. Try @{suggestion}'**
  String handleFieldTakenWithSuggestion(String suggestion);

  /// Shown when the handle equals the user's existing handle.
  ///
  /// In en, this message translates to:
  /// **'This is your current handle.'**
  String get handleFieldYours;

  /// Step counter in the attendee onboarding header.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String attendeeOnboardingStepCounter(int step, int total);

  /// Attendee onboarding step 1 title (You).
  ///
  /// In en, this message translates to:
  /// **'Let\'s set you up'**
  String get attendeeOnboardingStep1Title;

  /// Attendee onboarding step 1 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name, pick a handle, and a photo if you like.'**
  String get attendeeOnboardingStep1Subtitle;

  /// No description provided for @attendeeOnboardingAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get attendeeOnboardingAddPhoto;

  /// Label for the attendee name field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get attendeeOnboardingNameLabel;

  /// Hint for the attendee name field.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get attendeeOnboardingNameHint;

  /// Label for the attendee @handle field.
  ///
  /// In en, this message translates to:
  /// **'Your handle'**
  String get attendeeOnboardingHandleLabel;

  /// Attendee onboarding step 2 title (City).
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get attendeeOnboardingStep2Title;

  /// Attendee onboarding step 2 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your city to discover communities near you.'**
  String get attendeeOnboardingStep2Subtitle;

  /// Attendee onboarding step 3 title (Interests).
  ///
  /// In en, this message translates to:
  /// **'What are you into?'**
  String get attendeeOnboardingStep3Title;

  /// Attendee onboarding step 3 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a few interests so we can suggest the right communities.'**
  String get attendeeOnboardingStep3Subtitle;

  /// Attendee onboarding step 4 title (Join).
  ///
  /// In en, this message translates to:
  /// **'Join your first communities'**
  String get attendeeOnboardingStep4Title;

  /// Attendee onboarding step 4 subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to join the ones you like. You can always join more later.'**
  String get attendeeOnboardingStep4Subtitle;

  /// Finish button on the last attendee onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get attendeeOnboardingFinish;

  /// Badge marking a community that matches the attendee's interests.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get attendeeOnboardingForYou;

  /// Label for the @handle field in Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get editProfileHandleLabel;

  /// Title of the add-friend-by-identifier screen.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addFriendTitle;

  /// Subtitle on the add-friend screen.
  ///
  /// In en, this message translates to:
  /// **'Find someone by their email or @handle.'**
  String get addFriendSubtitle;

  /// Hint for the add-friend search input.
  ///
  /// In en, this message translates to:
  /// **'Email or @handle'**
  String get addFriendInputHint;

  /// Search button on the add-friend screen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get addFriendSearch;

  /// Shown when the lookup returns no match.
  ///
  /// In en, this message translates to:
  /// **'No one matches that email or handle.'**
  String get addFriendNoMatch;

  /// Shown when the lookup endpoint is not deployed (self-gated).
  ///
  /// In en, this message translates to:
  /// **'Adding friends isn\'t available right now.'**
  String get addFriendUnavailable;

  /// Generic error on the add-friend screen.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get addFriendError;

  /// CTA state when the matched profile is the viewer.
  ///
  /// In en, this message translates to:
  /// **'That\'s you'**
  String get addFriendSelf;

  /// Label for the roster invite identifier field.
  ///
  /// In en, this message translates to:
  /// **'Email or @handle'**
  String get rosterInviteIdentifierLabel;

  /// Hint for the roster invite identifier field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or @handle'**
  String get rosterInviteIdentifierHint;

  /// Validation error for the roster invite identifier.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email or @handle.'**
  String get rosterInviteInvalidIdentifier;

  /// Shown when the invited identifier matches no account.
  ///
  /// In en, this message translates to:
  /// **'No Kolabing account matches that email or handle.'**
  String get rosterNoAccountForIdentifier;

  /// Attendee home events section header.
  ///
  /// In en, this message translates to:
  /// **'EVENTS'**
  String get attendeeHomeEventsTitle;

  /// City picker button label when no city is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose city'**
  String get attendeeHomeChooseCity;

  /// Events filter chip: show only today's events.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get attendeeHomeFilterToday;

  /// Date-range dropdown chip / sheet title for the events feed.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get attendeeHomeFilterDate;

  /// Events date filter chip: all future events (default).
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get attendeeHomeFilterUpcoming;

  /// Events date filter chip: events within the current week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get attendeeHomeFilterThisWeek;

  /// Events date filter chip: events this weekend (Sat-Sun).
  ///
  /// In en, this message translates to:
  /// **'This weekend'**
  String get attendeeHomeFilterThisWeekend;

  /// Events date filter chip: events within the current calendar month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get attendeeHomeFilterThisMonth;

  /// Events filter chip / sheet title: filter by community type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get attendeeHomeFilterType;

  /// Type filter option that clears the community-type filter.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get attendeeHomeFilterTypeAll;

  /// Persistent CTA on the attendee home that opens community discovery.
  ///
  /// In en, this message translates to:
  /// **'Explore communities'**
  String get attendeeHomeExploreCommunities;

  /// Empty-state title when no city is selected for events.
  ///
  /// In en, this message translates to:
  /// **'Pick a city'**
  String get attendeeHomePickCityTitle;

  /// Empty-state hint inviting the user to pick a city.
  ///
  /// In en, this message translates to:
  /// **'Choose a city to discover events near you.'**
  String get attendeeHomePickCityHint;

  /// Empty-state title when a city has no events for the current filters.
  ///
  /// In en, this message translates to:
  /// **'No events in this city'**
  String get attendeeHomeNoEventsCity;

  /// Empty-state hint when no events match in the selected city.
  ///
  /// In en, this message translates to:
  /// **'Try another city or clear your filters.'**
  String get attendeeHomeNoEventsCityHint;

  /// Event card badge for a business-hosted event.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get eventPartnerBusiness;

  /// Event card badge for a community-hosted event.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get eventPartnerCommunity;

  /// Event card relative date: today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventDateToday;

  /// Event card relative date: tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get eventDateTomorrow;

  /// Event card relative date: N days away.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String eventDateInDays(int days);

  /// Error title on the attendee community profile screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load community'**
  String get attendeeCommunityProfileErrorTitle;

  /// Fallback label when a community's type slug can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get attendeeCommunityProfileTypeFallback;

  /// Member count under the community header.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members yet} one{{count} member} other{{count} members}}'**
  String attendeeCommunityProfileMemberCount(int count);

  /// About section title on the attendee community profile.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get attendeeCommunityProfileAboutTitle;

  /// Upcoming events section title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get attendeeCommunityProfileUpcomingEventsTitle;

  /// Action that opens the community detail on its Events tab.
  ///
  /// In en, this message translates to:
  /// **'See all →'**
  String get attendeeCommunityProfileSeeAll;

  /// Empty state for the upcoming events section.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events yet.'**
  String get attendeeCommunityProfileNoUpcomingEvents;

  /// CTA to join an open community.
  ///
  /// In en, this message translates to:
  /// **'Join community'**
  String get attendeeCommunityProfileJoin;

  /// Snackbar after a successful join.
  ///
  /// In en, this message translates to:
  /// **'Joined ✓'**
  String get attendeeCommunityProfileJoinedSnack;

  /// CTA to request joining an invite-only community.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get attendeeCommunityProfileRequestToJoin;

  /// Disabled CTA label when a join request is pending.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get attendeeCommunityProfileRequested;

  /// Snackbar after a join request is sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get attendeeCommunityProfileRequestedSnack;

  /// Notice when the join-request endpoint isn't deployed yet.
  ///
  /// In en, this message translates to:
  /// **'Requests aren\'t available yet. Try again later.'**
  String get attendeeCommunityProfileRequestUnavailable;

  /// CTA for an existing member to open the community detail.
  ///
  /// In en, this message translates to:
  /// **'Open community'**
  String get attendeeCommunityProfileOpenCommunity;

  /// Community detail tab: Rewards (goals, rewards, badges).
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get communityDetailTabRewards;

  /// Header action that opens the chat screen for this community.
  ///
  /// In en, this message translates to:
  /// **'Chats →'**
  String get communityDetailChatsAction;

  /// Action that opens the tier editor from the Members tab.
  ///
  /// In en, this message translates to:
  /// **'Tiers'**
  String get communityDetailTiersAction;

  /// Section header for members without an assigned tier.
  ///
  /// In en, this message translates to:
  /// **'No tier'**
  String get communityMembersGroupNoTier;

  /// Member count next to a tier section header.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No members} one{{count} member} other{{count} members}}'**
  String communityMembersTierCount(int count);

  /// Marker on the viewer's own roster row in member view.
  ///
  /// In en, this message translates to:
  /// **'★ You'**
  String get communityMembersYou;

  /// Points shown on a member row.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{points} pt} other{{points} pts}}'**
  String communityMembersPoints(int points);

  /// Empty state title for the Members tab.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get communityMembersEmptyTitle;

  /// Empty state body for the Members tab.
  ///
  /// In en, this message translates to:
  /// **'Members appear here once people join this community.'**
  String get communityMembersEmptyBody;

  /// Error title for the Members tab.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get communityMembersLoadError;

  /// App bar title of the Personal Rewards Screen.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get personalRewardsTitle;

  /// Title of the global XP redemption card.
  ///
  /// In en, this message translates to:
  /// **'Redeem your XP'**
  String get personalRewardsRedeemXpTitle;

  /// Unit label shown after the XP balance.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get personalRewardsXpUnit;

  /// Disabled CTA label on the Redeem your XP card (partner rewards not redeemable yet).
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get personalRewardsComingSoon;

  /// XP cost of a partner reward.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{points} XP} other{{points} XP}}'**
  String personalRewardsXpCost(int points);

  /// The viewer's per-community points balance shown in a community section header.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{points} pt} other{{points} pts}}'**
  String personalRewardsMyPoints(int points);

  /// Empty state for a community with no rewards.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet.'**
  String get personalRewardsNoRewards;

  /// Title of the empty state when the viewer has no community reward sections.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet'**
  String get personalRewardsEmptyTitle;

  /// Body of the empty state on the Personal Rewards Screen.
  ///
  /// In en, this message translates to:
  /// **'Join communities and earn points to unlock rewards.'**
  String get personalRewardsEmptyBody;

  /// Error title on the Personal Rewards Screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load rewards'**
  String get personalRewardsFailedToLoad;

  /// Badge shown on the current user's leaderboard row.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardEntryYou;

  /// Number of badges shown on a leaderboard row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} badge} other{{count} badges}}'**
  String leaderboardEntryBadgeCount(int count);

  /// Title shown when the rewards-hub endpoint isn't available yet.
  ///
  /// In en, this message translates to:
  /// **'Rewards coming soon'**
  String get communityRewardsComingSoonTitle;

  /// Body shown when the rewards-hub endpoint isn't available yet.
  ///
  /// In en, this message translates to:
  /// **'Goals, badges and rewards for this community will appear here.'**
  String get communityRewardsComingSoonBody;

  /// Label on the member points card.
  ///
  /// In en, this message translates to:
  /// **'Your points'**
  String get communityRewardsPointsLabel;

  /// Tier label on the member points card.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get communityRewardsTierLabel;

  /// Shown when the member has no tier yet.
  ///
  /// In en, this message translates to:
  /// **'No tier yet'**
  String get communityRewardsNoTier;

  /// Goals section title.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get communityRewardsGoalsTitle;

  /// Badges section title.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get communityRewardsBadgesTitle;

  /// Rewards section title.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get communityRewardsRewardsTitle;

  /// Reward points a goal grants.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String communityRewardsGoalReward(int points);

  /// Goal progress text.
  ///
  /// In en, this message translates to:
  /// **'{progress} / {target}'**
  String communityRewardsGoalProgress(int progress, int target);

  /// Label on an earned badge.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get communityRewardsBadgeEarned;

  /// Label on a locked badge.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get communityRewardsBadgeLocked;

  /// Button to redeem a reward.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get communityRewardsRedeem;

  /// Cost of a reward in points.
  ///
  /// In en, this message translates to:
  /// **'{points, plural, =1{{points} pt} other{{points} pts}}'**
  String communityRewardsRewardCost(int points);

  /// Remaining stock of a reward.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Out of stock} other{{count} left}}'**
  String communityRewardsRewardStock(int count);

  /// Confirm dialog title before redeeming.
  ///
  /// In en, this message translates to:
  /// **'Redeem reward?'**
  String get communityRewardsRedeemConfirmTitle;

  /// Confirm dialog body before redeeming.
  ///
  /// In en, this message translates to:
  /// **'This will spend {points} points on \"{title}\".'**
  String communityRewardsRedeemConfirmBody(int points, String title);

  /// Snackbar after a successful redemption.
  ///
  /// In en, this message translates to:
  /// **'Redeemed ✓'**
  String get communityRewardsRedeemedSnack;

  /// Empty state for the goals section.
  ///
  /// In en, this message translates to:
  /// **'No goals yet.'**
  String get communityRewardsGoalsEmpty;

  /// Empty state for the badges section.
  ///
  /// In en, this message translates to:
  /// **'No badges yet.'**
  String get communityRewardsBadgesEmpty;

  /// Empty state for the rewards section.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet.'**
  String get communityRewardsRewardsEmpty;

  /// Leader action to add a goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get communityRewardsAddGoal;

  /// Leader action to add a reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get communityRewardsAddReward;

  /// Leader action to add a badge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get communityRewardsAddBadge;

  /// Title of the goal editor when creating.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get communityGoalEditorNewTitle;

  /// Title of the goal editor when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get communityGoalEditorEditTitle;

  /// Goal title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get communityGoalTitleLabel;

  /// Validation when the goal title is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get communityGoalTitleRequired;

  /// Goal earn-type field label.
  ///
  /// In en, this message translates to:
  /// **'Earn by'**
  String get communityGoalEarnTypeLabel;

  /// Goal earn type: event check-ins.
  ///
  /// In en, this message translates to:
  /// **'Event check-ins'**
  String get communityGoalEarnTypeEventCheckIns;

  /// Goal earn type: challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get communityGoalEarnTypeChallenge;

  /// Goal earn type: days in community.
  ///
  /// In en, this message translates to:
  /// **'Days in community'**
  String get communityGoalEarnTypeDaysInCommunity;

  /// Goal target field label.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get communityGoalTargetLabel;

  /// Validation for the goal target.
  ///
  /// In en, this message translates to:
  /// **'Enter a target greater than 0'**
  String get communityGoalTargetRequired;

  /// Goal reward-points field label.
  ///
  /// In en, this message translates to:
  /// **'Reward points'**
  String get communityGoalRewardPointsLabel;

  /// Validation for the goal reward points.
  ///
  /// In en, this message translates to:
  /// **'Enter reward points'**
  String get communityGoalRewardPointsRequired;

  /// Title of the reward editor when creating.
  ///
  /// In en, this message translates to:
  /// **'New reward'**
  String get communityRewardEditorNewTitle;

  /// Title of the reward editor when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit reward'**
  String get communityRewardEditorEditTitle;

  /// Reward title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get communityRewardTitleLabel;

  /// Validation when the reward title is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get communityRewardTitleRequired;

  /// Reward description field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get communityRewardDescriptionLabel;

  /// Reward cost field label.
  ///
  /// In en, this message translates to:
  /// **'Cost (points)'**
  String get communityRewardCostLabel;

  /// Validation for the reward cost.
  ///
  /// In en, this message translates to:
  /// **'Enter a cost'**
  String get communityRewardCostRequired;

  /// Reward stock field label.
  ///
  /// In en, this message translates to:
  /// **'Stock (leave empty for unlimited)'**
  String get communityRewardStockLabel;

  /// Title of the badge editor when creating.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get communityBadgeEditorNewTitle;

  /// Title of the badge editor when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit badge'**
  String get communityBadgeEditorEditTitle;

  /// Badge title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get communityBadgeTitleLabel;

  /// Validation when the badge title is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get communityBadgeTitleRequired;

  /// Badge criteria-type field label.
  ///
  /// In en, this message translates to:
  /// **'Criteria'**
  String get communityBadgeCriteriaLabel;

  /// Badge criteria: points threshold.
  ///
  /// In en, this message translates to:
  /// **'Points threshold'**
  String get communityBadgeCriteriaPointsThreshold;

  /// Badge criteria: event check-ins.
  ///
  /// In en, this message translates to:
  /// **'Event check-ins'**
  String get communityBadgeCriteriaEventCheckIns;

  /// Badge criteria: days in community.
  ///
  /// In en, this message translates to:
  /// **'Days in community'**
  String get communityBadgeCriteriaDaysInCommunity;

  /// Badge criteria: challenges completed.
  ///
  /// In en, this message translates to:
  /// **'Challenges completed'**
  String get communityBadgeCriteriaChallengesCompleted;

  /// Badge criteria-value field label.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get communityBadgeValueLabel;

  /// Validation for the badge value.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get communityBadgeValueRequired;

  /// Label for the challenge picker on a badge.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get communityBadgeChallengesLabel;

  /// Shown when no challenges can be picked.
  ///
  /// In en, this message translates to:
  /// **'No challenges available yet.'**
  String get communityBadgeChallengesEmpty;

  /// Generic delete confirm title for goals/rewards/badges.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get communityRewardsDeleteTitle;

  /// Generic delete confirm body.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This can\'t be undone.'**
  String communityRewardsDeleteBody(String title);

  /// Toggle option: the leader's own view of events.
  ///
  /// In en, this message translates to:
  /// **'My view'**
  String get communityEventsMyView;

  /// Toggle option: preview events as an attendee sees them.
  ///
  /// In en, this message translates to:
  /// **'Attendee view'**
  String get communityEventsAttendeeView;

  /// Event visibility badge: public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communityEventVisibilityPublic;

  /// Event visibility badge: members only.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get communityEventVisibilityMembers;

  /// Event visibility badge: tier-gated.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get communityEventVisibilityTier;

  /// Business onboarding goal step: title
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get businessGoalTitle;

  /// Business onboarding goal step: subtitle
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor your setup based on what you want to achieve.'**
  String get businessGoalSubtitle;

  /// Business onboarding goal step: venue option title
  ///
  /// In en, this message translates to:
  /// **'Fill my venue'**
  String get businessGoalVenueTitle;

  /// Business onboarding goal step: venue option description
  ///
  /// In en, this message translates to:
  /// **'I have a physical place (bar, gym, shop, studio) and want communities to come.'**
  String get businessGoalVenueDescription;

  /// Business onboarding goal step: product option title
  ///
  /// In en, this message translates to:
  /// **'Promote a product or service'**
  String get businessGoalProductTitle;

  /// Business onboarding goal step: product option description
  ///
  /// In en, this message translates to:
  /// **'I want to reach communities in one or more cities, no physical venue needed.'**
  String get businessGoalProductDescription;

  /// Business product path identity step: title
  ///
  /// In en, this message translates to:
  /// **'Tell us about your brand'**
  String get businessProductIdentityTitle;

  /// Business product path identity step: subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your name, category and logo so communities know who you are.'**
  String get businessProductIdentitySubtitle;

  /// Business product path identity step: validation error
  ///
  /// In en, this message translates to:
  /// **'Please add a name and at least one category.'**
  String get businessProductIdentityIncomplete;

  /// Business product path: brand name field label
  ///
  /// In en, this message translates to:
  /// **'Brand name'**
  String get businessProductNameLabel;

  /// Business product path: brand name field hint
  ///
  /// In en, this message translates to:
  /// **'Your brand or company name'**
  String get businessProductNameHint;

  /// Business product path: category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get businessProductCategoryLabel;

  /// Business product path: category field hint
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3 that best describe you.'**
  String get businessProductCategoryHint;

  /// Business product path: product-type picker label
  ///
  /// In en, this message translates to:
  /// **'Product type'**
  String get businessProductTypeLabel;

  /// Business product path: product-type picker hint
  ///
  /// In en, this message translates to:
  /// **'What kind of product or service is it?'**
  String get businessProductTypeHint;

  /// Business product path cities step: title
  ///
  /// In en, this message translates to:
  /// **'Which cities do you want to reach?'**
  String get businessProductCitiesTitle;

  /// Business product path cities step: subtitle with free limit
  ///
  /// In en, this message translates to:
  /// **'Free plan: up to {limit} cities. Upgrade to Premium for unlimited reach.'**
  String businessProductCitiesSubtitle(int limit);

  /// Business product path cities step: validation error
  ///
  /// In en, this message translates to:
  /// **'Please select at least one city.'**
  String get businessProductCitiesRequired;

  /// Business product path cities step: free limit reached toast
  ///
  /// In en, this message translates to:
  /// **'Free plan covers up to {limit} cities. Upgrade to Premium to add more.'**
  String businessProductCitiesLimitReached(int limit);

  /// Business product path cities step: selection counter
  ///
  /// In en, this message translates to:
  /// **'{selected} of {limit} cities selected'**
  String businessProductCitiesCounter(int selected, int limit);

  /// Business product path about step: title
  ///
  /// In en, this message translates to:
  /// **'Add a few more details'**
  String get businessProductAboutTitle;

  /// Business product path about step: subtitle
  ///
  /// In en, this message translates to:
  /// **'All optional, but they help communities decide to work with you.'**
  String get businessProductAboutSubtitle;

  /// Business product path: offering field label
  ///
  /// In en, this message translates to:
  /// **'What you offer'**
  String get businessProductOfferingLabel;

  /// Business product path: offering field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., 20% off for community members, free samples, giveaway prizes'**
  String get businessProductOfferingHint;

  /// Venue mode label: hosted at the business location
  ///
  /// In en, this message translates to:
  /// **'Business Venue'**
  String get venueModeBusinessVenue;

  /// Venue mode label: hosted at the community location
  ///
  /// In en, this message translates to:
  /// **'Community Venue'**
  String get venueModeCommunityVenue;

  /// Venue mode label: no specific venue yet (online or to be arranged)
  ///
  /// In en, this message translates to:
  /// **'No venue yet'**
  String get venueModeNoVenue;

  /// Business product path: photos field label
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get businessProductPhotosLabel;

  /// Business product path: photos empty-state title (non-venue)
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get businessProductPhotosEmptyTitle;

  /// Business product path: photos empty-state description (non-venue)
  ///
  /// In en, this message translates to:
  /// **'Show what you offer. Upload your own photos, remove what you do not want, and set the final order here.'**
  String get businessProductPhotosEmptyDescription;

  /// Community onboarding step 1: community size helper text
  ///
  /// In en, this message translates to:
  /// **'Roughly how many members are in your community?'**
  String get communityStep1SizeHelper;

  /// Missions screen app-bar title and profile entry label
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missionsTitle;

  /// Mission progress as current over target, e.g. 2/5
  ///
  /// In en, this message translates to:
  /// **'{progress}/{target}'**
  String missionsProgress(int progress, int target);

  /// Short label for points awarded by a mission, shown after the amount (e.g. +50 pts)
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get missionsPointsLabel;

  /// Missions screen empty-state title
  ///
  /// In en, this message translates to:
  /// **'No missions yet'**
  String get missionsEmptyTitle;

  /// Missions screen empty-state message
  ///
  /// In en, this message translates to:
  /// **'Keep using Kolabing and new missions will show up here.'**
  String get missionsEmptyMessage;

  /// Missions screen error-state message
  ///
  /// In en, this message translates to:
  /// **'Could not load your missions'**
  String get missionsLoadError;

  /// Mission category header: onboarding
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get missionsCategoryOnboarding;

  /// Mission category header: attendance
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get missionsCategoryAttendance;

  /// Mission category header: engagement
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get missionsCategoryEngagement;

  /// Mission category header: content
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get missionsCategoryContent;

  /// Mission category header: referral
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get missionsCategoryReferral;

  /// Mission category header: growth
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get missionsCategoryGrowth;

  /// Mission category header: social
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get missionsCategorySocial;

  /// Mission category header: milestone
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get missionsCategoryMilestone;

  /// Mission category header: unknown/other category fallback
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get missionsCategoryOther;

  /// Leading text before the Terms of Service link in the sign-up consent checkbox
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get consentAgreeLead;

  /// Tappable label linking to the Terms of Service page
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get consentTermsLabel;

  /// Conjunction between the Terms of Service and Privacy Policy links
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get consentAgreeConjunction;

  /// Tappable label linking to the Privacy Policy page
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get consentPrivacyLabel;

  /// Title of the blocking re-consent screen shown when the agreement version changed
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our terms'**
  String get reconsentTitle;

  /// Body text of the re-consent screen
  ///
  /// In en, this message translates to:
  /// **'To keep using Kolabing, please review and accept our updated agreements.'**
  String get reconsentBody;

  /// Button that records consent on the re-consent screen
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get reconsentAcceptButton;

  /// Error shown when recording consent fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get reconsentError;

  /// Zero-tolerance EULA notice shown near the Terms consent checkbox on sign-up (App Review Guideline 1.2).
  ///
  /// In en, this message translates to:
  /// **'We have zero tolerance for objectionable content and abusive users.'**
  String get authNoToleranceNotice;

  /// Overflow menu action to report content or a user.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get moderationReport;

  /// Overflow menu action to block a user.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get moderationBlockUser;

  /// Overflow menu action to report a user's profile.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get moderationReportUser;

  /// Overflow menu action to report a Kolab / opportunity.
  ///
  /// In en, this message translates to:
  /// **'Report this Kolab'**
  String get moderationReportKolab;

  /// Per-row action to report a review.
  ///
  /// In en, this message translates to:
  /// **'Report review'**
  String get moderationReportReview;

  /// Title of the report bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get moderationReportSheetTitle;

  /// Subtitle explaining the report sheet.
  ///
  /// In en, this message translates to:
  /// **'Tell us why. Your report is confidential.'**
  String get moderationReportSheetSubtitle;

  /// Report reason: spam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get moderationReasonSpam;

  /// Report reason: harassment or bullying.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get moderationReasonHarassment;

  /// Report reason: inappropriate or objectionable content.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get moderationReasonInappropriate;

  /// Report reason: other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get moderationReasonOther;

  /// Placeholder for the optional note field in the report sheet.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get moderationNoteHint;

  /// Primary button to submit a report.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get moderationSubmitReport;

  /// Snackbar confirming a report was submitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report has been sent.'**
  String get moderationReportSuccess;

  /// Snackbar shown when submitting a report fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your report. Please try again.'**
  String get moderationReportError;

  /// Title of the block confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get moderationBlockConfirmTitle;

  /// Body of the block confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their content and they won\'t be able to reach you. You can unblock them later.'**
  String get moderationBlockConfirmBody;

  /// Confirm button in the block dialog.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get moderationBlockConfirmAction;

  /// Snackbar confirming a user was blocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get moderationBlockSuccess;

  /// Snackbar shown when blocking fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t block this user. Please try again.'**
  String get moderationBlockError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
