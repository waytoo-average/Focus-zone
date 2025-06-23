import 'package:flutter/material.dart';

class AppTheme {
  // --- Color Definitions ---
  static const Color primaryDeepNavy = Color(0xFF1E3A5F);
  static const Color accentDarkOrange = Color(0xFFFF8C00);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color primaryDarkenedNavy = Color(0xFF152A4A);
  static const Color accentLighterOrange = Color(0xFFFFB300);
  static const Color backgroundDark = Color(0xAE121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // --- Dark Theme ---
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryDarkenedNavy,
        canvasColor: backgroundDark,
        scaffoldBackgroundColor: backgroundDark,
        useMaterial3: false,
        colorScheme: ColorScheme.dark(
          primary: primaryDarkenedNavy,
          secondary: accentLighterOrange,
          surface: surfaceDark,
          background: backgroundDark,
          error: const Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white70,
          onBackground: Colors.white,
          onError: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryDarkenedNavy,
          foregroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          toolbarHeight: 64.0,
          elevation: 4.0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDarkenedNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4.0,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
          color: surfaceDark,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          tileColor: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          subtitleTextStyle: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return accentLighterOrange;
            }
            return null;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentLighterOrange,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8.0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceDark.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentLighterOrange, width: 2),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          titleMedium: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
          titleSmall: TextStyle(
              color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white54),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white70),
          labelSmall: TextStyle(color: Colors.white54),
        ),
      );

  // --- Light Theme ---
  static ThemeData get lightTheme => ThemeData(
        primaryColor: primaryDeepNavy,
        canvasColor: backgroundLight,
        scaffoldBackgroundColor: backgroundLight,
        useMaterial3: false,
        colorScheme: ColorScheme.light(
          primary: primaryDeepNavy,
          secondary: accentDarkOrange,
          surface: surfaceLight,
          background: backgroundLight,
          error: const Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.grey[800]!,
          onBackground: Colors.grey[800]!,
          onError: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryDeepNavy,
          foregroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          toolbarHeight: 64.0,
          elevation: 4.0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDeepNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4.0,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
          color: surfaceLight,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          tileColor: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return accentDarkOrange;
            }
            return null;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accentDarkOrange,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8.0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundLight.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryDeepNavy, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.grey[800]),
          displayMedium: TextStyle(color: Colors.grey[800]),
          displaySmall: TextStyle(color: Colors.grey[800]),
          headlineLarge: TextStyle(color: Colors.grey[800]),
          headlineMedium: TextStyle(color: Colors.grey[800]),
          headlineSmall: TextStyle(color: Colors.grey[800]),
          titleLarge: TextStyle(
              color: Colors.grey[900],
              fontWeight: FontWeight.bold,
              fontSize: 22),
          titleMedium: TextStyle(
              color: Colors.grey[850],
              fontWeight: FontWeight.w600,
              fontSize: 18),
          titleSmall: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 14),
          bodyLarge: TextStyle(color: Colors.grey[800]),
          bodyMedium: TextStyle(color: Colors.grey[700]),
          bodySmall: TextStyle(color: Colors.grey[600]),
          labelLarge: TextStyle(color: Colors.grey[800]),
          labelMedium: TextStyle(color: Colors.grey[700]),
          labelSmall: TextStyle(color: Colors.grey[600]),
        ),
      );
}
