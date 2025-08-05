import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0099FF);
  static const Color powerYellow = Color(0xFFFFD700);
  static const Color powerRed = Color(0xFFFF4444);
  static const Color powerPurple = Color(0xFF9C27B0);
  
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shadowColor: primaryBlue.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkBackground,
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shadowColor: primaryBlue.withOpacity(0.3),
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.3),
          backgroundColor: darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
  
  static Color getPowerLevelColor(int level) {
    switch (level) {
      case 0: return Colors.grey;
      case 1: return primaryBlue;
      case 2: return powerYellow;
      case 3: return powerRed;
      case 4: return powerPurple;
      default: return primaryBlue;
    }
  }
  
  static LinearGradient getPowerLevelGradient(int level) {
    final color = getPowerLevelColor(level);
    return LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color,
        color.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}