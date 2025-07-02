# Focus Zone: Your Academic Companion

## 🎯 What is Focus Zone?

Focus Zone is a mobile application designed to empower students by providing seamless access to and organization of their academic materials directly from Google Drive. It helps students manage their studies efficiently with features including:

  * **Organized Study Materials:** Navigate through academic content structured by grade, department, year, semester, and subject.
  * **Integrated Document Viewing:** Directly view PDF files within the app with caching capabilities, and access other document types through an integrated web viewer.
  * **Smart Download Management:** Download multiple files simultaneously to a customizable location with real-time progress updates.
  * **Personalized To-Do List:** Create, manage, and track academic tasks and reminders with due dates, repeat options, and customizable lists, supported by local notifications.
  * **User Authentication:** Securely sign in with your Google account to access your Google Drive files.
  * **Theme & Language Customization:** Personalize your app experience with light/dark themes and English/Arabic language options.
  * **Recent Files & Dashboard:** Quickly access recently viewed documents and get a snapshot of your study activity and task progress.

## 🧠 Learning Goals

This project serves as a comprehensive learning endeavor focusing on building a robust Flutter application. Key learning aspects include:

### 🧩 Frontend (Flutter & Dart)

  * **Effective Flutter Development:** Utilizing Flutter widgets, state management (Provider), and navigation (nested navigators, global routes).
  * **Google Drive API Integration:** Interacting with Google APIs for file listing, viewing, and downloading.
  * **Local Data Persistence:** Implementing `shared_preferences` for theme, language, and user-specific data like to-do lists and recent files.
  * **File System Interaction:** Handling file downloads, managing local storage, and opening files using `path_provider` and `open_filex`.
  * **Local Notifications:** Scheduling and managing recurring notifications using `flutter_local_notifications` and `timezone`.
  * **WebView Integration:** Embedding web content using `webview_flutter` for non-PDF Google Drive files.
  * **PDF Viewing:** Integrating `syncfusion_flutter_pdfviewer` for in-app PDF display and caching.
  * **Internationalization (i10n):** Implementing multi-language support (English and Arabic) using Flutter's localization tools.
  * **Permission Handling:** Gracefully requesting and managing platform-specific permissions using `permission_handler`.

### 🛠 Architecture & State Management

  * **Provider Pattern:** Utilizing the `provider` package for efficient and scalable app-wide state management (e.g., `SignInProvider`, `ThemeProvider`, `LanguageProvider`, `DownloadPathProvider`, `RecentFilesProvider`, `TodoSummaryProvider`, `FirstLaunchProvider`).
  * **Modular Design:** Separating features into distinct files (`app_core.dart`, `study_features.dart`, `todo_features.dart`, `settings_features.dart`) for better organization and maintainability.
  * **Asynchronous Operations:** Handling network requests and file operations asynchronously.

## 🛠 Tech Stack
___________________________________________________________________________________________________________________________________
|---------Layer---------|--------------------Technology---------------------|--------------------- Purpose------------------------|
| **Frontend**:         | Flutter, Dart                                     | UI development, Cross-platform                      |
| **Networking**:       | `http`, `dio`                                     | API communication                                   |
| **Authentication**:   | `google_sign_in`, `googleapis`                    | Google Sign-In, Google Drive access                 |
| **File Management**:  | `path_provider`, `file_picker`, `open_filex`      | Local storage access, file selection, opening files |
| **Document Viewing**: | `webview_flutter`, `syncfusion_flutter_pdfviewer` | In-app document and PDF display                     |
| **Notifications** :   | `flutter_local_notifications`, `timezone`         | Scheduling local reminders                          |
| **State Management**: | `provider`                                        | App-wide state management                           |
| **Localization**      | `flutter_localizations`, `intl`                   | Multi-language support                              |
| **Permissions**:      | `permission_handler`, `android_intent_plus`       | Runtime permission handling                         |
| **App Info** :        | `package_info_plus`                               | Retrieve app package information                    |
___________________________________________________________________________________________________________________________________
## 🧭 Project Status

**IN DEVELOPMENT:** This project is actively being developed with continuous updates and enhancements planned. Follow the GitHub repository for progress updates\!

## 👥 Developed By

**Belal Mohamed Elnemr**

  * Communication and Electronics Engineering Student

### Contact & Social

  * **Phone Number:** [+201026027552](https://www.google.com/search?q=tel:%2B201026027552)
  * **Email:** [belal.elnemr.work@gmail.com](mailto:belal.elnemr.work@gmail.com)
  * **GitHub Profile:** [waytoo-average](https://github.com/waytoo-average)
  * **Discord Profile:** [Discord Profile](https://discord.com/users/858382338281963520)
  
## 🏛️ About Focus Zone

Focus Zone is a comprehensive study management application that fosters practical and technological skills for students.

### Connect with Focus Zone

  * **Facebook Page:** [Focus Zone Facebook](https://www.facebook.com/2018ECCAT)
  * **College Location (Google Maps):** [Focus Zone on Maps](https://maps.app.goo.gl/MTtsxuok1c5gteMw8)

## 🧾 License

MIT © 2025 Belal Mohamed Elnemr

## 📬 Contributions

subhan_0073
-----

### Project Version

**Version:** 1.0.0+1