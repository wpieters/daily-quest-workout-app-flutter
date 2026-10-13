import 'package:flutter/material.dart';

/// Solo Leveling "system window" look: dark navy, cyan accents, uppercase
/// labels and bracketed monospace counts. The app is dark-only.
class AppTheme {
  // Core palette (HSL values from the original design noted alongside)
  static const Color background = Color(0xFF0F131A); // 220 25% 8%
  static const Color card = Color(0xFF151C28); // 220 30% 12%
  static const Color muted = Color(0xFF1F242E); // 220 20% 15%
  static const Color secondary = Color(0xFF29303D); // 220 20% 20%
  static const Color foreground = Color(0xFFD5D7DD); // 220 10% 85%
  static const Color mutedForeground = Color(0xFF818898); // 220 10% 55%
  static const Color border = Color(0xFF0F618A); // 200 80% 30%

  // Quest colours
  static const Color questPrimary = Color(0xFF00AAFF); // 200 100% 50%
  static const Color questSuccess = Color(0xFF33CC33); // 120 60% 50%
  static const Color questWarning = Color(0xFFFF8000); // 30 100% 50%
  static const Color questDanger = Color(0xFFFF3333);

  // Power level colours
  static const Color primaryBlue = questPrimary;
  static const Color powerYellow = Color(0xFFFFD700);
  static const Color powerRed = Color(0xFFFF4444);
  static const Color powerPurple = Color(0xFF9C27B0);

  // System window
  static const Color systemBlue = questPrimary;
  static const Color systemPanel = card;

  static const Color darkBackground = background;
  static const Color darkSurface = card;
  static const Color darkCard = card;

  /// Uppercase, widely tracked label, as on the in-story system windows.
  static const TextStyle label = TextStyle(
    color: foreground,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  /// Bracketed counts such as `[42 / 100]`.
  static const TextStyle mono = TextStyle(
    color: foreground,
    fontFamily: 'monospace',
    fontFamilyFallback: ['Courier New', 'Courier'],
    fontFeatures: [FontFeature.tabularFigures()],
    fontWeight: FontWeight.bold,
  );

  static ThemeData get theme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: questPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: questPrimary,
          onPrimary: background,
          secondary: secondary,
          onSecondary: foreground,
          surface: card,
          onSurface: foreground,
          outline: border,
          error: questDanger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border.withValues(alpha: 0.5),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: questPrimary.withValues(alpha: 0.3)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: questPrimary.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: questPrimary.withValues(alpha: 0.2),
          foregroundColor: questPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: questPrimary.withValues(alpha: 0.5)),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: questPrimary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? questPrimary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(background),
      ),
    );
  }

  /// Panel decoration shared by every quest/system window.
  static BoxDecoration panel({
    Color? borderColor,
    double borderAlpha = 0.3,
    List<BoxShadow>? glow,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: (borderColor ?? questPrimary).withValues(alpha: borderAlpha),
      ),
      boxShadow: glow,
    );
  }

  static Color getPowerLevelColor(int level) {
    switch (level) {
      case 0:
        return mutedForeground;
      case 1:
        return primaryBlue;
      case 2:
        return powerYellow;
      case 3:
        return powerRed;
      case 4:
        return powerPurple;
      default:
        return primaryBlue;
    }
  }

  static LinearGradient getPowerLevelGradient(int level) {
    final color = getPowerLevelColor(level);
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
