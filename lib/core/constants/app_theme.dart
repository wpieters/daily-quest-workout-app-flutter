import 'package:flutter/material.dart';

class AppTheme {
  // Power Level Colors (Blue → Yellow → Red progression)
  static const Color basicPowerBlue = Color(0xFF2196F3);
  static const Color superSaiyanYellow = Color(0xFFFFEB3B);
  static const Color superSaiyan2Gold = Color(0xFFFF9800);
  static const Color ultraInstinctSilver = Color(0xFF9E9E9E);

  // Primary App Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFFFF5722);
  static const Color accentColor = Color(0xFFFFEB3B);

  // Exercise Colors
  static const Color pushupColor = Color(0xFF4CAF50);
  static const Color situpColor = Color(0xFF2196F3);
  static const Color squatColor = Color(0xFFFF9800);
  static const Color runningColor = Color(0xFFF44336);

  // UI Colors
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2D2D2D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBBBBBB);
  static const Color dividerColor = Color(0xFF333333);

  // Progress Colors
  static const Color progressIncomplete = Color(0xFF424242);
  static const Color progressComplete = Color(0xFF4CAF50);
  static const Color stageComplete = Color(0xFFFFEB3B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardTheme(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: progressIncomplete,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(backgroundColor),
        side: const BorderSide(color: textSecondary, width: 2),
      ),
    );
  }

  static Color getPowerLevelColor(int streak) {
    if (streak >= 101) return ultraInstinctSilver;
    if (streak >= 31) return superSaiyan2Gold;
    if (streak >= 8) return superSaiyanYellow;
    return basicPowerBlue;
  }

  static Color getExerciseColor(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'pushups':
        return pushupColor;
      case 'situps':
        return situpColor;
      case 'squats':
        return squatColor;
      case 'running':
        return runningColor;
      default:
        return primaryColor;
    }
  }
}
