import 'package:json_annotation/json_annotation.dart';
import 'exercise_type.dart';

part 'workout_day.g.dart';

@JsonSerializable()
class WorkoutDay {
  final DateTime date;
  final int pushups;
  final int situps;
  final int squats;
  final int running; // in meters
  final bool runningEnabled;

  const WorkoutDay({
    required this.date,
    this.pushups = 0,
    this.situps = 0,
    this.squats = 0,
    this.running = 0,
    this.runningEnabled = true,
  });

  // Get count for specific exercise type
  int getCount(ExerciseType type) {
    switch (type) {
      case ExerciseType.pushups:
        return pushups;
      case ExerciseType.situps:
        return situps;
      case ExerciseType.squats:
        return squats;
      case ExerciseType.running:
        return running;
    }
  }

  // Check if exercise is completed
  bool isExerciseCompleted(ExerciseType type) {
    return getCount(type) >= type.target;
  }

  // Check if all required exercises are completed
  bool get isCompleted {
    final requiredExercises = [
      ExerciseType.pushups,
      ExerciseType.situps,
      ExerciseType.squats,
    ];
    
    // Add running if enabled
    if (runningEnabled) {
      requiredExercises.add(ExerciseType.running);
    }

    return requiredExercises.every((exercise) => isExerciseCompleted(exercise));
  }

  // Get completion percentage for an exercise
  double getCompletionPercentage(ExerciseType type) {
    final count = getCount(type);
    final target = type.target;
    return (count / target).clamp(0.0, 1.0);
  }

  // Get current stage for an exercise (0-10)
  int getCurrentStage(ExerciseType type) {
    final count = getCount(type);
    return (count / 10).floor().clamp(0, 10);
  }

  // Get progress within current stage (0.0-1.0)
  double getStageProgress(ExerciseType type) {
    final count = getCount(type);
    final stageCount = count % 10;
    return stageCount / 10.0;
  }

  // Create a copy with updated values
  WorkoutDay copyWith({
    DateTime? date,
    int? pushups,
    int? situps,
    int? squats,
    int? running,
    bool? runningEnabled,
  }) {
    return WorkoutDay(
      date: date ?? this.date,
      pushups: pushups ?? this.pushups,
      situps: situps ?? this.situps,
      squats: squats ?? this.squats,
      running: running ?? this.running,
      runningEnabled: runningEnabled ?? this.runningEnabled,
    );
  }

  // Update specific exercise count
  WorkoutDay updateExercise(ExerciseType type, int count) {
    switch (type) {
      case ExerciseType.pushups:
        return copyWith(pushups: count);
      case ExerciseType.situps:
        return copyWith(situps: count);
      case ExerciseType.squats:
        return copyWith(squats: count);
      case ExerciseType.running:
        return copyWith(running: count);
    }
  }

  // Increment exercise count
  WorkoutDay incrementExercise(ExerciseType type) {
    final currentCount = getCount(type);
    final newCount = (currentCount + type.increment).clamp(0, type.target);
    return updateExercise(type, newCount);
  }

  // JSON serialization
  factory WorkoutDay.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutDayToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDay &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          pushups == other.pushups &&
          situps == other.situps &&
          squats == other.squats &&
          running == other.running &&
          runningEnabled == other.runningEnabled;

  @override
  int get hashCode =>
      date.hashCode ^
      pushups.hashCode ^
      situps.hashCode ^
      squats.hashCode ^
      running.hashCode ^
      runningEnabled.hashCode;

  @override
  String toString() {
    return 'WorkoutDay(date: $date, pushups: $pushups, situps: $situps, '
        'squats: $squats, running: $running, runningEnabled: $runningEnabled, '
        'completed: $isCompleted)';
  }
}
