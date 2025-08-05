import 'workout_day.dart';

class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final List<WorkoutDay> history;

  const UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.history = const [],
  });

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

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWorkouts': totalWorkouts,
      'history': history.map((day) => day.toJson()).toList(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalWorkouts: json['totalWorkouts'] ?? 0,
      history: (json['history'] as List<dynamic>?)
          ?.map((day) => WorkoutDay.fromJson(day))
          .toList() ?? [],
    );
  }

  String get powerLevel {
    if (currentStreak >= 100) return 'Ultra Instinct';
    if (currentStreak >= 31) return 'Super Saiyan 2';
    if (currentStreak >= 8) return 'Super Saiyan';
    if (currentStreak >= 1) return 'Power Up';
    return 'Newbie';
  }

  int get powerLevelTier {
    if (currentStreak >= 100) return 4;
    if (currentStreak >= 31) return 3;
    if (currentStreak >= 8) return 2;
    if (currentStreak >= 1) return 1;
    return 0;
  }
}