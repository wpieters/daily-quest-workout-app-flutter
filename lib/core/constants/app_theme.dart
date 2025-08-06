import 'package:flutter/material.dart';

class AppTheme {
  // Power level colors (blue → yellow → red)
  static const Color powerLevel1 = Color(0xFF3498DB); // Blue
  static const Color powerLevel2 = Color(0xFFF1C40F); // Yellow
  static const Color powerLevel3 = Color(0xFFE74C3C); // Red
  static const Color powerLevel4 = Color(0xFF9B59B6); // Purple (Ultra Instinct)
  
  // App colors
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color accentColor = Color(0xFFF1C40F);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color textColor = Color(0xFFECF0F1);
  static const Color secondaryTextColor = Color(0xFFBDC3C7);
  
  // Get color based on power level
  static Color getPowerLevelColor(int level) {
    switch (level) {
      case 1:
        return powerLevel1;
      case 2:
        return powerLevel2;
      case 3:
        return powerLevel3;
      case 4:
        return powerLevel4;
      default:
        return powerLevel1;
    }
  }
  
  // Get color based on completion percentage
  static Color getProgressColor(double percentage) {
    if (percentage >= 0.8) {
      return powerLevel3; // Red for near completion
    } else if (percentage >= 0.5) {
      return powerLevel2; // Yellow for halfway
    } else {
      return powerLevel1; // Blue for starting
    }
  }
  
  // Light theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      background: Colors.white,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
  
  // Dark theme (default)
  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      background: backgroundColor,
      surface: cardColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textColor.withOpacity(0.9),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textColor.withOpacity(0.9),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),
  );
}