// lib/src/utils/app_utilities.dart

// --- App Padding & Task Filter/Sort Enums ---
class AppPadding {
  static const double horizontal = 16.0;
  static const double vertical = 8.0;
  static const double all = 16.0;
}

enum TaskFilter {
  all,
  active,
  completed,
}

enum TaskSort {
  dueDateAsc,
  dueDateDesc,
  titleAsc,
  titleDesc,
}
