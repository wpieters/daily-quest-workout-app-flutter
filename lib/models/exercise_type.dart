enum ExerciseType {
  pushups('Push-ups', '💪', '🟦'),
  situps('Sit-ups', '🔥', '🟨'),
  squats('Squats', '🦵', '🟧'),
  running('Running', '🏃', '🟩');

  const ExerciseType(this.displayName, this.icon, this.color);

  final String displayName;
  final String icon;
  final String color;
}