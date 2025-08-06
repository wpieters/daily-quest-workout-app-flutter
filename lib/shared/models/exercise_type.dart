enum ExerciseType {
  pushups,
  situps,
  squats,
  running;

  String get displayName {
    switch (this) {
      case ExerciseType.pushups:
        return 'Push-ups';
      case ExerciseType.situps:
        return 'Sit-ups';
      case ExerciseType.squats:
        return 'Squats';
      case ExerciseType.running:
        return 'Running';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseType.pushups:
        return '💪';
      case ExerciseType.situps:
        return '🧘';
      case ExerciseType.squats:
        return '🏋️';
      case ExerciseType.running:
        return '🏃';
    }
  }

  int get target {
    switch (this) {
      case ExerciseType.pushups:
      case ExerciseType.situps:
      case ExerciseType.squats:
        return 100;
      case ExerciseType.running:
        return 100; // 100 taps = 10km (100m per tap)
    }
  }

  int get stageSize {
    return 10; // 10 reps per stage
  }

  int get totalStages {
    return 10; // 10 stages total
  }
}