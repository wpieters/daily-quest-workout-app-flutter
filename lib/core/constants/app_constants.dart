class AppConstants {
  // Workout Targets
  static const int exerciseTarget = 100;
  static const int runningTarget = 10000; // 10km in meters
  static const int runningIncrement = 100; // 100m per tap
  static const int stageSize = 10; // 10 reps per stage
  static const int totalStages = 10; // 10 stages total

  // Animation Durations
  static const Duration buttonAnimationDuration = Duration(milliseconds: 150);
  static const Duration stageAnimationDuration = Duration(milliseconds: 300);
  static const Duration completionAnimationDuration = Duration(milliseconds: 500);

  // Power Level Thresholds (consecutive days)
  static const int basicPowerLevel = 1; // 1-7 days
  static const int superSaiyan1Level = 8; // 8-30 days
  static const int superSaiyan2Level = 31; // 31-100 days
  static const int ultraInstinctLevel = 101; // 100+ days

  // SharedPreferences Keys
  static const String keyCurrentDate = 'current_date';
  static const String keyPushups = 'pushups';
  static const String keySitups = 'situps';
  static const String keySquats = 'squats';
  static const String keyRunning = 'running';
  static const String keyRunningEnabled = 'running_enabled';
  static const String keyCurrentStreak = 'current_streak';
  static const String keyLongestStreak = 'longest_streak';
  static const String keyTotalWorkouts = 'total_workouts';
  static const String keyWorkoutHistory = 'workout_history';

  // UI Constants
  static const double buttonBorderRadius = 16.0;
  static const double buttonElevation = 4.0;
  static const double progressBarHeight = 8.0;
  static const double stageIndicatorSize = 12.0;
}
