import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @secureSignIn.
  ///
  /// In en, this message translates to:
  /// **'Secure sign-in'**
  String get secureSignIn;

  /// No description provided for @fastHandoff.
  ///
  /// In en, this message translates to:
  /// **'Fast handoff'**
  String get fastHandoff;

  /// No description provided for @smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'Smart alerts'**
  String get smartAlerts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your email and password to reconnect with your work.'**
  String get loginSubtitle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @emailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailError;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordError;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordLengthError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacySecurity;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get step1;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use an email and password you will remember. You can add the rest of your information next.'**
  String get signupSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get repeatPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email.'**
  String get verificationSent;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code. Please try again.'**
  String get verificationFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJob;

  /// No description provided for @postJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new task and start hiring quickly.'**
  String get postJobSubtitle;

  /// No description provided for @browseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse jobs'**
  String get browseJobs;

  /// No description provided for @browseJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See fresh openings near your preferred location.'**
  String get browseJobsSubtitle;

  /// No description provided for @trackWork.
  ///
  /// In en, this message translates to:
  /// **'Track work'**
  String get trackWork;

  /// No description provided for @trackWorkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review active applications and current progress.'**
  String get trackWorkSubtitle;

  /// No description provided for @openRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get openRequests;

  /// No description provided for @openRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Respond to worker requests and incoming updates.'**
  String get openRequestsSubtitle;

  /// No description provided for @welcomeBackWithComma.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackWithComma;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard'**
  String get loadingDashboard;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @seeJobs.
  ///
  /// In en, this message translates to:
  /// **'See jobs'**
  String get seeJobs;

  /// No description provided for @latestJobs.
  ///
  /// In en, this message translates to:
  /// **'Latest job openings'**
  String get latestJobs;

  /// No description provided for @latestJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick scan of fresh work requests around you.'**
  String get latestJobsSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @loadingWorkFeed.
  ///
  /// In en, this message translates to:
  /// **'Loading the latest work opportunities for your feed.'**
  String get loadingWorkFeed;

  /// No description provided for @noOpenings.
  ///
  /// In en, this message translates to:
  /// **'No openings yet'**
  String get noOpenings;

  /// No description provided for @noOpeningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New jobs will appear here as soon as providers publish them.'**
  String get noOpeningsSubtitle;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photos;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Workplace gallery'**
  String get gallery;

  /// No description provided for @gallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'These photos were added by the person who posted the job.'**
  String get gallerySubtitle;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No workplace photos were added to this post.'**
  String get noPhotos;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @jobInfo.
  ///
  /// In en, this message translates to:
  /// **'Job information'**
  String get jobInfo;

  /// No description provided for @jobInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the timing, location, budget, and description before responding.'**
  String get jobInfoSubtitle;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get getDirections;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @jobStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobStatusCompleted;

  /// No description provided for @jobStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobStatusInProgress;

  /// No description provided for @jobStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobStatusCancelled;

  /// No description provided for @jobStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get jobStatusOpen;

  /// No description provided for @manageApplications.
  ///
  /// In en, this message translates to:
  /// **'Manage applications'**
  String get manageApplications;

  /// No description provided for @manageApplicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the request list to chat with applicants and accept or reject them.'**
  String get manageApplicationsSubtitle;

  /// No description provided for @reviewApplications.
  ///
  /// In en, this message translates to:
  /// **'Review applications'**
  String get reviewApplications;

  /// No description provided for @respondToJob.
  ///
  /// In en, this message translates to:
  /// **'Respond to this job'**
  String get respondToJob;

  /// No description provided for @respondToJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message the owner or send an application to move forward.'**
  String get respondToJobSubtitle;

  /// No description provided for @messageOwner.
  ///
  /// In en, this message translates to:
  /// **'Message owner'**
  String get messageOwner;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @appAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get appAccepted;

  /// No description provided for @appAcceptedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The owner has accepted your application. Continue the chat for next steps.'**
  String get appAcceptedSubtitle;

  /// No description provided for @appRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get appRejected;

  /// No description provided for @appRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This application was rejected. You can still message the owner if needed.'**
  String get appRejectedSubtitle;

  /// No description provided for @appPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get appPending;

  /// No description provided for @appPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your application is waiting for the owner to review it.'**
  String get appPendingSubtitle;

  /// No description provided for @appNoApplication.
  ///
  /// In en, this message translates to:
  /// **'No application yet'**
  String get appNoApplication;

  /// No description provided for @applyFor.
  ///
  /// In en, this message translates to:
  /// **'Apply for'**
  String get applyFor;

  /// No description provided for @introduceYourself.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself to'**
  String get introduceYourself;

  /// No description provided for @applyHint.
  ///
  /// In en, this message translates to:
  /// **'Tell them why you are a strong fit for this job...'**
  String get applyHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @applyMessageError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message before applying'**
  String get applyMessageError;

  /// No description provided for @applyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply'**
  String get applyFailed;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'This job does not have a location yet.'**
  String get noLocation;

  /// No description provided for @mapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get mapsError;

  /// No description provided for @directionsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open directions'**
  String get directionsError;

  /// No description provided for @opportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get opportunities;

  /// No description provided for @postJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postJobTitle;

  /// No description provided for @jobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitleLabel;

  /// No description provided for @jobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home Cleaning Service'**
  String get jobTitleHint;

  /// No description provided for @jobDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the job requirements...'**
  String get jobDescHint;

  /// No description provided for @workplacePhotos.
  ///
  /// In en, this message translates to:
  /// **'Workplace Photos'**
  String get workplacePhotos;

  /// No description provided for @workplacePhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add up to {max} photos of the workplace so people can inspect before they apply.'**
  String workplacePhotosSubtitle(Object max);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @noPhotosSelected.
  ///
  /// In en, this message translates to:
  /// **'No photos selected yet. They will appear when users open the post.'**
  String get noPhotosSelected;

  /// No description provided for @photosSelected.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} photos selected'**
  String photosSelected(Object count, Object max);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get changeLocation;

  /// No description provided for @locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a point on the map to save the exact location.'**
  String get locationSubtitle;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get endDateOptional;

  /// No description provided for @default24Hours.
  ///
  /// In en, this message translates to:
  /// **'Default: +24 hours'**
  String get default24Hours;

  /// No description provided for @endTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End Time (Optional)'**
  String get endTimeOptional;

  /// No description provided for @expiryNote.
  ///
  /// In en, this message translates to:
  /// **'If not set, this opportunity will expire in 24 hours.'**
  String get expiryNote;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @enterBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter budget'**
  String get enterBudget;

  /// No description provided for @postJobButton.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJobButton;

  /// No description provided for @errorSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get errorSelectDate;

  /// No description provided for @errorSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get errorSelectTime;

  /// No description provided for @errorSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please pick the exact job location on the map'**
  String get errorSelectLocation;

  /// No description provided for @errorSelectbothEnd.
  ///
  /// In en, this message translates to:
  /// **'Please select both end date and end time'**
  String get errorSelectbothEnd;

  /// No description provided for @errorFutureEnd.
  ///
  /// In en, this message translates to:
  /// **'End date and time must be in the future'**
  String get errorFutureEnd;

  /// No description provided for @jobPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posted successfully!'**
  String get jobPostedSuccess;

  /// No description provided for @jobPostedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to post job'**
  String get jobPostedFailed;

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get pleaseEnter;

  /// No description provided for @noNewPhotos.
  ///
  /// In en, this message translates to:
  /// **'No new photos were added.'**
  String get noNewPhotos;

  /// No description provided for @addedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Added {count} photos. {skipped} were skipped because of duplicates or the {max}-photo limit.'**
  String addedPhotos(Object count, Object max, Object skipped);

  /// No description provided for @photoPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Please grant photo access to add workplace photos.'**
  String get photoPermissionError;

  /// No description provided for @maxPhotosError.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to {max} photos per post.'**
  String maxPhotosError(Object max);

  /// No description provided for @errorPickingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Error picking job photos'**
  String get errorPickingPhotos;

  /// No description provided for @googleSignInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in successful'**
  String get googleSignInSuccess;

  /// No description provided for @facebookSignInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Facebook sign-in successful'**
  String get facebookSignInSuccess;

  /// No description provided for @workspaceControls.
  ///
  /// In en, this message translates to:
  /// **'Workspace controls'**
  String get workspaceControls;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @personalizeApp.
  ///
  /// In en, this message translates to:
  /// **'Personalize the app'**
  String get personalizeApp;

  /// No description provided for @personalizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the parts of the experience you notice most.'**
  String get personalizeSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage push permission, in-app alerts, and message visibility.'**
  String get notificationsSubtitle;

  /// No description provided for @privacySecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure app lock, saved credentials, and permission access.'**
  String get privacySecuritySubtitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light, dark, or system-driven styling.'**
  String get appearanceSubtitle;

  /// No description provided for @sessionControls.
  ///
  /// In en, this message translates to:
  /// **'Session controls'**
  String get sessionControls;

  /// No description provided for @sessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the device cleanly when you are done.'**
  String get sessionSubtitle;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out and require authentication again on next launch.'**
  String get logoutSubtitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from this workspace?'**
  String get logoutMessage;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout'**
  String get logoutFailed;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'friend'**
  String get friend;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}!'**
  String greetingWithName(Object greeting, Object name);
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
