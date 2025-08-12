// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get feedbackCenter => 'Feedback Center';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackDesc =>
      'Share your thoughts, bugs, or issues with us.';

  @override
  String get yourSuggestions => 'Your Suggestions';

  @override
  String get yourSuggestionsDesc => 'View and manage your submitted feedback.';

  @override
  String get developerSuggestions => 'Developer Suggestions';

  @override
  String get developerSuggestionsDesc =>
      'See what the developer is working on and vote or comment.';

  @override
  String get userInfo => 'Your Info';

  @override
  String get userInfoDesc =>
      'Optionally provide your name and phone to help us contact you.';

  @override
  String get feedbackHint => 'Type your feedback here...';

  @override
  String get submit => 'Submit';

  @override
  String get appTitle => 'Focus Zone';

  @override
  String get settings => 'Settings';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get notAvailableNow =>
      'Content not available at the moment. Please check back later!';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get unnamedItem => 'Unnamed Item';

  @override
  String get loadingLocalizations => 'Loading localizations...';

  @override
  String get signIn => 'Sign In';

  @override
  String signedInAs(Object userName) {
    return 'Signed in as $userName';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get signInWithGoogle => 'Sign In with Google';

  @override
  String get notSignedInClientNotAvailable =>
      'Not signed in or client not available. Please sign in.';

  @override
  String get maxUserLimitReached =>
      'Maximum user limit reached. You can still use other app features without signing in. Please wait for future updates.';

  @override
  String get firstGrade => 'First Grade';

  @override
  String get secondGrade => 'Second Grade';

  @override
  String get thirdGrade => 'Third Grade';

  @override
  String get fourthGrade => 'Fourth Grade';

  @override
  String get communication => 'Communication Department';

  @override
  String get electronics => 'Electronics Department';

  @override
  String get mechatronics => 'Mechatronics Department';

  @override
  String get currentYear => 'Current Year';

  @override
  String get lastYear => 'Last Year';

  @override
  String get semester1 => 'First Semester';

  @override
  String get semester2 => 'Second Semester';

  @override
  String get lectures => 'Lectures';

  @override
  String get explanation => 'Explanation';

  @override
  String get summaries => 'Summaries';

  @override
  String get lectureContent => 'Lecture Content';

  @override
  String get errorMissingContext =>
      'Missing academic context. Please navigate from the home screen.';

  @override
  String get errorMissingSubjectDetails =>
      'Missing subject details. Cannot display content.';

  @override
  String explanationContentNotAvailable(Object subjectName) {
    return 'Explanation content for $subjectName is not yet available.';
  }

  @override
  String summariesContentNotAvailable(Object subjectName) {
    return 'Summaries for $subjectName are not yet available.';
  }

  @override
  String get errorMissingFolderId => 'Error: Missing folder ID.';

  @override
  String failedToLoadFiles(Object error) {
    return 'Failed to load files: $error';
  }

  @override
  String get errorNoUrlProvided => 'Error: No URL provided.';

  @override
  String failedToLoadPdf(Object error) {
    return 'Failed to load PDF: $error';
  }

  @override
  String get errorDownloadCancelled => 'Download cancelled!';

  @override
  String get errorFileIdMissing => 'Error: File ID is missing.';

  @override
  String get downloading => 'Downloading';

  @override
  String errorLoadingContent(Object description) {
    return 'Error loading content: $description';
  }

  @override
  String get cannotOpenFileType => 'Cannot open this file type directly.';

  @override
  String downloadStarted(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
    );
    return 'Starting $_temp0...';
  }

  @override
  String downloadCompleted(Object fileName) {
    return 'Download completed: $fileName';
  }

  @override
  String get openFile => 'Open File';

  @override
  String downloadFailed(Object error, Object fileName) {
    return 'Download failed for $fileName: $error';
  }

  @override
  String downloadCancelled(Object fileName) {
    return 'Download cancelled for: $fileName';
  }

  @override
  String get allDownloadsCompleted => 'All downloads completed!';

  @override
  String get openFolder => 'Open Folder';

  @override
  String couldNotOpenFolder(Object error) {
    return 'Could not open folder: $error';
  }

  @override
  String get downloadInProgressPleaseWait =>
      'Download in progress. Please wait.';

  @override
  String get cancelSelection => 'Cancel Selection';

  @override
  String itemsSelected(Object count) {
    return '$count Items Selected';
  }

  @override
  String get detailsAction => 'Details';

  @override
  String get downloadAction => 'Download';

  @override
  String get noItemSelectedForDetails =>
      'Please select exactly one item to view details.';

  @override
  String get fileDetails => 'File Details';

  @override
  String get fileNameField => 'File Name';

  @override
  String get fileTypeField => 'File Type';

  @override
  String get fileSizeField => 'File Size';

  @override
  String get lastModifiedField => 'Last Modified';

  @override
  String get aboutCollege => 'About College';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemDefault => 'System Default';

  @override
  String get downloadLocation => 'Download Location';

  @override
  String filesWillBeDownloadedTo(Object path) {
    return 'Files will be downloaded to: $path';
  }

  @override
  String get permissionDeniedStorage =>
      'Storage permission denied. Cannot choose download location.';

  @override
  String get permissionDenied => 'Permission denied. Cannot access storage.';

  @override
  String get noDirectorySelected => 'No directory selected.';

  @override
  String failedToCreateDirectory(Object error) {
    return 'Failed to create download directory: $error';
  }

  @override
  String failedToChooseDownloadPath(Object error) {
    return 'Failed to choose download path: $error';
  }

  @override
  String downloadPathSetTo(Object path) {
    return 'Download path set to: $path';
  }

  @override
  String downloadPathSetToFallback(Object path) {
    return 'Download path set to: $path (Fallback to app-specific storage)';
  }

  @override
  String selectedDownloadPath(Object path) {
    return 'You selected: $path';
  }

  @override
  String downloadPathWarning(Object actualPath) {
    return 'Warning: Due to Android restrictions, files may be downloaded to app-specific storage: $actualPath';
  }

  @override
  String get appSpecificDownloadPath => 'App-Specific';

  @override
  String get clearCustomDownloadPathOption => 'Clear Custom Download Path';

  @override
  String get confirmClearCustomDownloadPath =>
      'Are you sure you want to clear the custom download path? Downloads will revert to app-specific storage.';

  @override
  String get customDownloadPathCleared =>
      'Custom download path setting removed. Downloads will now go to app-specific storage.';

  @override
  String get customDownloadPathClearedConfirmation =>
      'Custom download path cleared. Downloads will now go to app-specific storage.';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get todoNotifications => 'Todo Notifications';

  @override
  String get todoVibration => 'Vibration';

  @override
  String get quranDownloadNotifications => 'Quran Download Notifications';

  @override
  String get quranVibration => 'Vibration';

  @override
  String get taskReminderTime => 'Task Reminder Time';

  @override
  String get atDeadline => 'At Deadline';

  @override
  String get min5 => '5 min';

  @override
  String get min15 => '15 min';

  @override
  String get min30 => '30 min';

  @override
  String get hr1 => '1 hr';

  @override
  String get hr2 => '2 hr';

  @override
  String get hr3 => '3 hr';

  @override
  String get todoVibrationSubtitle => 'Todo Notifications';

  @override
  String get quranVibrationSubtitle => 'Quran Download Notifications';

  @override
  String get clearPdfCache => 'Clear PDF Cache';

  @override
  String get confirmAction => 'Confirm Action';

  @override
  String get confirmClearCache =>
      'Are you sure you want to clear all internally cached PDF files? This will free up space but require re-downloading.';

  @override
  String cacheClearedItems(Object count) {
    return 'Cleared $count cached PDF files.';
  }

  @override
  String cacheClearFailed(Object error) {
    return 'Failed to clear PDF cache: $error';
  }

  @override
  String get about => 'About';

  @override
  String get appVersion => 'Version';

  @override
  String get appDescription =>
      'Focus Zone is a mobile application designed to help students access and organize their academic materials from Google Drive.';

  @override
  String get madeBy => 'Developed By';

  @override
  String get developerName => 'Belal Mohamed Elnemr';

  @override
  String get developerDetails => 'Communication Engineering Student';

  @override
  String get feedbackCenterSubtitle => 'Share your thoughts and suggestions';

  @override
  String get developerSuggestionsSubtitle =>
      'Here are some features we\'re planning to add:';

  @override
  String get yourOpinion => 'Your Opinion';

  @override
  String get opinionHint => 'Share your thoughts about the app...';

  @override
  String get suggestionHint => 'Suggest new features or improvements...';

  @override
  String get submitOpinion => 'Submit Opinion';

  @override
  String get submitSuggestion => 'Submit Suggestion';

  @override
  String get feedbackSubmitted => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Failed to submit feedback. Please try again.';

  @override
  String get feedbackEmpty => 'Please enter your feedback before submitting.';

  @override
  String get contactInfo => 'Contact Info';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get email => 'Email';

  @override
  String couldNotLaunchUrl(Object url) {
    return 'Could not launch URL: $url';
  }

  @override
  String get collegeName => 'Egyptian Chinese College of Applied Technology';

  @override
  String get eccatIntro =>
      'The Egyptian-Chinese College for Applied Technology at Suez Canal University is a joint initiative with China offering hands-on, industry-focused education in fields like mechatronics, electronics, and communication technology..';

  @override
  String get connectWithUs => 'Connect With Us';

  @override
  String get facebookPage => 'Facebook Page';

  @override
  String get collegeLocation => 'College Location';

  @override
  String get refresh => 'Refresh';

  @override
  String get noFilesFound => 'No files found in this folder.';

  @override
  String get clear => 'Clear';

  @override
  String get notSet => 'Not Set';

  @override
  String get studyButton => 'Study';

  @override
  String get exitButton => 'Exit App';

  @override
  String get todoListButton => 'To-Do List';

  @override
  String get todoListTitle => 'My To-Do List';

  @override
  String get addTask => 'Add Task';

  @override
  String get enterYourTaskHere => 'Enter your task here...';

  @override
  String get noTasksYet => 'No tasks yet! Add one below.';

  @override
  String get taskAdded => 'Task added!';

  @override
  String get taskCompleted => 'Task completed!';

  @override
  String get taskReactivated => 'Task reactivated!';

  @override
  String get taskDeleted => 'Task deleted!';

  @override
  String get emptyTaskError => 'Task cannot be empty.';

  @override
  String get allListsTitle => 'All Lists';

  @override
  String get overdueTasks => 'Overdue';

  @override
  String get todayTasks => 'Today';

  @override
  String get tomorrowTasks => 'Tomorrow';

  @override
  String get thisWeekTasks => 'This Week';

  @override
  String get enterQuickTaskHint => 'Enter Quick Task Here';

  @override
  String get searchTooltip => 'Search';

  @override
  String get newTaskTitle => 'New Task';

  @override
  String get editTaskTitle => 'Edit Task';

  @override
  String get whatIsToBeDone => 'What is to be done?';

  @override
  String get dueDate => 'Due date';

  @override
  String get dueTime => 'Time';

  @override
  String get notifications => 'Notifications';

  @override
  String get repeat => 'Repeat';

  @override
  String get addToLlist => 'Add to List';

  @override
  String get noRepeat => 'No Repeat';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get personal => 'Personal';

  @override
  String get work => 'Work';

  @override
  String get shopping => 'Shopping';

  @override
  String get defaultList => 'Default List';

  @override
  String get saveTask => 'Save Task';

  @override
  String get taskSaved => 'Task saved!';

  @override
  String get searchTasksHint => 'Search tasks...';

  @override
  String get noMatchingTasks => 'No matching tasks found.';

  @override
  String get laterTasks => 'Later';

  @override
  String get noDateTasks => 'No Date';

  @override
  String get completedTasksSection => 'Completed';

  @override
  String get noTasksIllustrationText =>
      'No tasks here! Time to add some study goals or daily reminders.';

  @override
  String get noFilesIllustrationText =>
      'It looks like there are no files in this folder, or you haven\'t selected a subject yet.';

  @override
  String get emptySearchIllustrationText =>
      'No tasks found matching your search. Try a different keyword!';

  @override
  String todayTasksProgress(Object completed, Object total) {
    return 'Today\'s Tasks: $completed of $total completed';
  }

  @override
  String get notificationReminderBody => 'Reminder for:';

  @override
  String everyXDays(Object count) {
    return 'Every $count days';
  }

  @override
  String get weekdays => 'Weekdays';

  @override
  String get weekends => 'Weekends';

  @override
  String lecturesContentNotAvailable(Object subjectName) {
    return 'Lectures content for $subjectName is not yet available.';
  }

  @override
  String get downloadSelected => 'Download Selected';

  @override
  String get viewDetails => 'View Details';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get home => 'Home';

  @override
  String get upComing => 'Up-coming';

  @override
  String get upComingContent => 'Up-coming content will be available soon!';

  @override
  String get dashboardPlaceholder => 'Welcome to your Focus Zone Dashboard!';

  @override
  String get dashboardComingSoon =>
      'Your activity, quick access, and personalized insights will appear here soon.';

  @override
  String errorPageNotFound(Object pageName) {
    return 'Page not found: $pageName';
  }

  @override
  String get errorAttemptedGlobalPush =>
      'Attempted to open content outside the current tab\'s navigation. Please try again from the main tab, or report this issue if it persists.';

  @override
  String get downloadFolderNotFound =>
      'Download folder not found. It might have been moved or deleted.';

  @override
  String get discordProfile => 'Discord Profile';

  @override
  String get githubProfile => 'GitHub Profile';

  @override
  String get recentFiles => 'Recent Files';

  @override
  String get noRecentFiles => 'No recent files to display.';

  @override
  String get quickSettings => 'Quick Settings';

  @override
  String get quickLinks => 'Quick Links';

  @override
  String welcomeUser(Object userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get yourStudyActivity => 'Your Study Activity';

  @override
  String get lastOpened => 'Last Opened';

  @override
  String documentsViewedThisWeek(Object count) {
    return 'Documents viewed this week: $count';
  }

  @override
  String get keepLearning => 'Keep learning, consistency is key!';

  @override
  String get todoSnapshot => 'To-Do Snapshot';

  @override
  String get nextDeadline => 'Next Deadline';

  @override
  String get noUpcomingTasks => 'No upcoming tasks right now!';

  @override
  String dailyTaskProgress(Object completed, Object total) {
    return 'Today\'s Progress: $completed of $total tasks completed';
  }

  @override
  String overdueTasksDashboard(Object count) {
    return 'Overdue Tasks: $count';
  }

  @override
  String get yourStudyZone => 'Your Study Zone';

  @override
  String get exploreSubjects => 'Explore Subjects';

  @override
  String get findNewMaterials => 'Find new materials and lectures.';

  @override
  String get createStudyGoal => 'Create a Study Goal';

  @override
  String get planYourNextTask => 'Plan your next study task or reminder.';

  @override
  String get chooseNewLocation => 'Choose New Location';

  @override
  String get openCurrentLocation => 'Open Current Location';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String downloadLocationUpdated(Object path) {
    return 'Download location updated to: $path';
  }

  @override
  String get downloadLocationReset => 'Download location reset to default.';

  @override
  String get noLocationSelected => 'No location selected.';

  @override
  String failedToSetDownloadLocation(Object error) {
    return 'Failed to set download location: $error';
  }

  @override
  String get permissionDeniedForever =>
      'Storage permission denied permanently. Please grant it from app settings.';

  @override
  String get storagePermissionTitle => 'Storage Permission Required';

  @override
  String get storagePermissionExplanation =>
      'This app needs storage permission to download and save files. Without this permission, you won\'t be able to download files or choose where to save them.';

  @override
  String get storagePermissionNote =>
      'This permission is required for downloading and managing your study materials. You can change this later in your device settings.';

  @override
  String get continue_ => 'Continue';

  @override
  String get zikr => 'Zikr';

  @override
  String get azkar => 'Azkar';

  @override
  String get quran => 'Quran';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get morningRemembrance => 'Morning Remembrance';

  @override
  String get eveningRemembrance => 'Evening Remembrance';

  @override
  String get customZikr => 'Custom Zikr';

  @override
  String get zikrCounter => 'Zikr Counter';

  @override
  String get tapToCount => 'Tap anywhere to count';

  @override
  String azkarTime(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      two: '$count times',
      one: '$count time',
    );
    return '$_temp0';
  }

  @override
  String azkarPage(Object currentPage, Object totalPages) {
    return '$currentPage/$totalPages';
  }

  @override
  String get azkarCompleted => 'MashaAllah, you have completed the Azkar!';

  @override
  String get noSurahsFound => 'No surahs found.';

  @override
  String get failedToLoadSurahs =>
      'Failed to load surahs. Please check your connection.';

  @override
  String get failedToLoadAyahs =>
      'Failed to load ayahs. Please check your connection.';

  @override
  String get failedToLoadPrayerTimes => 'Failed to load prayer times.';

  @override
  String untilNextPrayer(Object prayerName) {
    return 'Until $prayerName prayer';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Sunrise';

  @override
  String get prayerNameDhuhr => 'Dhuhr';

  @override
  String get prayerNameAsr => 'Asr';

  @override
  String get prayerNameMaghrib => 'Maghrib';

  @override
  String get prayerNameIsha => 'Isha';

  @override
  String get prayerNameJumah => 'Jumah';

  @override
  String get dueToday => 'Due Today';

  @override
  String get lessThanOneDay => 'Less than one day';

  @override
  String dueIn(Object timeString) {
    return 'Due in $timeString';
  }

  @override
  String overdueBy(Object timeString) {
    return 'Overdue by $timeString';
  }

  @override
  String year(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String month(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String week(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String day(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get completed => 'Completed';

  @override
  String repeats(Object repeatInterval) {
    return 'Repeats: $repeatInterval';
  }

  @override
  String get sortByDueDateAsc => 'Due Date (Asc)';

  @override
  String get sortByDueDateDesc => 'Due Date (Desc)';

  @override
  String get sortByTitleAsc => 'Title (Asc)';

  @override
  String get sortByTitleDesc => 'Title (Desc)';

  @override
  String get allTasks => 'All Tasks';

  @override
  String get activeTasks => 'Active';

  @override
  String get completedTasks => 'Completed';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get taskOptions => 'Task options';

  @override
  String get editTask => 'Edit task';

  @override
  String get markAsNotDone => 'Mark as not done';

  @override
  String get markAsDone => 'Mark as done';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteTaskConfirmation =>
      'Are you sure you want to delete this task?';

  @override
  String get writeYourZikr => 'Write your Zikr';

  @override
  String get zikrHint => 'E.g., SubhanAllah, Alhamdulillah...';

  @override
  String get errorZikrEmpty => 'Please enter the Zikr text.';

  @override
  String get setRepetitions => 'Set the number of repetitions';

  @override
  String get errorCountEmpty => 'Please enter a count.';

  @override
  String get errorCountZero => 'Count must be greater than zero.';

  @override
  String get start => 'Start';

  @override
  String get myAzkarTitle => 'My Azkar';

  @override
  String get addZikrTitle => 'Add Zikr';

  @override
  String get editZikrTitle => 'Edit Zikr';

  @override
  String streakLabel(Object streakCount) {
    return 'Streak: $streakCount';
  }

  @override
  String get deleteConfirmationTitle => 'Delete Zikr';

  @override
  String get deleteConfirmationContent =>
      'Are you sure you want to permanently delete this Zikr?';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get quickAddTitle => 'Quick Add Suggestions';

  @override
  String get emptyAzkarList =>
      'Your custom Azkar list is empty.\nTap the + button to add a new one.';

  @override
  String get suggestion1 => 'Glory is to Allah';

  @override
  String get suggestion2 => 'Praise be to Allah';

  @override
  String get suggestion3 => 'Allah is the Greatest';

  @override
  String get suggestion4 => 'I seek the forgiveness of Allah';

  @override
  String dailyCountLabel(Object count) {
    return 'Completed today: $count';
  }

  @override
  String get quickCounterTitle => 'Quick Counter';

  @override
  String get reset => 'Reset';

  @override
  String get quranTitle => 'Quran';

  @override
  String get quranSubtitle => 'The Holy Quran';

  @override
  String get quranDescription =>
      'Read, download, and manage the full Quran and Juzs.';

  @override
  String get browseJuzs => 'Browse Juzs';

  @override
  String get browseJuzsSubtitle => 'View and download individual Juzs';

  @override
  String get viewFullQuran => 'View Full Quran';

  @override
  String get pauseDownload => 'Pause Download';

  @override
  String get resumeDownload => 'Resume Download';

  @override
  String get downloadFullQuran => 'Download Full Quran';

  @override
  String get fullQuranReady => 'Full Quran is ready to view!';

  @override
  String pagesCount(Object downloaded, Object progress, Object total) {
    return '$downloaded/$total pages ($progress%)';
  }

  @override
  String get loading => 'Loading...';

  @override
  String completeQuran(Object pages, Object size) {
    return 'Complete Quran ($size, $pages pages)';
  }

  @override
  String get pausingPleaseWait => 'Pausing, please wait...';

  @override
  String get cancellingPleaseWait => 'Cancelling, please wait...';

  @override
  String get deletingPleaseWait => 'Deleting, please wait...';

  @override
  String get deleteFullQuran => 'Delete Full Quran';

  @override
  String get freeUpStorage => 'Free up storage space';

  @override
  String get downloadIncomplete => 'Download incomplete';

  @override
  String pagesDownloaded(Object downloaded, Object total) {
    return '$downloaded of $total pages downloaded';
  }

  @override
  String get anErrorOccurred => 'An error occurred during download.';

  @override
  String get stillUnderDevelopment =>
      'This feature is still under development.';

  @override
  String downloadFullQuranDialog(Object pages, Object size) {
    return 'The full Quran is approximately $size and contains $pages pages. This may take some time to download. Continue? KEEP INTERNET CONNECTION ON';
  }

  @override
  String get areYouSureDeleteQuran =>
      'Are you sure you want to delete the full Quran? This will free up storage space but you will need to download it again to view it.';

  @override
  String get fullQuranDeleted => 'Full Quran deleted successfully.';

  @override
  String get downloadControls => 'Download Controls';

  @override
  String get progress => 'Progress';

  @override
  String get current => 'Current file:';

  @override
  String get pause => 'Pause';

  @override
  String get deleteDownloadedFiles => 'Delete Downloaded Files';

  @override
  String get juzListTitle => 'Juz List';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String juzNotDownloaded(Object juz) {
    return 'Juz $juz is not downloaded.';
  }

  @override
  String get juzProperties => 'Juz Properties';

  @override
  String get fileCount => 'File count';

  @override
  String get totalSize => 'Total size';

  @override
  String get close => 'Close';

  @override
  String get couldNotLoadProperties => 'Could not load properties.';

  @override
  String get pendingPausing => 'Pausing...';

  @override
  String get pendingCancelling => 'Cancelling...';

  @override
  String get pendingDeleting => 'Deleting...';

  @override
  String get pagesLabel => 'pages';

  @override
  String get surahListTitle => 'Surah List';

  @override
  String get surahLoadError => 'Error loading Surahs';

  @override
  String get noSurahData => 'No Surah data available.';

  @override
  String get ayahCountLabel => 'Ayahs';

  @override
  String get makkiType => 'Makki';

  @override
  String get madaniType => 'Madani';

  @override
  String get readingSettings => 'Reading Settings';

  @override
  String get nightMode => 'Night Mode';

  @override
  String get nightModeSubtitle => 'Dark background for low light';

  @override
  String get scrollDirection => 'Scroll Direction';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get readingTimer => 'Reading Timer';

  @override
  String timerRunning(Object time) {
    return 'Running: $time';
  }

  @override
  String get timerNotRunning => 'Not running';

  @override
  String get autoScroll => 'Auto Scroll';

  @override
  String autoScrollEnabled(Object seconds) {
    return 'Enabled (${seconds}s/page)';
  }

  @override
  String get autoScrollDisabled => 'Disabled';

  @override
  String get scrollSpeed => 'Scroll Speed';

  @override
  String secondsPerPage(Object seconds) {
    return '$seconds seconds per page';
  }

  @override
  String get minTimeToCountPage => 'Minimum Time to Count Page as Read';

  @override
  String secondsLabel(Object seconds) {
    return '$seconds seconds';
  }

  @override
  String get readingAnalytics => 'Reading Analytics';

  @override
  String get streaks => 'Streaks';

  @override
  String get dayStreak => 'Day Streak';

  @override
  String get today => 'Today';

  @override
  String get goals => 'Goals';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String goalProgress(Object progress) {
    return '$progress%';
  }

  @override
  String minutesGoalProgress(Object goal, Object minutes) {
    return '$minutes / $goal minutes';
  }

  @override
  String get weeklyGoal => 'Weekly Goal';

  @override
  String pagesGoalProgress(Object goal, Object pages) {
    return '$pages / $goal pages';
  }

  @override
  String get noInsights => 'No insights yet. Start reading to see tips!';

  @override
  String get noReadingSessions => 'No reading sessions yet.';

  @override
  String get startStreakTip => 'Start a streak by reading every day!';

  @override
  String totalTimeReading(Object seconds) {
    return 'Total time reading: $seconds seconds';
  }

  @override
  String get insights => 'Insights';

  @override
  String get weekendReadingTip => 'You read more on weekends!';

  @override
  String get weekdayReadingTip => 'You read more on weekdays!';

  @override
  String amazingStreakTip(Object streak) {
    return 'Amazing! You have a $streak-day streak!';
  }

  @override
  String greatStreakTip(Object streak) {
    return 'Great! Keep your $streak-day streak going!';
  }

  @override
  String get weeklyGoalAchievedTip => 'You reached your weekly goal! 🎉';

  @override
  String get closeWeeklyGoalTip => 'You are close to your weekly goal!';

  @override
  String dailyGoalMetTip(Object days) {
    return 'You met your daily goal $days times this week!';
  }

  @override
  String get sessionInsights => 'Session Insights';

  @override
  String avgTimePerPage(Object time) {
    return 'Average time per page: $time seconds';
  }

  @override
  String mostReadPage(Object page, Object time) {
    return 'Most read page: $page ($time seconds)';
  }

  @override
  String leastReadPage(Object page, Object time) {
    return 'Least read page: $page ($time seconds)';
  }

  @override
  String uniquePagesRead(Object pages) {
    return 'Unique pages read: $pages';
  }

  @override
  String get noSessionData =>
      'No session data yet. Start a session to see insights.';

  @override
  String get history => 'History';

  @override
  String get pagesReadLast7Days => 'Pages Read (Last 7 Days)';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String get fullQuran => 'Full Quran';

  @override
  String juz(Object juz) {
    return 'Juz $juz';
  }

  @override
  String get removeBookmark => 'Remove Bookmark';

  @override
  String get bookmarkPage => 'Bookmark Page';

  @override
  String get surahList => 'Surah List';

  @override
  String get more => 'More';

  @override
  String get noImagesFoundForThisJuz => 'No images found for this Juz.';

  @override
  String get autoScrolling => 'Auto-scrolling';

  @override
  String get readingGoals => 'Reading Goals';

  @override
  String get setDailyGoal => 'Set Daily Goal';

  @override
  String get viewDownloadedJuzs => 'View Downloaded Juzs';

  @override
  String get switchJuz => 'Switch Juz';

  @override
  String get downloadedJuzsTitle => 'Downloaded Juzs';

  @override
  String juzsDownloaded(Object downloaded, Object total) {
    return '$downloaded/$total Juzs downloaded';
  }

  @override
  String get enterYourInfo =>
      'Enter your info (optional) to help us improve communication.';

  @override
  String get continueButton => 'Continue';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get skip => 'Skip';

  @override
  String get updateYourInfo => 'Update your info';

  @override
  String get like => 'Like';

  @override
  String get dislike => 'Dislike';

  @override
  String get addComment => 'Add comment';

  @override
  String get recentComments => 'Recent comments';

  @override
  String get prayerReminderTime => 'Prayer reminder time';

  @override
  String get prayerVibration => 'Vibration';

  @override
  String get prayerVibrationSubtitle => 'Prayer Notifications';

  @override
  String get globalNotificationsDisabled =>
      'Global todo notifications are disabled';

  @override
  String get prayerNotifications => 'Prayer Time Notifications';

  @override
  String prayerNotificationBody(Object prayerName) {
    return '$prayerName prayer is in 1 minute';
  }

  @override
  String prayerNotificationBodyAdvance(Object prayerName, Object timeText) {
    return '$prayerName prayer is in $timeText';
  }

  @override
  String get atPrayerTime => 'At prayer time';

  @override
  String inMinutes(Object count) {
    return '$count minutes';
  }

  @override
  String inHours(Object count) {
    return '$count hours';
  }

  @override
  String get inOneMinute => '1 minute';

  @override
  String get inOneHour => '1 hour';
}
