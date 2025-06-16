// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ECCAT Study Station';

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
  String get errorDownloadCancelled => 'Download cancelled.';

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
      'ECCAT Study Station is a mobile application designed to help students access and organize their academic materials from Google Drive.';

  @override
  String get madeBy => 'Developed By';

  @override
  String get developerName => 'Belal Mohamed Elnemr';

  @override
  String get developerDetails =>
      'Communication and Electronics Engineering Student';

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
      'The Egyptian Chinese College of Applied Technology (ECCAT) is a unique educational institution fostering practical and technological skills.';

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
  String get dashboardPlaceholder => 'Welcome to your Study Station Dashboard!';

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
  String get permissionDeniedAllFilesAccess =>
      'All files access permission denied. Please grant it manually from app settings for full functionality.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get allFilesAccessRationale =>
      'To enable downloading and managing PDF files, ECCAT Study Station needs \'All files access\' permission. This allows the app to save and open files in your chosen download location.';

  @override
  String get permissionNeeded => 'Permission Needed';

  @override
  String couldNotOpenChosenFolder(Object error) {
    return 'Could not open chosen folder: $error. Trying app\'s default.';
  }

  @override
  String get couldNotOpenDefaultFolder =>
      'Could not open app\'s default download folder.';
}
