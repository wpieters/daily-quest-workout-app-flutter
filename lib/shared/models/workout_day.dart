import 'package:json_annotation/json_annotation.dart';
import 'package:daily_quest/shared/models/exercise_type.dart';

part 'workout_day.g.dart';

@JsonSerializable()
class WorkoutDay {
  final DateTime date;
  final int pushups;
  final int situps;
  final int squats;
  final int running; // in 100m units
  final bool runningEnabled;
  final bool completed;

  WorkoutDay({
    required this.date,
    this.pushups = 0,
    this.situps = 0,
    this.squats = 0,
    this.running = 0,
    this.runningEnabled = true,
    this.completed = false,
  });

  // Create a new instance with updated values
  WorkoutDay copyWith({
    DateTime? date,
    int? pushups,
    int? situps,
    int? squats,
    int? running,
    bool? runningEnabled,
    bool? completed,
  }) {
    return WorkoutDay(
      date: date ?? this.date,
      pushups: pushups ?? this.pushups,
      situps: situps ?? this.situps,
      squats: squats ?? this.squats,
      running: running ?? this.running,
      runningEnabled: runningEnabled ?? this.runningEnabled,
      completed: completed ?? this.completed,
    );
  }

  // Get exercise count by type
  int getCountForExercise(ExerciseType type) {
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

  // Check if all exercises have reached their targets
  bool get isCompleted {
    final pushupsDone = pushups >= ExerciseType.pushups.target;
    final situpsDone = situps >= ExerciseType.situps.target;
    final squatsDone = squats >= ExerciseType.squats.target;
    
    if (runningEnabled) {
      final runningDone = running >= ExerciseType.running.target;
      return pushupsDone && situpsDone && squatsDone && runningDone;
    } else {
      return pushupsDone && situpsDone && squatsDone;
    }
  }

  // Calculate completion percentage
  double getCompletionPercentage(ExerciseType type) {
    final count = getCountForExercise(type);
    final target = type.target;
    return count / target;
  }

  // Calculate stage completion (0-10)
  int getCompletedStages(ExerciseType type) {
    final count = getCountForExercise(type);
    return (count / type.stageSize).floor();
  }

  // Factory methods for JSON serialization
  factory WorkoutDay.fromJson(Map<String, dynamic> json) => 
      _$WorkoutDayFromJson(json);
  
  Map<String, dynamic> toJson() => _$WorkoutDayToJson(this);
  
  // Create a new workout day for today
  factory WorkoutDay.today() {
    return WorkoutDay(
      date: DateTime.now(),
    );
  }
}