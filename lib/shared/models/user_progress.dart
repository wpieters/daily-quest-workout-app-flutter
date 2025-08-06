import 'package:json_annotation/json_annotation.dart';
import 'package:daily_quest/shared/models/workout_day.dart';

part 'user_progress.g.dart';

@JsonSerializable()
class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final List<WorkoutDay> history;

  UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    List<WorkoutDay>? history,
  }) : history = history ?? [];

  // Create a new instance with updated values
  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    List<WorkoutDay>? history,
  }) {
    return UserProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      history: history ?? this.history,
    );
  }

  // Add a completed workout day to history
  UserProgress addCompletedWorkout(WorkoutDay workoutDay) {
    if (!workoutDay.isCompleted) {
      return this; // Only add completed workouts
    }

    // Check if we already have a workout for this date
    final existingIndex = history.indexWhere(
      (day) => _isSameDay(day.date, workoutDay.date),
    );

    List<WorkoutDay> updatedHistory;
    if (existingIndex >= 0) {
      // Replace existing workout
      updatedHistory = List.from(history);
      updatedHistory[existingIndex] = workoutDay;
    } else {
      // Add new workout
      updatedHistory = List.from(history)..add(workoutDay);
    }

    // Sort history by date (newest first)
    updatedHistory.sort((a, b) => b.date.compareTo(a.date));

    // Calculate new streak
    int newStreak = _calculateCurrentStreak(updatedHistory);
    int newLongestStreak = longestStreak;
    if (newStreak > longestStreak) {
      newLongestStreak = newStreak;
    }

    return UserProgress(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      totalWorkouts: existingIndex >= 0 ? totalWorkouts : totalWorkouts + 1,
      history: updatedHistory,
    );
  }

  // Calculate current streak based on consecutive completed days
  int _calculateCurrentStreak(List<WorkoutDay> sortedHistory) {
    if (sortedHistory.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final day in sortedHistory) {
      if (!day.isCompleted) continue;

      if (lastDate == null) {
        // First completed day
        streak = 1;
        lastDate = day.date;
      } else if (_isSameDay(lastDate, day.date)) {
        // Same day, skip
        continue;
      } else if (_isConsecutiveDay(lastDate, day.date)) {
        // Consecutive day
        streak++;
        lastDate = day.date;
      } else {
        // Streak broken
        break;
      }
    }

    return streak;
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Check if two dates are consecutive days
  bool _isConsecutiveDay(DateTime date1, DateTime date2) {
    final difference = date1.difference(date2).inDays.abs();
    return difference == 1;
  }

  // Get the power level based on streak (for animations)
  int get powerLevel {
    if (currentStreak >= 100) return 4; // Ultra Instinct
    if (currentStreak >= 31) return 3; // Super Saiyan 2
    if (currentStreak >= 8) return 2; // Super Saiyan 1
    return 1; // Basic power-up
  }

  // Factory methods for JSON serialization
  factory UserProgress.fromJson(Map<String, dynamic> json) => 
      _$UserProgressFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}