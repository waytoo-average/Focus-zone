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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ECCAT Study Station'**
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
  /// **'Not signed in. Google Drive client not available.'**
  String get notSignedInClientNotAvailable;

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
  /// **'Folder ID is missing. Cannot browse content.'**
  String get errorMissingFolderId;

  /// No description provided for @failedToLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files: {error}'**
  String failedToLoadFiles(Object error);

  /// No description provided for @errorNoUrlProvided.
  ///
  /// In en, this message translates to:
  /// **'No URL provided for content. Cannot display.'**
  String get errorNoUrlProvided;

  /// No description provided for @failedToLoadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF: {error}'**
  String failedToLoadPdf(Object error);

  /// No description provided for @errorDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download was cancelled.'**
  String get errorDownloadCancelled;

  /// No description provided for @errorFileIdMissing.
  ///
  /// In en, this message translates to:
  /// **'File ID is missing. Cannot open or download.'**
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
  /// **'Cannot open this file type directly in the app.'**
  String get cannotOpenFileType;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started for {count} items.'**
  String downloadStarted(Object count);

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
  /// **'Download cancelled for {fileName}.'**
  String downloadCancelled(Object fileName);

  /// No description provided for @allDownloadsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All selected downloads completed.'**
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
  /// **'No item selected for details.'**
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
  /// **'Permission denied.'**
  String get permissionDenied;

  /// No description provided for @noDirectorySelected.
  ///
  /// In en, this message translates to:
  /// **'No directory selected.'**
  String get noDirectorySelected;

  /// No description provided for @failedToCreateDirectory.
  ///
  /// In en, this message translates to:
  /// **'Failed to create directory: {error}'**
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
  /// **'ECCAT Study Station is a mobile application designed to help students access and organize their academic materials from Google Drive.'**
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
  /// **'Communication and Electronics Engineering Student'**
  String get developerDetails;

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
  /// **'The Egyptian Chinese College of Applied Technology (ECCAT) is a unique educational institution fostering practical and technological skills.'**
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
  /// **'Looks like this folder is empty. Time to upload some materials!'**
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
  /// **'Welcome to your Study Station Dashboard!'**
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
