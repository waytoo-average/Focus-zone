// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get feedbackCenter => 'مركز التقييم';

  @override
  String get sendFeedback => 'إرسال ملاحظة';

  @override
  String get sendFeedbackDesc => 'شاركنا أفكارك أو المشاكل التي تواجهك.';

  @override
  String get yourSuggestions => 'اقتراحاتك';

  @override
  String get yourSuggestionsDesc => 'عرض وإدارة ملاحظاتك المرسلة.';

  @override
  String get developerSuggestions => 'اقتراحات المطور';

  @override
  String get developerSuggestionsDesc =>
      'شاهد ما يعمل عليه المطور وصوّت أو أضف تعليقًا.';

  @override
  String get userInfo => 'معلوماتك';

  @override
  String get userInfoDesc =>
      'يمكنك إدخال اسمك ورقمك لمساعدتنا في التواصل معك (اختياري).';

  @override
  String get feedbackHint => 'اكتب ملاحظتك هنا...';

  @override
  String get submit => 'إرسال';

  @override
  String get appTitle => 'منطقة التركيز';

  @override
  String get settings => 'الإعدادات';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة!';

  @override
  String get notAvailableNow =>
      'المحتوى غير متاح في الوقت الحالي. يرجى التحقق لاحقًا!';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get unnamedItem => 'عنصر بدون اسم';

  @override
  String get loadingLocalizations => 'جاري تحميل اللغات...';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String signedInAs(Object userName) {
    return 'تم تسجيل الدخول باسم $userName';
  }

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بحساب جوجل';

  @override
  String get notSignedInClientNotAvailable =>
      'لم يتم تسجيل الدخول أو العميل غير متاح. يرجى تسجيل الدخول.';

  @override
  String get maxUserLimitReached =>
      'تم الوصول للحد الأقصى للمستخدمين. يمكنك الاستمرار في استخدام ميزات التطبيق الأخرى بدون تسجيل الدخول. يرجى الانتظار للتحديثات المستقبلية.';

  @override
  String get firstGrade => 'الفرقة الأولى';

  @override
  String get secondGrade => 'الفرقة الثانية';

  @override
  String get thirdGrade => 'الفرقة الثالثة';

  @override
  String get fourthGrade => 'الفرقة الرابعة';

  @override
  String get communication => 'قسم الاتصالات';

  @override
  String get electronics => 'قسم الإلكترونيات';

  @override
  String get mechatronics => 'قسم الميكاترونكس';

  @override
  String get currentYear => 'العام الحالي';

  @override
  String get lastYear => 'العام الماضي';

  @override
  String get semester1 => 'الفصل الدراسي الأول';

  @override
  String get semester2 => 'الفصل الدراسي الثاني';

  @override
  String get lectures => 'المحاضرات';

  @override
  String get explanation => 'الشرح';

  @override
  String get summaries => 'الملخصات';

  @override
  String get lectureContent => 'محتوى المحاضرة';

  @override
  String get errorMissingContext =>
      'سياق أكاديمي مفقود. يرجى التنقل من الشاشة الرئيسية.';

  @override
  String get errorMissingSubjectDetails =>
      'تفاصيل الموضوع مفقودة. لا يمكن عرض المحتوى.';

  @override
  String explanationContentNotAvailable(Object subjectName) {
    return 'محتوى الشرح لـ $subjectName غير متاح بعد.';
  }

  @override
  String summariesContentNotAvailable(Object subjectName) {
    return 'الملخصات لـ $subjectName غير متاحة بعد.';
  }

  @override
  String get errorMissingFolderId => 'خطأ: معرف المجلد مفقود.';

  @override
  String failedToLoadFiles(Object error) {
    return 'فشل تحميل الملفات: $error';
  }

  @override
  String get errorNoUrlProvided => 'خطأ: لم يتم توفير عنوان URL.';

  @override
  String failedToLoadPdf(Object error) {
    return 'فشل تحميل ملف PDF: $error';
  }

  @override
  String get errorDownloadCancelled => 'تم إلغاء التنزيل.';

  @override
  String get errorFileIdMissing => 'خطأ: معرف الملف مفقود.';

  @override
  String get downloading => 'جار التحميل';

  @override
  String errorLoadingContent(Object description) {
    return 'خطأ في تحميل المحتوى: $description';
  }

  @override
  String get cannotOpenFileType => 'لا يمكن فتح هذا النوع من الملفات مباشرة.';

  @override
  String downloadStarted(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تنزيلات',
      one: '1 تنزيل',
    );
    return 'بدء $_temp0...';
  }

  @override
  String downloadCompleted(Object fileName) {
    return 'اكتمل التنزيل: $fileName';
  }

  @override
  String get openFile => 'فتح الملف';

  @override
  String downloadFailed(Object error, Object fileName) {
    return 'فشل تنزيل $fileName: $error';
  }

  @override
  String downloadCancelled(Object fileName) {
    return 'تم إلغاء التنزيل لـ: $fileName';
  }

  @override
  String get allDownloadsCompleted => 'اكتملت جميع التنزيلات!';

  @override
  String get openFolder => 'فتح المجلد';

  @override
  String couldNotOpenFolder(Object error) {
    return 'تعذر فتح المجلد: $error';
  }

  @override
  String get downloadInProgressPleaseWait =>
      'التنزيل قيد التقدم. يرجى الانتظار.';

  @override
  String get cancelSelection => 'إلغاء التحديد';

  @override
  String itemsSelected(Object count) {
    return '$count عناصر محددة';
  }

  @override
  String get detailsAction => 'التفاصيل';

  @override
  String get downloadAction => 'تنزيل';

  @override
  String get noItemSelectedForDetails =>
      'يرجى تحديد عنصر واحد فقط لعرض التفاصيل.';

  @override
  String get fileDetails => 'تفاصيل الملف';

  @override
  String get fileNameField => 'اسم الملف';

  @override
  String get fileTypeField => 'نوع الملف';

  @override
  String get fileSizeField => 'حجم الملف';

  @override
  String get lastModifiedField => 'آخر تعديل';

  @override
  String get aboutCollege => 'عن الكلية';

  @override
  String get chooseLanguage => 'اختيار اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get chooseTheme => 'اختيار المظهر';

  @override
  String get lightTheme => 'المظهر الفاتح';

  @override
  String get darkTheme => 'المظهر الداكن';

  @override
  String get systemDefault => 'افتراضي النظام';

  @override
  String get downloadLocation => 'موقع التنزيل';

  @override
  String filesWillBeDownloadedTo(Object path) {
    return 'سيتم تنزيل الملفات إلى: $path';
  }

  @override
  String get permissionDeniedStorage =>
      'تم رفض إذن التخزين. لا يمكن اختيار موقع التنزيل.';

  @override
  String get permissionDenied => 'تم رفض الإذن. لا يمكن الوصول إلى التخزين.';

  @override
  String get noDirectorySelected => 'لم يتم تحديد دليل.';

  @override
  String failedToCreateDirectory(Object error) {
    return 'فشل إنشاء مجلد التنزيل: $error';
  }

  @override
  String failedToChooseDownloadPath(Object error) {
    return 'فشل في اختيار مسار التنزيل: $error';
  }

  @override
  String downloadPathSetTo(Object path) {
    return 'تم تعيين مسار التنزيل إلى: $path';
  }

  @override
  String downloadPathSetToFallback(Object path) {
    return 'تم تعيين مسار التنزيل إلى: $path (العودة إلى التخزين الخاص بالتطبيق)';
  }

  @override
  String selectedDownloadPath(Object path) {
    return 'لقد اخترت: $path';
  }

  @override
  String downloadPathWarning(Object actualPath) {
    return 'تحذير: بسبب قيود أندرويد، قد يتم تنزيل الملفات إلى التخزين الخاص بالتطبيق: $actualPath';
  }

  @override
  String get appSpecificDownloadPath => 'خاص بالتطبيق';

  @override
  String get clearCustomDownloadPathOption => 'مسح مسار التنزيل المخصص';

  @override
  String get confirmClearCustomDownloadPath =>
      'هل أنت متأكد من أنك تريد مسح مسار التنزيل المخصص؟ ستعود التنزيلات إلى التخزين الخاص بالتطبيق.';

  @override
  String get customDownloadPathCleared =>
      'تمت إزالة إعداد مسار التنزيل المخصص. ستذهب التنزيلات الآن إلى التخزين الخاص بالتطبيق.';

  @override
  String get customDownloadPathClearedConfirmation =>
      'تم مسح مسار التنزيل المخصص. ستذهب التنزيلات الآن إلى التخزين الخاص بالتطبيق.';

  @override
  String get notificationSettingsTitle => 'إعدادات الإشعارات';

  @override
  String get todoNotifications => 'إشعارات المهام';

  @override
  String get todoVibration => 'اهتزاز';

  @override
  String get quranDownloadNotifications => 'إشعارات تحميل القرآن';

  @override
  String get quranVibration => 'اهتزاز';

  @override
  String get taskReminderTime => 'وقت تذكير المهمة';

  @override
  String get atDeadline => 'عند الموعد النهائي';

  @override
  String get min5 => 'قبل 5 دقائق';

  @override
  String get min15 => 'قبل 15 دقيقة';

  @override
  String get min30 => 'قبل 30 دقيقة';

  @override
  String get hr1 => 'قبل ساعة';

  @override
  String get hr2 => 'قبل ساعتين';

  @override
  String get hr3 => 'قبل 3 ساعات';

  @override
  String get todoVibrationSubtitle => 'إشعارات المهام';

  @override
  String get quranVibrationSubtitle => 'إشعارات تحميل القرآن';

  @override
  String get clearPdfCache => 'مسح ذاكرة التخزين المؤقت لملفات PDF';

  @override
  String get confirmAction => 'تأكيد الإجراء';

  @override
  String get confirmClearCache =>
      'هل أنت متأكد أنك تريد مسح جميع ملفات PDF المخزنة مؤقتًا داخليًا؟ سيؤدي ذلك إلى تحرير مساحة ولكن يتطلب إعادة التنزيل.';

  @override
  String cacheClearedItems(Object count) {
    return 'تم مسح $count ملف PDF مخزنة مؤقتًا.';
  }

  @override
  String cacheClearFailed(Object error) {
    return 'فشل مسح ذاكرة التخزين المؤقت لملفات PDF: $error';
  }

  @override
  String get about => 'حول التطبيق';

  @override
  String get appVersion => 'الإصدار';

  @override
  String get appDescription =>
      'منطقة التركيز هو تطبيق جوال مصمم لمساعدة الطلاب على الوصول إلى موادهم الأكاديمية وتنظيمها من جوجل درايف.';

  @override
  String get madeBy => 'تم التطوير بواسطة';

  @override
  String get developerName => 'بلال محمد النمر';

  @override
  String get developerDetails => 'طالب هندسة اتصالات وإلكترونيات';

  @override
  String get feedbackCenterSubtitle => 'شارك أفكارك واقتراحاتك';

  @override
  String get developerSuggestionsSubtitle =>
      'إليك بعض الميزات التي نخطط لإضافتها:';

  @override
  String get yourOpinion => 'رأيك';

  @override
  String get opinionHint => 'شارك أفكارك حول التطبيق...';

  @override
  String get suggestionHint => 'اقترح ميزات جديدة أو تحسينات...';

  @override
  String get submitOpinion => 'إرسال الرأي';

  @override
  String get submitSuggestion => 'إرسال الاقتراح';

  @override
  String get feedbackSubmitted => 'شكراً لك على تقييمك!';

  @override
  String get feedbackError => 'فشل في إرسال التقييم. يرجى المحاولة مرة أخرى.';

  @override
  String get feedbackEmpty => 'يرجى إدخال تقييمك قبل الإرسال.';

  @override
  String get contactInfo => 'معلومات الاتصال';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String couldNotLaunchUrl(Object url) {
    return 'تعذر فتح الرابط: $url';
  }

  @override
  String get collegeName => 'الكلية المصرية الصينية للتكنولوجيا التطبيقية';

  @override
  String get eccatIntro =>
      'الكلية المصرية الصينية للتكنولوجيا التطبيقية بجامعة قناة السويس هي مبادرة مشتركة مع الصين تقدم تعليماً عملياً يركز على الصناعة في مجالات مثل الميكاترونيات والإلكترونيات وتكنولوجيا الاتصالات.';

  @override
  String get connectWithUs => 'تواصل معنا';

  @override
  String get facebookPage => 'صفحة الفيسبوك';

  @override
  String get collegeLocation => 'موقع الكلية';

  @override
  String get refresh => 'تحديث';

  @override
  String get noFilesFound => 'لم يتم العثور على ملفات في هذا المجلد.';

  @override
  String get clear => 'مسح';

  @override
  String get notSet => 'غير محدد';

  @override
  String get studyButton => 'دراسة';

  @override
  String get exitButton => 'الخروج من التطبيق';

  @override
  String get todoListButton => 'قائمة المهام';

  @override
  String get todoListTitle => 'قائمة المهام';

  @override
  String get addTask => 'إضافة مهمة';

  @override
  String get enterYourTaskHere => 'أدخل مهمتك هنا...';

  @override
  String get noTasksYet => 'لا توجد مهام بعد! أضف واحدة أدناه.';

  @override
  String get taskAdded => 'تمت إضافة المهمة!';

  @override
  String get taskCompleted => 'تم إكمال المهمة!';

  @override
  String get taskReactivated => 'تم إعادة تنشيط المهمة!';

  @override
  String get taskDeleted => 'تم حذف المهمة!';

  @override
  String get emptyTaskError => 'لا يمكن أن تكون المهمة فارغة.';

  @override
  String get allListsTitle => 'جميع القوائم';

  @override
  String get overdueTasks => 'مهام متأخرة';

  @override
  String get todayTasks => 'اليوم';

  @override
  String get tomorrowTasks => 'غداً';

  @override
  String get thisWeekTasks => 'هذا الأسبوع';

  @override
  String get enterQuickTaskHint => 'أدخل مهمة سريعة هنا';

  @override
  String get searchTooltip => 'بحث';

  @override
  String get newTaskTitle => 'مهمة جديدة';

  @override
  String get editTaskTitle => 'تعديل المهمة';

  @override
  String get whatIsToBeDone => 'ما الذي يجب عمله؟';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get dueTime => 'الوقت';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get repeat => 'تكرار';

  @override
  String get addToLlist => 'إضافة إلى قائمة';

  @override
  String get noRepeat => 'لا تكرار';

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get personal => 'شخصي';

  @override
  String get work => 'عمل';

  @override
  String get shopping => 'تسوق';

  @override
  String get defaultList => 'قائمة افتراضية';

  @override
  String get saveTask => 'حفظ المهمة';

  @override
  String get taskSaved => 'تم حفظ المهمة!';

  @override
  String get searchTasksHint => 'البحث عن المهام.';

  @override
  String get noMatchingTasks => 'لم يتم العثور على مهام مطابقة.';

  @override
  String get laterTasks => 'لاحقاً';

  @override
  String get noDateTasks => 'لا يوجد تاريخ';

  @override
  String get completedTasksSection => 'المهام المكتملة';

  @override
  String get noTasksIllustrationText =>
      'لا توجد مهام هنا! حان الوقت لإضافة بعض أهداف الدراسة أو التذكيرات اليومية.';

  @override
  String get noFilesIllustrationText =>
      'يبدو أنه لا توجد ملفات في هذا المجلد، أو لم تختر مادة بعد.';

  @override
  String get emptySearchIllustrationText =>
      'لم يتم العثور على مهام مطابقة لبحثك. جرب كلمة مفتاحية مختلفة!';

  @override
  String todayTasksProgress(Object completed, Object total) {
    return 'مهام اليوم: $completed من $total اكتملت';
  }

  @override
  String get notificationReminderBody => 'تذكير بـ:';

  @override
  String everyXDays(Object count) {
    return 'كل $count أيام';
  }

  @override
  String get weekdays => 'أيام الأسبوع';

  @override
  String get weekends => 'عطلات نهاية الأسبوع';

  @override
  String lecturesContentNotAvailable(Object subjectName) {
    return 'محتوى المحاضرات لـ $subjectName غير متاح بعد.';
  }

  @override
  String get downloadSelected => 'تنزيل المحدد';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get enableNotifications => 'تمكين الإشعارات';

  @override
  String get home => 'الرئيسية';

  @override
  String get upComing => 'قريباً';

  @override
  String get upComingContent => 'المحتوى القادم سيكون متاحاً قريباً!';

  @override
  String get dashboardPlaceholder => 'مرحباً بك في لوحة التحكم الخاصة بك!';

  @override
  String get dashboardComingSoon =>
      'سيظهر نشاطك والوصول السريع والإحصائيات المخصصة هنا قريباً.';

  @override
  String errorPageNotFound(Object pageName) {
    return 'الصفحة غير موجودة: $pageName';
  }

  @override
  String get errorAttemptedGlobalPush =>
      'تمت محاولة فتح المحتوى خارج التنقل الحالي للعلامة التبويب. يرجى المحاولة مرة أخرى من علامة التبويب الرئيسية، أو الإبلاغ عن هذه المشكلة إذا استمرت.';

  @override
  String get downloadFolderNotFound =>
      'مجلد التنزيلات غير موجود. ربما تم نقله أو حذفه.';

  @override
  String get discordProfile => 'ملف Discord الشخصي';

  @override
  String get githubProfile => 'ملف GitHub الشخصي';

  @override
  String get recentFiles => 'الملفات الأخيرة';

  @override
  String get noRecentFiles => 'لا توجد ملفات حديثة لعرضها.';

  @override
  String get quickSettings => 'الإعدادات السريعة';

  @override
  String get quickLinks => 'روابط سريعة';

  @override
  String welcomeUser(Object userName) {
    return 'أهلاً بك، $userName!';
  }

  @override
  String get yourStudyActivity => 'نشاطك الدراسي';

  @override
  String get lastOpened => 'آخر فتح';

  @override
  String documentsViewedThisWeek(Object count) {
    return 'المستندات التي تمت مشاهدتها هذا الأسبوع: $count';
  }

  @override
  String get keepLearning => 'استمر في التعلم، الاتساق هو المفتاح!';

  @override
  String get todoSnapshot => 'نظرة عامة على المهام';

  @override
  String get nextDeadline => 'الموعد النهائي القادم';

  @override
  String get noUpcomingTasks => 'لا توجد مهام قادمة حاليًا!';

  @override
  String dailyTaskProgress(Object completed, Object total) {
    return 'تقدم اليوم: تم إكمال $completed من $total مهمة';
  }

  @override
  String overdueTasksDashboard(Object count) {
    return 'المهام المتأخرة: $count';
  }

  @override
  String get yourStudyZone => 'منطقة دراستك';

  @override
  String get exploreSubjects => 'استكشاف المواد';

  @override
  String get findNewMaterials => 'ابحث عن مواد ومحاضرات جديدة.';

  @override
  String get createStudyGoal => 'إنشاء هدف دراسي';

  @override
  String get planYourNextTask => 'خطط لمهمتك الدراسية أو تذكيرك التالي.';

  @override
  String get chooseNewLocation => 'اختيار موقع جديد';

  @override
  String get openCurrentLocation => 'فتح الموقع الحالي';

  @override
  String get resetToDefault => 'إعادة تعيين إلى الافتراضي';

  @override
  String downloadLocationUpdated(Object path) {
    return 'تم تحديث موقع التنزيل إلى: $path';
  }

  @override
  String get downloadLocationReset =>
      'تمت إعادة تعيين موقع التنزيل إلى الافتراضي.';

  @override
  String get noLocationSelected => 'لم يتم اختيار موقع.';

  @override
  String failedToSetDownloadLocation(Object error) {
    return 'فشل تعيين موقع التنزيل: $error';
  }

  @override
  String get permissionDeniedForever =>
      'تم رفض إذن التخزين بشكل دائم. يرجى منحه من إعدادات التطبيق.';

  @override
  String get storagePermissionTitle => 'مطلوب إذن التخزين';

  @override
  String get storagePermissionExplanation =>
      'يحتاج هذا التطبيق إلى إذن التخزين لتنزيل وحفظ الملفات. بدون هذا الإذن، لن تتمكن من تنزيل الملفات أو اختيار مكان حفظها.';

  @override
  String get storagePermissionNote =>
      'هذا الإذن مطلوب لتنزيل وإدارة المواد الدراسية الخاصة بك. يمكنك تغيير هذا لاحقًا في إعدادات جهازك.';

  @override
  String get continue_ => 'متابعة';

  @override
  String get zikr => 'الأذكار';

  @override
  String get azkar => 'أذكار';

  @override
  String get quran => 'قرآن';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get morningRemembrance => 'أذكار الصباح';

  @override
  String get eveningRemembrance => 'أذكار المساء';

  @override
  String get customZikr => 'سبحة خاصة';

  @override
  String get zikrCounter => 'عداد الأذكار';

  @override
  String get tapToCount => 'انقر في أي مكان للعد';

  @override
  String azkarTime(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرات',
      two: '$count مرتان',
      one: '$count مرة',
    );
    return '$_temp0';
  }

  @override
  String azkarPage(Object currentPage, Object totalPages) {
    return '$currentPage/$totalPages';
  }

  @override
  String get azkarCompleted => 'ما شاء الله، لقد أتممت الأذكار!';

  @override
  String get noSurahsFound => 'لم يتم العثور على سور.';

  @override
  String get failedToLoadSurahs => 'فشل تحميل السور. يرجى التحقق من اتصالك.';

  @override
  String get failedToLoadAyahs => 'فشل تحميل الآيات. يرجى التحقق من اتصالك.';

  @override
  String get failedToLoadPrayerTimes => 'فشل في تحميل أوقات الصلاة.';

  @override
  String untilNextPrayer(Object prayerName) {
    return 'حتى صلاة $prayerName';
  }

  @override
  String get prayerNameFajr => 'الفجر';

  @override
  String get prayerNameSunrise => 'الشروق';

  @override
  String get prayerNameDhuhr => 'الظهر';

  @override
  String get prayerNameAsr => 'العصر';

  @override
  String get prayerNameMaghrib => 'المغرب';

  @override
  String get prayerNameIsha => 'العشاء';

  @override
  String get prayerNameJumah => 'جمعة';

  @override
  String get dueToday => 'مستحق اليوم';

  @override
  String get lessThanOneDay => 'أقل من يوم';

  @override
  String dueIn(Object timeString) {
    return 'مستحق خلال $timeString';
  }

  @override
  String overdueBy(Object timeString) {
    return 'متأخر منذ $timeString';
  }

  @override
  String year(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سنوات',
      one: 'سنة',
    );
    return '$_temp0';
  }

  @override
  String month(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'شهور',
      one: 'شهر',
    );
    return '$_temp0';
  }

  @override
  String week(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أسابيع',
      one: 'أسبوع',
    );
    return '$_temp0';
  }

  @override
  String day(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get completed => 'مكتمل';

  @override
  String repeats(Object repeatInterval) {
    return 'تكرار: $repeatInterval';
  }

  @override
  String get sortByDueDateAsc => 'تاريخ الاستحقاق (تصاعدي)';

  @override
  String get sortByDueDateDesc => 'تاريخ الاستحقاق (تنازلي)';

  @override
  String get sortByTitleAsc => 'العنوان (تصاعدي)';

  @override
  String get sortByTitleDesc => 'العنوان (تنازلي)';

  @override
  String get allTasks => 'كل المهام';

  @override
  String get activeTasks => 'نشطة';

  @override
  String get completedTasks => 'مكتملة';

  @override
  String get edit => 'تعديل';

  @override
  String get done => 'تم';

  @override
  String get undo => 'تراجع';

  @override
  String get taskOptions => 'خيارات المهمة';

  @override
  String get editTask => 'تعديل المهمة';

  @override
  String get markAsNotDone => 'وضع كغير مكتملة';

  @override
  String get markAsDone => 'وضع كمكتملة';

  @override
  String get deleteTask => 'حذف المهمة';

  @override
  String get deleteTaskConfirmation => 'هل أنت متأكد أنك تريد حذف هذه المهمة؟';

  @override
  String get writeYourZikr => 'اكتب الذكر الخاص بك';

  @override
  String get zikrHint => 'مثال: سبحان الله، الحمد لله...';

  @override
  String get errorZikrEmpty => 'الرجاء إدخال نص الذكر.';

  @override
  String get setRepetitions => 'حدد عدد التكرارات';

  @override
  String get errorCountEmpty => 'الرجاء إدخال عدد.';

  @override
  String get errorCountZero => 'يجب أن يكون العدد أكبر من صفر.';

  @override
  String get start => 'ابدأ';

  @override
  String get myAzkarTitle => 'أذكاري';

  @override
  String get addZikrTitle => 'إضافة ذكر';

  @override
  String get editZikrTitle => 'تعديل الذكر';

  @override
  String streakLabel(Object streakCount) {
    return 'متتالية: $streakCount';
  }

  @override
  String get deleteConfirmationTitle => 'حذف الذكر';

  @override
  String get deleteConfirmationContent =>
      'هل أنت متأكد من رغبتك في حذف هذا الذكر نهائياً؟';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get quickAddTitle => 'إضافات سريعة مقترحة';

  @override
  String get emptyAzkarList =>
      'قائمة أذكارك فارغة.\nاضغط على زر + لإضافة ذكر جديد.';

  @override
  String get suggestion1 => 'سبحان الله';

  @override
  String get suggestion2 => 'الحمد لله';

  @override
  String get suggestion3 => 'الله أكبر';

  @override
  String get suggestion4 => 'أستغفر الله';

  @override
  String dailyCountLabel(Object count) {
    return 'مرات الإنجاز اليوم: $count';
  }

  @override
  String get quickCounterTitle => 'عداد سريع';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get quranTitle => 'القرآن الكريم';

  @override
  String get quranSubtitle => 'القرآن الكريم';

  @override
  String get quranDescription => 'اقرأ، نزّل، وادِر القرآن الكريم والأجزاء.';

  @override
  String get browseJuzs => 'تصفح الأجزاء';

  @override
  String get browseJuzsSubtitle => 'عرض وتنزيل الأجزاء الفردية';

  @override
  String get viewFullQuran => 'عرض القرآن الكامل';

  @override
  String get pauseDownload => 'إيقاف التنزيل مؤقتًا';

  @override
  String get resumeDownload => 'استئناف التنزيل';

  @override
  String get downloadFullQuran => 'تنزيل القرآن الكامل';

  @override
  String get fullQuranReady => 'القرآن الكامل جاهز للعرض!';

  @override
  String pagesCount(Object downloaded, Object progress, Object total) {
    return '$downloaded/$total صفحة ($progress%)';
  }

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String completeQuran(Object pages, Object size) {
    return 'القرآن الكامل ($size، $pages صفحة)';
  }

  @override
  String get pausingPleaseWait => 'يتم الإيقاف المؤقت، يرجى الانتظار...';

  @override
  String get cancellingPleaseWait => 'يتم الإلغاء، يرجى الانتظار...';

  @override
  String get deletingPleaseWait => 'يتم الحذف، يرجى الانتظار...';

  @override
  String get deleteFullQuran => 'حذف القرآن الكامل';

  @override
  String get freeUpStorage => 'توفير مساحة تخزين';

  @override
  String get downloadIncomplete => 'التنزيل غير مكتمل';

  @override
  String pagesDownloaded(Object downloaded, Object total) {
    return 'تم تنزيل $downloaded من $total صفحة';
  }

  @override
  String get anErrorOccurred => 'حدث خطأ أثناء التنزيل.';

  @override
  String get stillUnderDevelopment => 'هذه الميزة قيد التطوير.';

  @override
  String downloadFullQuranDialog(Object pages, Object size) {
    return 'حجم القرآن الكامل تقريبًا $size ويحتوي على $pages صفحة. قد يستغرق التنزيل بعض الوقت. هل تريد المتابعة؟';
  }

  @override
  String get areYouSureDeleteQuran =>
      'هل أنت متأكد أنك تريد حذف القرآن الكامل؟ سيؤدي ذلك إلى توفير مساحة تخزين ولكن ستحتاج إلى تنزيله مرة أخرى للعرض.';

  @override
  String get fullQuranDeleted => 'تم حذف القرآن الكامل بنجاح.';

  @override
  String get downloadControls => 'إدارة التنزيل';

  @override
  String get progress => 'التقدم';

  @override
  String get current => 'الملف الحالي:';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get deleteDownloadedFiles => 'حذف الملفات التي تم تنزيلها';

  @override
  String get juzListTitle => 'قائمة الأجزاء';

  @override
  String selectedCount(Object count) {
    return '$count محدد';
  }

  @override
  String get deleteSelected => 'حذف المحدد';

  @override
  String juzNotDownloaded(Object juz) {
    return 'الجزء $juz غير مُنزّل.';
  }

  @override
  String get juzProperties => 'خصائص الجزء';

  @override
  String get fileCount => 'عدد الملفات';

  @override
  String get totalSize => 'الحجم الكلي';

  @override
  String get close => 'إغلاق';

  @override
  String get couldNotLoadProperties => 'تعذر تحميل الخصائص.';

  @override
  String get pendingPausing => 'يتم الإيقاف المؤقت...';

  @override
  String get pendingCancelling => 'يتم الإلغاء...';

  @override
  String get pendingDeleting => 'يتم الحذف...';

  @override
  String get pagesLabel => 'صفحات';

  @override
  String get surahListTitle => 'قائمة السور';

  @override
  String get surahLoadError => 'خطأ في تحميل السور';

  @override
  String get noSurahData => 'لا توجد بيانات سور متاحة.';

  @override
  String get ayahCountLabel => 'آيات';

  @override
  String get makkiType => 'مكية';

  @override
  String get madaniType => 'مدنية';

  @override
  String get readingSettings => 'إعدادات القراءة';

  @override
  String get nightMode => 'الوضع الليلي';

  @override
  String get nightModeSubtitle => 'خلفية داكنة للإضاءة المنخفضة';

  @override
  String get scrollDirection => 'اتجاه التمرير';

  @override
  String get horizontal => 'أفقي';

  @override
  String get vertical => 'عمودي';

  @override
  String get readingTimer => 'مؤقت القراءة';

  @override
  String timerRunning(Object time) {
    return 'يعمل: $time';
  }

  @override
  String get timerNotRunning => 'غير نشط';

  @override
  String get autoScroll => 'التمرير التلقائي';

  @override
  String autoScrollEnabled(Object seconds) {
    return 'مفعل ($secondsث/صفحة)';
  }

  @override
  String get autoScrollDisabled => 'معطل';

  @override
  String get scrollSpeed => 'سرعة التمرير';

  @override
  String secondsPerPage(Object seconds) {
    return '$seconds ثانية لكل صفحة';
  }

  @override
  String get minTimeToCountPage => 'الحد الأدنى لاحتساب الصفحة كمقروءة';

  @override
  String secondsLabel(Object seconds) {
    return '$seconds ثانية';
  }

  @override
  String get readingAnalytics => 'تحليلات القراءة';

  @override
  String get streaks => 'سلاسل القراءة';

  @override
  String get dayStreak => 'سلسلة الأيام';

  @override
  String get today => 'اليوم';

  @override
  String get goals => 'الأهداف';

  @override
  String get dailyGoal => 'الهدف اليومي';

  @override
  String goalProgress(Object progress) {
    return '$progress%';
  }

  @override
  String minutesGoalProgress(Object goal, Object minutes) {
    return '$minutes / $goal دقيقة';
  }

  @override
  String get weeklyGoal => 'الهدف الأسبوعي';

  @override
  String pagesGoalProgress(Object goal, Object pages) {
    return '$pages / $goal صفحة';
  }

  @override
  String get noInsights => 'لا توجد نصائح بعد. ابدأ القراءة لرؤية النصائح!';

  @override
  String get noReadingSessions => 'لا توجد جلسات قراءة بعد.';

  @override
  String get startStreakTip => 'ابدأ سلسلة بقراءة كل يوم!';

  @override
  String totalTimeReading(Object seconds) {
    return 'إجمالي وقت القراءة: $seconds ثانية';
  }

  @override
  String get insights => 'نصائح';

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
  String get sessionInsights => 'إحصاءات الجلسة';

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
      'لا توجد بيانات جلسة بعد. ابدأ جلسة لرؤية الإحصاءات.';

  @override
  String get history => 'السجل';

  @override
  String get pagesReadLast7Days => 'الصفحات المقروءة (آخر 7 أيام)';

  @override
  String get recentSessions => 'الجلسات الأخيرة';

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
  String get setDailyGoal => 'تحديد الهدف اليومي';

  @override
  String get viewDownloadedJuzs => 'عرض الأجزاء المُنزّلة';

  @override
  String get switchJuz => 'تبديل الجزء';

  @override
  String get downloadedJuzsTitle => 'الأجزاء المُنزّلة';

  @override
  String juzsDownloaded(Object downloaded, Object total) {
    return '$downloaded/$total جزء مُنزّل';
  }

  @override
  String get enterYourInfo =>
      'أدخل معلوماتك (اختياري) لمساعدتنا في تحسين التواصل.';

  @override
  String get continueButton => 'إستمرار';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get skip => 'تخطي';

  @override
  String get updateYourInfo => 'تحديث معلوماتك';

  @override
  String get like => 'إعجاب';

  @override
  String get dislike => 'لا إعجاب';

  @override
  String get addComment => 'إضافة تعليق';

  @override
  String get recentComments => 'التعليقات الأخيرة';

  @override
  String get prayerReminderTime => 'تذكير وقت الصلاة';

  @override
  String get prayerVibration => 'اهتزاز';

  @override
  String get prayerVibrationSubtitle => 'إشعارات الصلاة';

  @override
  String get globalNotificationsDisabled => 'إشعارات المهام العامة معطلة';

  @override
  String get prayerNotifications => 'إشعارات مواقيت الصلاة';

  @override
  String prayerNotificationBody(Object prayerName) {
    return 'تبقّى دقيقة على صلاة $prayerName';
  }

  @override
  String prayerNotificationBodyAdvance(Object prayerName, Object timeText) {
    return 'تبقّى $timeText على صلاة $prayerName';
  }

  @override
  String get atPrayerTime => 'في وقت الصلاة';

  @override
  String inMinutes(Object count) {
    return '$count دقائق';
  }

  @override
  String inHours(Object count) {
    return '$count ساعات';
  }

  @override
  String get inOneMinute => 'دقيقة واحدة';

  @override
  String get inOneHour => 'ساعة واحدة';

  @override
  String get search => 'بحث';

  @override
  String get sortByNameAsc => 'الاسم (أ-ي)';

  @override
  String get sortByNameDesc => 'الاسم (ي-أ)';

  @override
  String get sortByDateAsc => 'التاريخ (الأقدم)';

  @override
  String get sortByDateDesc => 'التاريخ (الأحدث)';

  @override
  String get sortByType => 'النوع';

  @override
  String get searchHint => 'ابحث في الملفات...';

  @override
  String get openWithExternalApp => 'openwithexternalapp';
}
