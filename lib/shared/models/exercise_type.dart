enum ExerciseType {
  pushups('Push-ups', 'pushups', 1),
  situps('Sit-ups', 'situps', 1),
  squats('Squats', 'squats', 1),
  running('Running', 'running', 100);

  const ExerciseType(this.displayName, this.key, this.increment);

  final String displayName;
  final String key;
  final int increment; // How much each tap increases the count

  String get unit {
    switch (this) {
      case ExerciseType.running:
        return 'm';
      default:
        return 'reps';
    }
  }

  int get target {
    switch (this) {
      case ExerciseType.running:
        return 10000; // 10km
      default:
        return 100; // 100 reps
    }
  }

  String formatCount(int count) {
    switch (this) {
      case ExerciseType.running:
        if (count >= 1000) {
          return '${(count / 1000).toStringAsFixed(1)}km';
        }
        return '${count}m';
      default:
        return '$count';
    }
  }

  String formatTarget() {
    switch (this) {
      case ExerciseType.running:
        return '10km';
      default:
        return '100';
    }
  }
}
