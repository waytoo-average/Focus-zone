// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'محطة دراسة الكلية المصرية الصينية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

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
      'محطة دراسة الكلية المصرية الصينية للتكنولوجيا التطبيقية (ECCAT) هو تطبيق جوال مصمم لمساعدة الطلاب على الوصول إلى موادهم الأكاديمية وتنظيمها من جوجل درايف.';

  @override
  String get madeBy => 'تم التطوير بواسطة';

  @override
  String get developerName => 'بلال محمد النمر';

  @override
  String get developerDetails => 'طالب هندسة اتصالات وإلكترونيات';

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
      'الكلية المصرية الصينية للتكنولوجيا التطبيقية (ECCAT) هي مؤسسة تعليمية فريدة تعزز المهارات العملية والتكنولوجية.';

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
}
