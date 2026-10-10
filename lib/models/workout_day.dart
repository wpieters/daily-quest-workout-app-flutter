import '../progression/progression_state.dart';

class WorkoutDay {
  final DateTime date;
  final int pushups;
  final int situps;
  final int squats;
  final int running; // in 100m units
  final bool runningEnabled;
  final bool completed;
  final int xpEarned; // XP already awarded for this day; awards never repeat
  final bool bonusAwarded;

  const WorkoutDay({
    required this.date,
    this.pushups = 0,
    this.situps = 0,
    this.squats = 0,
    this.running = 0,
    this.runningEnabled = true,
    this.completed = false,
    this.xpEarned = 0,
    this.bonusAwarded = false,
  });

  WorkoutDay copyWith({
    DateTime? date,
    int? pushups,
    int? situps,
    int? squats,
    int? running,
    bool? runningEnabled,
    bool? completed,
    int? xpEarned,
    bool? bonusAwarded,
  }) {
    return WorkoutDay(
      date: date ?? this.date,
      pushups: pushups ?? this.pushups,
      situps: situps ?? this.situps,
      squats: squats ?? this.squats,
      running: running ?? this.running,
      runningEnabled: runningEnabled ?? this.runningEnabled,
      completed: completed ?? this.completed,
      xpEarned: xpEarned ?? this.xpEarned,
      bonusAwarded: bonusAwarded ?? this.bonusAwarded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'pushups': pushups,
      'situps': situps,
      'squats': squats,
      'running': running,
      'runningEnabled': runningEnabled,
      'completed': completed,
      'xpEarned': xpEarned,
      'bonusAwarded': bonusAwarded,
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      date: DateTime.parse(json['date']),
      pushups: json['pushups'] ?? 0,
      situps: json['situps'] ?? 0,
      squats: json['squats'] ?? 0,
      running: json['running'] ?? 0,
      runningEnabled: json['runningEnabled'] ?? true,
      completed: json['completed'] ?? false,
      xpEarned: json['xpEarned'] ?? 0,
      bonusAwarded: json['bonusAwarded'] ?? false,
    );
  }

  bool get isComplete {
    const target = 100;
    final exercisesComplete = pushups >= target && situps >= target && squats >= target;
    final runningComplete = !runningEnabled || running >= target;
    return exercisesComplete && runningComplete;
  }

  DaySummary get summary => DaySummary.fromCounts(
        pushups: pushups,
        situps: situps,
        squats: squats,
        running: running,
        runningEnabled: runningEnabled,
      );

  bool get hasActivity => pushups + situps + squats + running > 0;

  int get pushupsStage => (pushups / 10).floor().clamp(0, 10);
  int get situpsStage => (situps / 10).floor().clamp(0, 10);
  int get squatsStage => (squats / 10).floor().clamp(0, 10);
  int get runningStage => (running / 10).floor().clamp(0, 10);

  double get pushupsProgress => (pushups / 100).clamp(0.0, 1.0);
  double get situpsProgress => (situps / 100).clamp(0.0, 1.0);
  double get squatsProgress => (squats / 100).clamp(0.0, 1.0);
  double get runningProgress => (running / 100).clamp(0.0, 1.0);
}