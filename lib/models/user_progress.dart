import '../progression/progression_state.dart';
import 'workout_day.dart';

class UserProgress {
  /// Bump when the stored shape changes. v1 had no `schemaVersion` key and
  /// no progression data; v1 data loads with starting progression values.
  static const int schemaVersion = 2;

  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final List<WorkoutDay> history;
  final ProgressionState progression;

  const UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.history = const [],
    required this.progression,
  });

  factory UserProgress.initial() =>
      UserProgress(progression: ProgressionState.initial());

  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    List<WorkoutDay>? history,
    ProgressionState? progression,
  }) {
    return UserProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      history: history ?? this.history,
      progression: progression ?? this.progression,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWorkouts': totalWorkouts,
      'history': history.map((day) => day.toJson()).toList(),
      'progression': progression.toJson(),
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
      progression: ProgressionState.fromJson(json['progression']),
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