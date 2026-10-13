import 'progression_config.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Which exercises reached their target on a given day.
class DaySummary {
  final bool pushups;
  final bool situps;
  final bool squats;
  final bool running;
  final bool runningEnabled;

  const DaySummary({
    this.pushups = false,
    this.situps = false,
    this.squats = false,
    this.running = false,
    this.runningEnabled = true,
  });

  static const empty = DaySummary();

  factory DaySummary.fromCounts({
    required int pushups,
    required int situps,
    required int squats,
    required int running,
    required bool runningEnabled,
    ProgressionConfig config = ProgressionConfig.standard,
  }) {
    final t = config.exerciseTarget;
    return DaySummary(
      pushups: pushups >= t,
      situps: situps >= t,
      squats: squats >= t,
      running: runningEnabled && running >= t,
      runningEnabled: runningEnabled,
    );
  }

  int get completedCount =>
      [pushups, situps, squats, running].where((done) => done).length;

  bool get isMissed => completedCount == 0;

  bool get earnsBonus => runningEnabled && completedCount == 4;
}

/// Per-exercise completion counts over a span of days.
class DayTally {
  final int days;
  final int pushups;
  final int situps;
  final int squats;
  final int running;

  const DayTally({
    this.days = 0,
    this.pushups = 0,
    this.situps = 0,
    this.squats = 0,
    this.running = 0,
  });

  static const empty = DayTally();

  DayTally add(DaySummary day) => DayTally(
    days: days + 1,
    pushups: pushups + (day.pushups ? 1 : 0),
    situps: situps + (day.situps ? 1 : 0),
    squats: squats + (day.squats ? 1 : 0),
    running: running + (day.running ? 1 : 0),
  );

  bool meets(int count, double ratio) => days > 0 && count / days >= ratio;

  Map<String, dynamic> toJson() => {
    'days': days,
    'pushups': pushups,
    'situps': situps,
    'squats': squats,
    'running': running,
  };

  factory DayTally.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return DayTally(
      days: json['days'] ?? 0,
      pushups: json['pushups'] ?? 0,
      situps: json['situps'] ?? 0,
      squats: json['squats'] ?? 0,
      running: json['running'] ?? 0,
    );
  }
}

class CharacterStats {
  final int strength;
  final int vitality;
  final int agility;
  final int intelligence;
  final int perception;

  const CharacterStats({
    required this.strength,
    required this.vitality,
    required this.agility,
    required this.intelligence,
    required this.perception,
  });

  factory CharacterStats.starting(ProgressionConfig config) => CharacterStats(
    strength: config.startingStat,
    vitality: config.startingStat,
    agility: config.startingStat,
    intelligence: config.startingStat,
    perception: config.startingStat,
  );

  int hp(ProgressionConfig config) => vitality * config.hpPerVitality;
  int mp(ProgressionConfig config) => intelligence * config.mpPerIntelligence;

  CharacterStats copyWith({int? strength, int? vitality, int? agility}) =>
      CharacterStats(
        strength: strength ?? this.strength,
        vitality: vitality ?? this.vitality,
        agility: agility ?? this.agility,
        intelligence: intelligence,
        perception: perception,
      );

  Map<String, dynamic> toJson() => {
    'strength': strength,
    'vitality': vitality,
    'agility': agility,
    'intelligence': intelligence,
    'perception': perception,
  };

  factory CharacterStats.fromJson(
    Map<String, dynamic>? json,
    ProgressionConfig config,
  ) {
    final start = config.startingStat;
    return CharacterStats(
      strength: json?['strength'] ?? start,
      vitality: json?['vitality'] ?? start,
      agility: json?['agility'] ?? start,
      intelligence: json?['intelligence'] ?? start,
      perception: json?['perception'] ?? start,
    );
  }
}

/// Persisted progression data. Level, title, HP and MP are derived, not stored.
class ProgressionState {
  final int totalXp;
  final int skillPoints;
  final CharacterStats stats;
  final int fatigueCurrent;
  final int fatigueMax;
  final int consecutiveMissedDays;

