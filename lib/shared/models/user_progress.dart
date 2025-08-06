import 'package:json_annotation/json_annotation.dart';
import 'workout_day.dart';

part 'user_progress.g.dart';

@JsonSerializable()
class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final DateTime? lastWorkoutDate;

  const UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.lastWorkoutDate,
  });

  // Get power level based on current streak
  int get powerLevel {
    if (currentStreak >= 101) return 4; // Ultra Instinct
    if (currentStreak >= 31) return 3;  // Super Saiyan 2
    if (currentStreak >= 8) return 2;   // Super Saiyan 1
    if (currentStreak >= 1) return 1;   // Basic Power
    return 0; // No power
  }

  String get powerLevelName {
    switch (powerLevel) {
      case 4:
        return 'Ultra Instinct';
      case 3:
        return 'Super Saiyan 2';
      case 2:
        return 'Super Saiyan 1';
      case 1:
        return 'Basic Power';
      default:
        return 'Beginner';
    }
  }

  // Calculate streak based on workout completion
  static int calculateStreak(List<WorkoutDay> workoutHistory) {
    if (workoutHistory.isEmpty) return 0;

    // Sort by date (most recent first)
    final sortedDays = List<WorkoutDay>.from(workoutHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < sortedDays.length; i++) {
      final workoutDay = sortedDays[i];
      
      if (!workoutDay.isCompleted) break;
      
      // Check if this day is consecutive
      final daysDifference = today.difference(workoutDay.date).inDays;
      if (daysDifference == i || (i == 0 && daysDifference <= 1)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // Update progress after a workout completion
  UserProgress updateAfterWorkout(WorkoutDay completedDay) {
    final newTotalWorkouts = totalWorkouts + 1;
    
    // Check if this breaks or continues the streak
    final today = DateTime.now();
    final isToday = completedDay.date.day == today.day &&
        completedDay.date.month == today.month &&
        completedDay.date.year == today.year;

    int newCurrentStreak = currentStreak;
    
    if (isToday && completedDay.isCompleted) {
      // If completing today's workout
      if (lastWorkoutDate == null) {
        // First workout ever
        newCurrentStreak = 1;
      } else {
        final daysSinceLastWorkout = today.difference(lastWorkoutDate!).inDays;
        if (daysSinceLastWorkout == 1) {
          // Consecutive day
          newCurrentStreak = currentStreak + 1;
        } else if (daysSinceLastWorkout == 0) {
          // Same day (already counted)
          newCurrentStreak = currentStreak;
        } else {
          // Broke streak, start over
          newCurrentStreak = 1;
        }
      }
    }

    final newLongestStreak = newCurrentStreak > longestStreak 
        ? newCurrentStreak 
        : longestStreak;

    return UserProgress(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      totalWorkouts: newTotalWorkouts,
      lastWorkoutDate: completedDay.date,
    );
  }

  // Reset streak (called when a day is missed)
  UserProgress resetStreak() {
    return UserProgress(
      currentStreak: 0,
      longestStreak: longestStreak,
      totalWorkouts: totalWorkouts,
      lastWorkoutDate: lastWorkoutDate,
    );
  }

  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    DateTime? lastWorkoutDate,
  }) {
    return UserProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }

  // JSON serialization
  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgress &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          totalWorkouts == other.totalWorkouts &&
          lastWorkoutDate == other.lastWorkoutDate;

  @override
  int get hashCode =>
      currentStreak.hashCode ^
      longestStreak.hashCode ^
      totalWorkouts.hashCode ^
      lastWorkoutDate.hashCode;

  @override
  String toString() {
    return 'UserProgress(currentStreak: $currentStreak, '
        'longestStreak: $longestStreak, totalWorkouts: $totalWorkouts, '
        'lastWorkoutDate: $lastWorkoutDate, powerLevel: $powerLevelName)';
  }
}
