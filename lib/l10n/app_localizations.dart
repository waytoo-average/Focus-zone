import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @feedbackCenter.
  ///
  /// In en, this message translates to:
  /// **'Feedback Center'**
  String get feedbackCenter;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts, bugs, or issues with us.'**
  String get sendFeedbackDesc;

  /// No description provided for @yourSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Your Suggestions'**
  String get yourSuggestions;

  /// No description provided for @yourSuggestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and manage your submitted feedback.'**
  String get yourSuggestionsDesc;

  /// No description provided for @developerSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Developer Suggestions'**
  String get developerSuggestions;

  /// No description provided for @developerSuggestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'See what the developer is working on and vote or comment.'**
  String get developerSuggestionsDesc;

  /// No description provided for @userInfo.
  ///
  /// In en, this message translates to:
  /// **'Your Info'**
  String get userInfo;

  /// No description provided for @userInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Optionally provide your name and phone to help us contact you.'**
  String get userInfoDesc;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Type your feedback here...'**
  String get feedbackHint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Zone'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @notAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Content not available at the moment. Please check back later!'**
  String get notAvailableNow;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @unnamedItem.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Item'**
  String get unnamedItem;

  /// No description provided for @loadingLocalizations.
  ///
  /// In en, this message translates to:
  /// **'Loading localizations...'**
  String get loadingLocalizations;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {userName}'**
  String signedInAs(Object userName);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signInWithGoogle;

  /// No description provided for @notSignedInClientNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not signed in or client not available. Please sign in.'**
  String get notSignedInClientNotAvailable;

  /// No description provided for @maxUserLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum user limit reached. You can still use other app features without signing in. Please wait for future updates.'**
  String get maxUserLimitReached;

  /// No description provided for @firstGrade.
  ///
  /// In en, this message translates to:
  /// **'First Grade'**
  String get firstGrade;

  /// No description provided for @secondGrade.
  ///
  /// In en, this message translates to:
  /// **'Second Grade'**
  String get secondGrade;

  /// No description provided for @thirdGrade.
  ///
  /// In en, this message translates to:
  /// **'Third Grade'**
  String get thirdGrade;

  /// No description provided for @fourthGrade.
  ///
  /// In en, this message translates to:
  /// **'Fourth Grade'**
  String get fourthGrade;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication Department'**
  String get communication;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics Department'**
  String get electronics;

  /// No description provided for @mechatronics.
  ///
  /// In en, this message translates to:
  /// **'Mechatronics Department'**
  String get mechatronics;

  /// No description provided for @currentYear.
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get currentYear;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @semester1.
  ///
  /// In en, this message translates to:
  /// **'First Semester'**
  String get semester1;

  /// No description provided for @semester2.
  ///
  /// In en, this message translates to:
  /// **'Second Semester'**
  String get semester2;

  /// No description provided for @lectures.
  ///
  /// In en, this message translates to:
  /// **'Lectures'**
  String get lectures;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @summaries.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get summaries;

  /// No description provided for @lectureContent.
  ///
  /// In en, this message translates to:
  /// **'Lecture Content'**
  String get lectureContent;

  /// No description provided for @errorMissingContext.
  ///
  /// In en, this message translates to:
  /// **'Missing academic context. Please navigate from the home screen.'**
  String get errorMissingContext;

  /// No description provided for @errorMissingSubjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Missing subject details. Cannot display content.'**
  String get errorMissingSubjectDetails;

  /// No description provided for @explanationContentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Explanation content for {subjectName} is not yet available.'**
  String explanationContentNotAvailable(Object subjectName);

  /// No description provided for @summariesContentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Summaries for {subjectName} are not yet available.'**
  String summariesContentNotAvailable(Object subjectName);

  /// No description provided for @errorMissingFolderId.
  ///
  /// In en, this message translates to:
  /// **'Error: Missing folder ID.'**
  String get errorMissingFolderId;

  /// No description provided for @failedToLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files: {error}'**
  String failedToLoadFiles(Object error);

  /// No description provided for @errorNoUrlProvided.
  ///
  /// In en, this message translates to:
  /// **'Error: No URL provided.'**
  String get errorNoUrlProvided;

  /// No description provided for @failedToLoadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF: {error}'**
  String failedToLoadPdf(Object error);

  /// No description provided for @errorDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled!'**
  String get errorDownloadCancelled;

  /// No description provided for @errorFileIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Error: File ID is missing.'**
  String get errorFileIdMissing;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @errorLoadingContent.
  ///
  /// In en, this message translates to:
  /// **'Error loading content: {description}'**
  String errorLoadingContent(Object description);

  /// No description provided for @cannotOpenFileType.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this file type directly.'**
  String get cannotOpenFileType;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Starting {count,plural, =1{1 download} other{{count} downloads}}...'**
  String downloadStarted(num count);

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Download completed: {fileName}'**
  String downloadCompleted(Object fileName);

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed for {fileName}: {error}'**
  String downloadFailed(Object error, Object fileName);

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled for: {fileName}'**
  String downloadCancelled(Object fileName);

  /// No description provided for @allDownloadsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All downloads completed!'**
  String get allDownloadsCompleted;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @couldNotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder: {error}'**
  String couldNotOpenFolder(Object error);

  /// No description provided for @downloadInProgressPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Download in progress. Please wait.'**
  String get downloadInProgressPleaseWait;

  /// No description provided for @cancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel Selection'**
  String get cancelSelection;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} Items Selected'**
  String itemsSelected(Object count);

  /// No description provided for @detailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsAction;

  /// No description provided for @downloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadAction;

  /// No description provided for @noItemSelectedForDetails.
  ///
  /// In en, this message translates to:
  /// **'Please select exactly one item to view details.'**
  String get noItemSelectedForDetails;

  /// No description provided for @fileDetails.
  ///
  /// In en, this message translates to:
  /// **'File Details'**
  String get fileDetails;

  /// No description provided for @fileNameField.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileNameField;

  /// No description provided for @fileTypeField.
  ///
  /// In en, this message translates to:
  /// **'File Type'**
  String get fileTypeField;

  /// No description provided for @fileSizeField.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSizeField;

  /// No description provided for @lastModifiedField.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModifiedField;

  /// No description provided for @aboutCollege.
  ///
  /// In en, this message translates to:
  /// **'About College'**
  String get aboutCollege;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @downloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocation;

  /// No description provided for @filesWillBeDownloadedTo.
  ///
  /// In en, this message translates to:
  /// **'Files will be downloaded to: {path}'**
  String filesWillBeDownloadedTo(Object path);

  /// No description provided for @permissionDeniedStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied. Cannot choose download location.'**
  String get permissionDeniedStorage;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Cannot access storage.'**
  String get permissionDenied;

  /// No description provided for @noDirectorySelected.
  ///
  /// In en, this message translates to:
  /// **'No directory selected.'**
  String get noDirectorySelected;

  /// No description provided for @failedToCreateDirectory.
  ///
  /// In en, this message translates to:
  /// **'Failed to create download directory: {error}'**
  String failedToCreateDirectory(Object error);

  /// No description provided for @failedToChooseDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'Failed to choose download path: {error}'**
  String failedToChooseDownloadPath(Object error);

  /// No description provided for @downloadPathSetTo.
  ///
  /// In en, this message translates to:
  /// **'Download path set to: {path}'**
  String downloadPathSetTo(Object path);

  /// No description provided for @downloadPathSetToFallback.
  ///
  /// In en, this message translates to:
  /// **'Download path set to: {path} (Fallback to app-specific storage)'**
  String downloadPathSetToFallback(Object path);

  /// No description provided for @selectedDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'You selected: {path}'**
  String selectedDownloadPath(Object path);

  /// No description provided for @downloadPathWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Due to Android restrictions, files may be downloaded to app-specific storage: {actualPath}'**
  String downloadPathWarning(Object actualPath);

  /// No description provided for @appSpecificDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'App-Specific'**
  String get appSpecificDownloadPath;

  /// No description provided for @clearCustomDownloadPathOption.
  ///
  /// In en, this message translates to:
  /// **'Clear Custom Download Path'**
  String get clearCustomDownloadPathOption;

  /// No description provided for @confirmClearCustomDownloadPath.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the custom download path? Downloads will revert to app-specific storage.'**
  String get confirmClearCustomDownloadPath;

  /// No description provided for @customDownloadPathCleared.
  ///
  /// In en, this message translates to:
  /// **'Custom download path setting removed. Downloads will now go to app-specific storage.'**
  String get customDownloadPathCleared;

  /// No description provided for @customDownloadPathClearedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Custom download path cleared. Downloads will now go to app-specific storage.'**
  String get customDownloadPathClearedConfirmation;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @todoNotifications.
  ///
  /// In en, this message translates to:
  /// **'Todo Notifications'**
  String get todoNotifications;

  /// No description provided for @todoVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get todoVibration;

  /// No description provided for @quranDownloadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Quran Download Notifications'**
  String get quranDownloadNotifications;

  /// No description provided for @quranVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get quranVibration;

  /// No description provided for @taskReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Task Reminder Time'**
  String get taskReminderTime;

  /// No description provided for @atDeadline.
  ///
  /// In en, this message translates to:
  /// **'At Deadline'**
  String get atDeadline;

  /// No description provided for @min5.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get min5;

  /// No description provided for @min15.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get min15;

  /// No description provided for @min30.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get min30;

  /// No description provided for @hr1.
  ///
  /// In en, this message translates to:
  /// **'1 hr'**
  String get hr1;

  /// No description provided for @hr2.
  ///
  /// In en, this message translates to:
  /// **'2 hr'**
  String get hr2;

  /// No description provided for @hr3.
  ///
  /// In en, this message translates to:
  /// **'3 hr'**
  String get hr3;

  /// No description provided for @todoVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Todo Notifications'**
  String get todoVibrationSubtitle;

  /// No description provided for @quranVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quran Download Notifications'**
  String get quranVibrationSubtitle;

  /// No description provided for @clearPdfCache.
  ///
  /// In en, this message translates to:
  /// **'Clear PDF Cache'**
  String get clearPdfCache;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @confirmClearCache.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all internally cached PDF files? This will free up space but require re-downloading.'**
  String get confirmClearCache;

  /// No description provided for @cacheClearedItems.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} cached PDF files.'**
  String cacheClearedItems(Object count);

  /// No description provided for @cacheClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear PDF cache: {error}'**
  String cacheClearFailed(Object error);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Focus Zone is a mobile application designed to help students access and organize their academic materials from Google Drive.'**
  String get appDescription;

  /// No description provided for @madeBy.
  ///
  /// In en, this message translates to:
  /// **'Developed By'**
  String get madeBy;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Belal Mohamed Elnemr'**
  String get developerName;

  /// No description provided for @developerDetails.
  ///
  /// In en, this message translates to:
  /// **'Communication Engineering Student'**
  String get developerDetails;

  /// No description provided for @feedbackCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts and suggestions'**
  String get feedbackCenterSubtitle;

  /// No description provided for @developerSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here are some features we\'re planning to add:'**
  String get developerSuggestionsSubtitle;

  /// No description provided for @yourOpinion.
  ///
  /// In en, this message translates to:
  /// **'Your Opinion'**
  String get yourOpinion;

  /// No description provided for @opinionHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts about the app...'**
  String get opinionHint;

  /// No description provided for @suggestionHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest new features or improvements...'**
  String get suggestionHint;

  /// No description provided for @submitOpinion.
  ///
  /// In en, this message translates to:
  /// **'Submit Opinion'**
  String get submitOpinion;

  /// No description provided for @submitSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Submit Suggestion'**
  String get submitSuggestion;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackSubmitted;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit feedback. Please try again.'**
  String get feedbackError;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your feedback before submitting.'**
  String get feedbackEmpty;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch URL: {url}'**
  String couldNotLaunchUrl(Object url);

  /// No description provided for @collegeName.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Chinese College of Applied Technology'**
  String get collegeName;

  /// No description provided for @eccatIntro.
  ///
  /// In en, this message translates to:
  /// **'The Egyptian-Chinese College for Applied Technology at Suez Canal University is a joint initiative with China offering hands-on, industry-focused education in fields like mechatronics, electronics, and communication technology..'**
  String get eccatIntro;

  /// No description provided for @connectWithUs.
  ///
  /// In en, this message translates to:
  /// **'Connect With Us'**
  String get connectWithUs;

  /// No description provided for @facebookPage.
  ///
  /// In en, this message translates to:
  /// **'Facebook Page'**
  String get facebookPage;

  /// No description provided for @collegeLocation.
  ///
  /// In en, this message translates to:
  /// **'College Location'**
  String get collegeLocation;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No files found in this folder.'**
  String get noFilesFound;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @studyButton.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get studyButton;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitButton;

  /// No description provided for @todoListButton.
  ///
  /// In en, this message translates to:
  /// **'To-Do List'**
  String get todoListButton;

  /// No description provided for @todoListTitle.
  ///
  /// In en, this message translates to:
  /// **'My To-Do List'**
  String get todoListTitle;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @enterYourTaskHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your task here...'**
  String get enterYourTaskHere;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet! Add one below.'**
  String get noTasksYet;

  /// No description provided for @taskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added!'**
  String get taskAdded;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed!'**
  String get taskCompleted;

  /// No description provided for @taskReactivated.
  ///
  /// In en, this message translates to:
  /// **'Task reactivated!'**
  String get taskReactivated;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted!'**
  String get taskDeleted;

  /// No description provided for @emptyTaskError.
  ///
  /// In en, this message translates to:
  /// **'Task cannot be empty.'**
  String get emptyTaskError;

  /// No description provided for @allListsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Lists'**
  String get allListsTitle;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTasks;

  /// No description provided for @tomorrowTasks.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowTasks;

  /// No description provided for @thisWeekTasks.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekTasks;

  /// No description provided for @enterQuickTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Quick Task Here'**
  String get enterQuickTaskHint;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @newTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTaskTitle;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTaskTitle;

  /// No description provided for @whatIsToBeDone.
  ///
  /// In en, this message translates to:
  /// **'What is to be done?'**
  String get whatIsToBeDone;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get dueTime;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @addToLlist.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToLlist;

  /// No description provided for @noRepeat.
  ///
  /// In en, this message translates to:
  /// **'No Repeat'**
  String get noRepeat;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @defaultList.
  ///
  /// In en, this message translates to:
  /// **'Default List'**
  String get defaultList;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save Task'**
  String get saveTask;

  /// No description provided for @taskSaved.
  ///
  /// In en, this message translates to:
  /// **'Task saved!'**
  String get taskSaved;

  /// No description provided for @searchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasksHint;

  /// No description provided for @noMatchingTasks.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks found.'**
  String get noMatchingTasks;

  /// No description provided for @laterTasks.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterTasks;

  /// No description provided for @noDateTasks.
  ///
  /// In en, this message translates to:
  /// **'No Date'**
  String get noDateTasks;

  /// No description provided for @completedTasksSection.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasksSection;

  /// No description provided for @noTasksIllustrationText.
  ///
  /// In en, this message translates to:
  /// **'No tasks here! Time to add some study goals or daily reminders.'**
  String get noTasksIllustrationText;

  /// No description provided for @noFilesIllustrationText.
  ///
  /// In en, this message translates to:
  /// **'It looks like there are no files in this folder, or you haven\'t selected a subject yet.'**
  String get noFilesIllustrationText;

  /// No description provided for @emptySearchIllustrationText.
  ///
  /// In en, this message translates to:
  /// **'No tasks found matching your search. Try a different keyword!'**
  String get emptySearchIllustrationText;

  /// No description provided for @todayTasksProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks: {completed} of {total} completed'**
  String todayTasksProgress(Object completed, Object total);

  /// No description provided for @notificationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Reminder for:'**
  String get notificationReminderBody;

  /// No description provided for @everyXDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String everyXDays(Object count);

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekends;

  /// No description provided for @lecturesContentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lectures content for {subjectName} is not yet available.'**
  String lecturesContentNotAvailable(Object subjectName);

  /// No description provided for @downloadSelected.
  ///
  /// In en, this message translates to:
  /// **'Download Selected'**
  String get downloadSelected;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @upComing.
  ///
  /// In en, this message translates to:
  /// **'Up-coming'**
  String get upComing;

  /// No description provided for @upComingContent.
  ///
  /// In en, this message translates to:
  /// **'Up-coming content will be available soon!'**
  String get upComingContent;

  /// No description provided for @dashboardPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your Focus Zone Dashboard!'**
  String get dashboardPlaceholder;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Your activity, quick access, and personalized insights will appear here soon.'**
  String get dashboardComingSoon;

  /// No description provided for @errorPageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {pageName}'**
  String errorPageNotFound(Object pageName);

  /// No description provided for @errorAttemptedGlobalPush.
  ///
  /// In en, this message translates to:
  /// **'Attempted to open content outside the current tab\'s navigation. Please try again from the main tab, or report this issue if it persists.'**
  String get errorAttemptedGlobalPush;

  /// No description provided for @downloadFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Download folder not found. It might have been moved or deleted.'**
  String get downloadFolderNotFound;

  /// No description provided for @discordProfile.
  ///
  /// In en, this message translates to:
  /// **'Discord Profile'**
  String get discordProfile;

  /// No description provided for @githubProfile.
  ///
  /// In en, this message translates to:
  /// **'GitHub Profile'**
  String get githubProfile;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recentFiles;

  /// No description provided for @noRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No recent files to display.'**
  String get noRecentFiles;

  /// No description provided for @quickSettings.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get quickSettings;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeUser(Object userName);

  /// No description provided for @yourStudyActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Study Activity'**
  String get yourStudyActivity;

  /// No description provided for @lastOpened.
  ///
  /// In en, this message translates to:
  /// **'Last Opened'**
  String get lastOpened;

  /// No description provided for @documentsViewedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Documents viewed this week: {count}'**
  String documentsViewedThisWeek(Object count);

  /// No description provided for @keepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning, consistency is key!'**
  String get keepLearning;

  /// No description provided for @todoSnapshot.
  ///
  /// In en, this message translates to:
  /// **'To-Do Snapshot'**
  String get todoSnapshot;

  /// No description provided for @nextDeadline.
  ///
  /// In en, this message translates to:
  /// **'Next Deadline'**
  String get nextDeadline;

  /// No description provided for @noUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks right now!'**
  String get noUpcomingTasks;

  /// No description provided for @dailyTaskProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress: {completed} of {total} tasks completed'**
  String dailyTaskProgress(Object completed, Object total);

  /// No description provided for @overdueTasksDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks: {count}'**
  String overdueTasksDashboard(Object count);

  /// No description provided for @yourStudyZone.
  ///
  /// In en, this message translates to:
  /// **'Your Study Zone'**
  String get yourStudyZone;

  /// No description provided for @exploreSubjects.
  ///
  /// In en, this message translates to:
  /// **'Explore Subjects'**
  String get exploreSubjects;

  /// No description provided for @findNewMaterials.
  ///
  /// In en, this message translates to:
  /// **'Find new materials and lectures.'**
  String get findNewMaterials;

  /// No description provided for @createStudyGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a Study Goal'**
  String get createStudyGoal;

  /// No description provided for @planYourNextTask.
  ///
  /// In en, this message translates to:
  /// **'Plan your next study task or reminder.'**
  String get planYourNextTask;

  /// No description provided for @chooseNewLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose New Location'**
  String get chooseNewLocation;

  /// No description provided for @openCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Current Location'**
  String get openCurrentLocation;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @downloadLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Download location updated to: {path}'**
  String downloadLocationUpdated(Object path);

  /// No description provided for @downloadLocationReset.
  ///
  /// In en, this message translates to:
  /// **'Download location reset to default.'**
  String get downloadLocationReset;

  /// No description provided for @noLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'No location selected.'**
  String get noLocationSelected;

  /// No description provided for @failedToSetDownloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to set download location: {error}'**
  String failedToSetDownloadLocation(Object error);

  /// No description provided for @permissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied permanently. Please grant it from app settings.'**
  String get permissionDeniedForever;

  /// No description provided for @storagePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get storagePermissionTitle;

  /// No description provided for @storagePermissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This app needs storage permission to download and save files. Without this permission, you won\'t be able to download files or choose where to save them.'**
  String get storagePermissionExplanation;

  /// No description provided for @storagePermissionNote.
  ///
  /// In en, this message translates to:
  /// **'This permission is required for downloading and managing your study materials. You can change this later in your device settings.'**
  String get storagePermissionNote;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @zikr.
  ///
  /// In en, this message translates to:
  /// **'Zikr'**
  String get zikr;

  /// No description provided for @azkar.
  ///
  /// In en, this message translates to:
  /// **'Azkar'**
  String get azkar;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// No description provided for @morningRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Morning Remembrance'**
  String get morningRemembrance;

  /// No description provided for @eveningRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Evening Remembrance'**
  String get eveningRemembrance;

  /// No description provided for @customZikr.
  ///
  /// In en, this message translates to:
  /// **'Custom Zikr'**
  String get customZikr;

  /// No description provided for @zikrCounter.
  ///
  /// In en, this message translates to:
  /// **'Zikr Counter'**
  String get zikrCounter;

  /// No description provided for @tapToCount.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to count'**
  String get tapToCount;

  /// No description provided for @azkarTime.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{{count} time} =2{{count} times} other{{count} times}}'**
  String azkarTime(num count);

  /// No description provided for @azkarPage.
  ///
  /// In en, this message translates to:
  /// **'{currentPage}/{totalPages}'**
  String azkarPage(Object currentPage, Object totalPages);

  /// No description provided for @azkarCompleted.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah, you have completed the Azkar!'**
  String get azkarCompleted;

  /// No description provided for @noSurahsFound.
  ///
  /// In en, this message translates to:
  /// **'No surahs found.'**
  String get noSurahsFound;

  /// No description provided for @failedToLoadSurahs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load surahs. Please check your connection.'**
  String get failedToLoadSurahs;

  /// No description provided for @failedToLoadAyahs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ayahs. Please check your connection.'**
  String get failedToLoadAyahs;

  /// No description provided for @failedToLoadPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prayer times.'**
  String get failedToLoadPrayerTimes;

  /// No description provided for @untilNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Until {prayerName} prayer'**
  String untilNextPrayer(Object prayerName);

  /// No description provided for @prayerNameFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerNameFajr;

  /// No description provided for @prayerNameSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerNameSunrise;

  /// No description provided for @prayerNameDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerNameDhuhr;

  /// No description provided for @prayerNameAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerNameAsr;

  /// No description provided for @prayerNameMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerNameMaghrib;

  /// No description provided for @prayerNameIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerNameIsha;

  /// No description provided for @prayerNameJumah.
  ///
  /// In en, this message translates to:
  /// **'Jumah'**
  String get prayerNameJumah;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get dueToday;

  /// No description provided for @lessThanOneDay.
  ///
  /// In en, this message translates to:
  /// **'Less than one day'**
  String get lessThanOneDay;

  /// No description provided for @dueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {timeString}'**
  String dueIn(Object timeString);

  /// No description provided for @overdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {timeString}'**
  String overdueBy(Object timeString);

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{year} other{years}}'**
  String year(num count);

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{month} other{months}}'**
  String month(num count);

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{week} other{weeks}}'**
  String week(num count);

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day} other{days}}'**
  String day(num count);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats: {repeatInterval}'**
  String repeats(Object repeatInterval);

  /// No description provided for @sortByDueDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Asc)'**
  String get sortByDueDateAsc;

  /// No description provided for @sortByDueDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Desc)'**
  String get sortByDueDateDesc;

  /// No description provided for @sortByTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title (Asc)'**
  String get sortByTitleAsc;

  /// No description provided for @sortByTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title (Desc)'**
  String get sortByTitleDesc;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get allTasks;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @taskOptions.
  ///
  /// In en, this message translates to:
  /// **'Task options'**
  String get taskOptions;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @markAsNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markAsNotDone;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markAsDone;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirmation;

  /// No description provided for @writeYourZikr.
  ///
  /// In en, this message translates to:
  /// **'Write your Zikr'**
  String get writeYourZikr;

  /// No description provided for @zikrHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., SubhanAllah, Alhamdulillah...'**
  String get zikrHint;

  /// No description provided for @errorZikrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the Zikr text.'**
  String get errorZikrEmpty;

  /// No description provided for @setRepetitions.
  ///
  /// In en, this message translates to:
  /// **'Set the number of repetitions'**
  String get setRepetitions;

  /// No description provided for @errorCountEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a count.'**
  String get errorCountEmpty;

  /// No description provided for @errorCountZero.
  ///
  /// In en, this message translates to:
  /// **'Count must be greater than zero.'**
  String get errorCountZero;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @myAzkarTitle.
  ///
  /// In en, this message translates to:
  /// **'My Azkar'**
  String get myAzkarTitle;

  /// No description provided for @addZikrTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Zikr'**
  String get addZikrTitle;

  /// No description provided for @editZikrTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Zikr'**
  String get editZikrTitle;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak: {streakCount}'**
  String streakLabel(Object streakCount);

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Zikr'**
  String get deleteConfirmationTitle;

  /// No description provided for @deleteConfirmationContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this Zikr?'**
  String get deleteConfirmationContent;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Suggestions'**
  String get quickAddTitle;

  /// No description provided for @emptyAzkarList.
  ///
  /// In en, this message translates to:
  /// **'Your custom Azkar list is empty.\nTap the + button to add a new one.'**
  String get emptyAzkarList;

  /// No description provided for @suggestion1.
  ///
  /// In en, this message translates to:
  /// **'Glory is to Allah'**
  String get suggestion1;

  /// No description provided for @suggestion2.
  ///
  /// In en, this message translates to:
  /// **'Praise be to Allah'**
  String get suggestion2;

  /// No description provided for @suggestion3.
  ///
  /// In en, this message translates to:
  /// **'Allah is the Greatest'**
  String get suggestion3;

  /// No description provided for @suggestion4.
  ///
  /// In en, this message translates to:
  /// **'I seek the forgiveness of Allah'**
  String get suggestion4;

  /// No description provided for @dailyCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed today: {count}'**
  String dailyCountLabel(Object count);

  /// No description provided for @quickCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Counter'**
  String get quickCounterTitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @quranSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The Holy Quran'**
  String get quranSubtitle;

  /// No description provided for @quranDescription.
  ///
  /// In en, this message translates to:
  /// **'Read, download, and manage the full Quran and Juzs.'**
  String get quranDescription;

  /// No description provided for @browseJuzs.
  ///
  /// In en, this message translates to:
  /// **'Browse Juzs'**
  String get browseJuzs;

  /// No description provided for @browseJuzsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and download individual Juzs'**
  String get browseJuzsSubtitle;

  /// No description provided for @viewFullQuran.
  ///
  /// In en, this message translates to:
  /// **'View Full Quran'**
  String get viewFullQuran;

  /// No description provided for @pauseDownload.
  ///
  /// In en, this message translates to:
  /// **'Pause Download'**
  String get pauseDownload;

  /// No description provided for @resumeDownload.
  ///
  /// In en, this message translates to:
  /// **'Resume Download'**
  String get resumeDownload;

  /// No description provided for @downloadFullQuran.
  ///
  /// In en, this message translates to:
  /// **'Download Full Quran'**
  String get downloadFullQuran;

  /// No description provided for @fullQuranReady.
  ///
  /// In en, this message translates to:
  /// **'Full Quran is ready to view!'**
  String get fullQuranReady;

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{downloaded}/{total} pages ({progress}%)'**
  String pagesCount(Object downloaded, Object progress, Object total);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @completeQuran.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran ({size}, {pages} pages)'**
  String completeQuran(Object pages, Object size);

  /// No description provided for @pausingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Pausing, please wait...'**
  String get pausingPleaseWait;

  /// No description provided for @cancellingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Cancelling, please wait...'**
  String get cancellingPleaseWait;

  /// No description provided for @deletingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Deleting, please wait...'**
  String get deletingPleaseWait;

  /// No description provided for @deleteFullQuran.
  ///
  /// In en, this message translates to:
  /// **'Delete Full Quran'**
  String get deleteFullQuran;

  /// No description provided for @freeUpStorage.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get freeUpStorage;

  /// No description provided for @downloadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Download incomplete'**
  String get downloadIncomplete;

  /// No description provided for @pagesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{downloaded} of {total} pages downloaded'**
  String pagesDownloaded(Object downloaded, Object total);

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during download.'**
  String get anErrorOccurred;

  /// No description provided for @stillUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'This feature is still under development.'**
  String get stillUnderDevelopment;

  /// No description provided for @downloadFullQuranDialog.
  ///
  /// In en, this message translates to:
  /// **'The full Quran is approximately {size} and contains {pages} pages. This may take some time to download. Continue? KEEP INTERNET CONNECTION ON'**
  String downloadFullQuranDialog(Object pages, Object size);

  /// No description provided for @areYouSureDeleteQuran.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the full Quran? This will free up storage space but you will need to download it again to view it.'**
  String get areYouSureDeleteQuran;

  /// No description provided for @fullQuranDeleted.
  ///
  /// In en, this message translates to:
  /// **'Full Quran deleted successfully.'**
  String get fullQuranDeleted;

  /// No description provided for @downloadControls.
  ///
  /// In en, this message translates to:
  /// **'Download Controls'**
  String get downloadControls;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current file:'**
  String get current;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @deleteDownloadedFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete Downloaded Files'**
  String get deleteDownloadedFiles;

  /// No description provided for @juzListTitle.
  ///
  /// In en, this message translates to:
  /// **'Juz List'**
  String get juzListTitle;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @juzNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} is not downloaded.'**
  String juzNotDownloaded(Object juz);

  /// No description provided for @juzProperties.
  ///
  /// In en, this message translates to:
  /// **'Juz Properties'**
  String get juzProperties;

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'File count'**
  String get fileCount;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total size'**
  String get totalSize;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @couldNotLoadProperties.
  ///
  /// In en, this message translates to:
  /// **'Could not load properties.'**
  String get couldNotLoadProperties;

  /// No description provided for @pendingPausing.
  ///
  /// In en, this message translates to:
  /// **'Pausing...'**
  String get pendingPausing;

  /// No description provided for @pendingCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get pendingCancelling;

  /// No description provided for @pendingDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get pendingDeleting;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pagesLabel;

  /// No description provided for @surahListTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah List'**
  String get surahListTitle;

  /// No description provided for @surahLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading Surahs'**
  String get surahLoadError;

  /// No description provided for @noSurahData.
  ///
  /// In en, this message translates to:
  /// **'No Surah data available.'**
  String get noSurahData;

  /// No description provided for @ayahCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahCountLabel;

  /// No description provided for @makkiType.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get makkiType;

  /// No description provided for @madaniType.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get madaniType;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading Settings'**
  String get readingSettings;

  /// No description provided for @nightMode.
  ///
  /// In en, this message translates to:
  /// **'Night Mode'**
  String get nightMode;

  /// No description provided for @nightModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dark background for low light'**
  String get nightModeSubtitle;

  /// No description provided for @scrollDirection.
  ///
  /// In en, this message translates to:
  /// **'Scroll Direction'**
  String get scrollDirection;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @readingTimer.
  ///
  /// In en, this message translates to:
  /// **'Reading Timer'**
  String get readingTimer;

  /// No description provided for @timerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running: {time}'**
  String timerRunning(Object time);

  /// No description provided for @timerNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get timerNotRunning;

  /// No description provided for @autoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto Scroll'**
  String get autoScroll;

  /// No description provided for @autoScrollEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled ({seconds}s/page)'**
  String autoScrollEnabled(Object seconds);

  /// No description provided for @autoScrollDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get autoScrollDisabled;

  /// No description provided for @scrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Scroll Speed'**
  String get scrollSpeed;

  /// No description provided for @secondsPerPage.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds per page'**
  String secondsPerPage(Object seconds);

  /// No description provided for @minTimeToCountPage.
  ///
  /// In en, this message translates to:
  /// **'Minimum Time to Count Page as Read'**
  String get minTimeToCountPage;

  /// No description provided for @secondsLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String secondsLabel(Object seconds);

  /// No description provided for @readingAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reading Analytics'**
  String get readingAnalytics;

  /// No description provided for @streaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaks;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreak;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{progress}%'**
  String goalProgress(Object progress);

  /// No description provided for @minutesGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'{minutes} / {goal} minutes'**
  String minutesGoalProgress(Object goal, Object minutes);

  /// No description provided for @weeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoal;

  /// No description provided for @pagesGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'{pages} / {goal} pages'**
  String pagesGoalProgress(Object goal, Object pages);

  /// No description provided for @noInsights.
  ///
  /// In en, this message translates to:
  /// **'No insights yet. Start reading to see tips!'**
  String get noInsights;

  /// No description provided for @noReadingSessions.
  ///
  /// In en, this message translates to:
  /// **'No reading sessions yet.'**
  String get noReadingSessions;

  /// No description provided for @startStreakTip.
  ///
  /// In en, this message translates to:
  /// **'Start a streak by reading every day!'**
  String get startStreakTip;

  /// No description provided for @totalTimeReading.
  ///
  /// In en, this message translates to:
  /// **'Total time reading: {seconds} seconds'**
  String totalTimeReading(Object seconds);

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @weekendReadingTip.
  ///
  /// In en, this message translates to:
  /// **'You read more on weekends!'**
  String get weekendReadingTip;

  /// No description provided for @weekdayReadingTip.
  ///
  /// In en, this message translates to:
  /// **'You read more on weekdays!'**
  String get weekdayReadingTip;

  /// No description provided for @amazingStreakTip.
  ///
  /// In en, this message translates to:
  /// **'Amazing! You have a {streak}-day streak!'**
  String amazingStreakTip(Object streak);

  /// No description provided for @greatStreakTip.
  ///
  /// In en, this message translates to:
  /// **'Great! Keep your {streak}-day streak going!'**
  String greatStreakTip(Object streak);

  /// No description provided for @weeklyGoalAchievedTip.
  ///
  /// In en, this message translates to:
  /// **'You reached your weekly goal! 🎉'**
  String get weeklyGoalAchievedTip;

  /// No description provided for @closeWeeklyGoalTip.
  ///
  /// In en, this message translates to:
  /// **'You are close to your weekly goal!'**
  String get closeWeeklyGoalTip;

  /// No description provided for @dailyGoalMetTip.
  ///
  /// In en, this message translates to:
  /// **'You met your daily goal {days} times this week!'**
  String dailyGoalMetTip(Object days);

  /// No description provided for @sessionInsights.
  ///
  /// In en, this message translates to:
  /// **'Session Insights'**
  String get sessionInsights;

  /// No description provided for @avgTimePerPage.
  ///
  /// In en, this message translates to:
  /// **'Average time per page: {time} seconds'**
  String avgTimePerPage(Object time);

  /// No description provided for @mostReadPage.
  ///
  /// In en, this message translates to:
  /// **'Most read page: {page} ({time} seconds)'**
  String mostReadPage(Object page, Object time);

  /// No description provided for @leastReadPage.
  ///
  /// In en, this message translates to:
  /// **'Least read page: {page} ({time} seconds)'**
  String leastReadPage(Object page, Object time);

  /// No description provided for @uniquePagesRead.
  ///
  /// In en, this message translates to:
  /// **'Unique pages read: {pages}'**
  String uniquePagesRead(Object pages);

  /// No description provided for @noSessionData.
  ///
  /// In en, this message translates to:
  /// **'No session data yet. Start a session to see insights.'**
  String get noSessionData;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @pagesReadLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Pages Read (Last 7 Days)'**
  String get pagesReadLast7Days;

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get recentSessions;

  /// No description provided for @fullQuran.
  ///
  /// In en, this message translates to:
  /// **'Full Quran'**
  String get fullQuran;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String juz(Object juz);

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarkPage.
  ///
  /// In en, this message translates to:
  /// **'Bookmark Page'**
  String get bookmarkPage;

  /// No description provided for @surahList.
  ///
  /// In en, this message translates to:
  /// **'Surah List'**
  String get surahList;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @noImagesFoundForThisJuz.
  ///
  /// In en, this message translates to:
  /// **'No images found for this Juz.'**
  String get noImagesFoundForThisJuz;

  /// No description provided for @autoScrolling.
  ///
  /// In en, this message translates to:
  /// **'Auto-scrolling'**
  String get autoScrolling;

  /// No description provided for @readingGoals.
  ///
  /// In en, this message translates to:
  /// **'Reading Goals'**
  String get readingGoals;

  /// No description provided for @setDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Goal'**
  String get setDailyGoal;

  /// No description provided for @viewDownloadedJuzs.
  ///
  /// In en, this message translates to:
  /// **'View Downloaded Juzs'**
  String get viewDownloadedJuzs;

  /// No description provided for @switchJuz.
  ///
  /// In en, this message translates to:
  /// **'Switch Juz'**
  String get switchJuz;

  /// No description provided for @downloadedJuzsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Juzs'**
  String get downloadedJuzsTitle;

  /// No description provided for @juzsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{downloaded}/{total} Juzs downloaded'**
  String juzsDownloaded(Object downloaded, Object total);

  /// No description provided for @enterYourInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter your info (optional) to help us improve communication.'**
  String get enterYourInfo;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @updateYourInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your info'**
  String get updateYourInfo;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @recentComments.
  ///
  /// In en, this message translates to:
  /// **'Recent comments'**
  String get recentComments;

  /// No description provided for @prayerReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder time'**
  String get prayerReminderTime;

  /// No description provided for @prayerVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get prayerVibration;

  /// No description provided for @prayerVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Notifications'**
  String get prayerVibrationSubtitle;

  /// No description provided for @globalNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Global todo notifications are disabled'**
  String get globalNotificationsDisabled;

  /// No description provided for @prayerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Notifications'**
  String get prayerNotifications;

  /// No description provided for @prayerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{prayerName} prayer is in 1 minute'**
  String prayerNotificationBody(Object prayerName);

  /// No description provided for @prayerNotificationBodyAdvance.
  ///
  /// In en, this message translates to:
  /// **'{prayerName} prayer is in {timeText}'**
  String prayerNotificationBodyAdvance(Object prayerName, Object timeText);

  /// No description provided for @atPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get atPrayerTime;

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String inMinutes(Object count);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String inHours(Object count);

  /// No description provided for @inOneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get inOneMinute;

  /// No description provided for @inOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get inOneHour;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