  /// The last calendar day whose missed-day processing has been settled.
  final DateTime? lastActiveDate;

  /// Days spent at the current level, for the stat-gain rule.
  final DayTally levelTally;

  /// Days since the last fatigue milestone, for the fatigue-max rule.
  final DayTally fatigueTally;

  /// Highest level ever reached; skill points are only granted for new highs.
  final int highestLevel;

  /// Highest fatigue milestone level already evaluated.
  final int fatigueMilestoneLevel;

  const ProgressionState({
    required this.totalXp,
    required this.skillPoints,
    required this.stats,
    required this.fatigueCurrent,
    required this.fatigueMax,
    required this.consecutiveMissedDays,
    required this.lastActiveDate,
    required this.levelTally,
    required this.fatigueTally,
    required this.highestLevel,
    required this.fatigueMilestoneLevel,
  });

  factory ProgressionState.initial([
    ProgressionConfig config = ProgressionConfig.standard,
  ]) => ProgressionState(
    totalXp: 0,
    skillPoints: 0,
    stats: CharacterStats.starting(config),
    fatigueCurrent: config.startingFatigue,
    fatigueMax: config.startingFatigue,
    consecutiveMissedDays: 0,
    lastActiveDate: null,
    levelTally: DayTally.empty,
    fatigueTally: DayTally.empty,
    highestLevel: 1,
    fatigueMilestoneLevel: 0,
  );

  ProgressionState copyWith({
    int? totalXp,
    int? skillPoints,
    CharacterStats? stats,
    int? fatigueCurrent,
    int? fatigueMax,
    int? consecutiveMissedDays,
    DateTime? lastActiveDate,
    DayTally? levelTally,
    DayTally? fatigueTally,
    int? highestLevel,
    int? fatigueMilestoneLevel,
  }) {
    return ProgressionState(
      totalXp: totalXp ?? this.totalXp,
      skillPoints: skillPoints ?? this.skillPoints,
      stats: stats ?? this.stats,
      fatigueCurrent: fatigueCurrent ?? this.fatigueCurrent,
      fatigueMax: fatigueMax ?? this.fatigueMax,
      consecutiveMissedDays:
          consecutiveMissedDays ?? this.consecutiveMissedDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      levelTally: levelTally ?? this.levelTally,
      fatigueTally: fatigueTally ?? this.fatigueTally,
      highestLevel: highestLevel ?? this.highestLevel,
      fatigueMilestoneLevel:
          fatigueMilestoneLevel ?? this.fatigueMilestoneLevel,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'skillPoints': skillPoints,
    'stats': stats.toJson(),
    'fatigueCurrent': fatigueCurrent,
    'fatigueMax': fatigueMax,
    'consecutiveMissedDays': consecutiveMissedDays,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    'levelTally': levelTally.toJson(),
    'fatigueTally': fatigueTally.toJson(),
    'highestLevel': highestLevel,
    'fatigueMilestoneLevel': fatigueMilestoneLevel,
  };

  factory ProgressionState.fromJson(
    Map<String, dynamic>? json, [
    ProgressionConfig config = ProgressionConfig.standard,
  ]) {
    if (json == null) return ProgressionState.initial(config);
    final lastActive = json['lastActiveDate'] as String?;
    return ProgressionState(
      totalXp: json['totalXp'] ?? 0,
      skillPoints: json['skillPoints'] ?? 0,
      stats: CharacterStats.fromJson(json['stats'], config),
      fatigueCurrent: json['fatigueCurrent'] ?? config.startingFatigue,
      fatigueMax: json['fatigueMax'] ?? config.startingFatigue,
      consecutiveMissedDays: json['consecutiveMissedDays'] ?? 0,
      lastActiveDate: lastActive == null ? null : DateTime.parse(lastActive),
      levelTally: DayTally.fromJson(json['levelTally']),
      fatigueTally: DayTally.fromJson(json['fatigueTally']),
      highestLevel: json['highestLevel'] ?? 1,
      fatigueMilestoneLevel: json['fatigueMilestoneLevel'] ?? 0,
    );
  }
}
