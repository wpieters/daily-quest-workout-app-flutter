import 'leveling.dart';
import 'progression_config.dart';
import 'progression_state.dart';

/// A single level transition, produced by XP gains or missed-day penalties.
class LevelChange {
  final int fromLevel;
  final int toLevel;
  final int strengthDelta;
  final int vitalityDelta;
  final int agilityDelta;
  final int skillPointsGained;
  final int fatigueMaxGained;

  const LevelChange({
    required this.fromLevel,
    required this.toLevel,
    this.strengthDelta = 0,
    this.vitalityDelta = 0,
    this.agilityDelta = 0,
    this.skillPointsGained = 0,
    this.fatigueMaxGained = 0,
  });

  bool get isLevelUp => toLevel > fromLevel;

  /// The title unlocked by this change, or null if the title didn't change.
  String? get newTitle {
    final title = titleForLevel(toLevel);
    return title == titleForLevel(fromLevel) ? null : title;
  }
}

class ProgressionResult {
  final ProgressionState state;
  final List<LevelChange> levelChanges;
  final int missedDaysProcessed;

  const ProgressionResult(
    this.state, {
    this.levelChanges = const [],
    this.missedDaysProcessed = 0,
  });
}

/// Pure progression rules: XP awards, missed days, level protection, stats.
class ProgressionEngine {
  final ProgressionConfig config;
  final Leveling leveling;

  ProgressionEngine([this.config = ProgressionConfig.standard])
      : leveling = Leveling(config);

  int levelOf(ProgressionState s) => leveling.levelForXp(s.totalXp);

  String titleOf(ProgressionState s) => titleForLevel(levelOf(s));

  /// XP a day is worth: per exercise at target, plus the all-four bonus.
  int dayXp(DaySummary day) =>
      day.completedCount * config.xpPerExercise +
      (day.earnsBonus ? config.allCompleteBonusXp : 0);

  /// Adds [amount] XP. [today] is the current day's progress so far, counted
  /// provisionally towards the stat-gain and fatigue rules on level-up.
  ProgressionResult awardXp(
      ProgressionState state, int amount, DaySummary today) {
    if (amount <= 0) return ProgressionResult(state);

    final fromLevel = levelOf(state);
    var s = state.copyWith(totalXp: state.totalXp + amount);
    final toLevel = levelOf(s);
    final changes = <LevelChange>[];

    for (var level = fromLevel; level < toLevel; level++) {
      final next = level + 1;
      final tally = s.levelTally.add(today);
      final ratio = config.statGainCompletionRatio;
      final gain = config.statGainPerLevel;
      final stats = s.stats;

      final str = _capped(stats.strength,
          tally.meets(tally.pushups, ratio) ? gain : 0);
      final vit = _capped(stats.vitality,
          tally.meets(tally.situps, ratio) ? gain : 0);
      final agi = _capped(stats.agility,
          tally.meets(tally.squats, ratio) ? gain : 0);

      final skillPoints =
          next > s.highestLevel ? config.skillPointsPerLevel : 0;

      var fatigueGain = 0;
      var fatigueTally = s.fatigueTally;
      var fatigueMilestone = s.fatigueMilestoneLevel;
      if (next % config.fatigueLevelSpan == 0 && next > fatigueMilestone) {
        final span = fatigueTally.add(today);
        if (span.meets(span.running, config.fatigueRunningRatio)) {
          fatigueGain = config.fatigueGainPerSpan;
        }
        fatigueTally = DayTally.empty;
        fatigueMilestone = next;
      }

      s = s.copyWith(
        stats: stats.copyWith(
          strength: stats.strength + str,
          vitality: stats.vitality + vit,
          agility: stats.agility + agi,
        ),
        skillPoints: s.skillPoints + skillPoints,
        highestLevel: next > s.highestLevel ? next : s.highestLevel,
        fatigueMax: s.fatigueMax + fatigueGain,
        fatigueTally: fatigueTally,
        fatigueMilestoneLevel: fatigueMilestone,
        levelTally: DayTally.empty,
      );

      changes.add(LevelChange(
        fromLevel: level,
        toLevel: next,
        strengthDelta: str,
        vitalityDelta: vit,
        agilityDelta: agi,
        skillPointsGained: skillPoints,
        fatigueMaxGained: fatigueGain,
      ));
    }

    return ProgressionResult(s, levelChanges: changes);
  }

  /// Settles a day that has ended: tallies it, recovers fatigue, and applies
  /// the missed-day penalty if no exercise reached its target.
  ProgressionResult finalizeDay(ProgressionState state, DaySummary day) {
    var s = state.copyWith(
      levelTally: state.levelTally.add(day),
      fatigueTally: state.fatigueTally.add(day),
      fatigueCurrent: (state.fatigueCurrent + config.fatigueRecoveryPerDay)
          .clamp(0, state.fatigueMax),
    );

    if (!day.isMissed) {
      return ProgressionResult(s.copyWith(consecutiveMissedDays: 0));
    }

    final misses = s.consecutiveMissedDays + 1;
    final fromLevel = levelOf(s);
    final protected = misses < config.levelProtectionDays;
    final minXp = protected ? leveling.levelFloor(fromLevel) : 0;
    final newXp = s.totalXp - config.missedDayPenaltyXp;
    s = s.copyWith(
      consecutiveMissedDays: misses,
      totalXp: newXp < minXp ? minXp : newXp,
    );

    final toLevel = levelOf(s);
    if (toLevel >= fromLevel) {
      return ProgressionResult(s, missedDaysProcessed: 1);
    }

    final penalty = config.levelDownStatPenalty * (fromLevel - toLevel);
    final stats = s.stats;
    final str = _floored(stats.strength, penalty);
    final vit = _floored(stats.vitality, penalty);
    final agi = _floored(stats.agility, penalty);
    s = s.copyWith(
      stats: stats.copyWith(
        strength: stats.strength + str,
        vitality: stats.vitality + vit,
        agility: stats.agility + agi,
      ),
      levelTally: DayTally.empty,
    );

    return ProgressionResult(
      s,
      missedDaysProcessed: 1,
      levelChanges: [
        LevelChange(
          fromLevel: fromLevel,
          toLevel: toLevel,
          strengthDelta: str,
          vitalityDelta: vit,
          agilityDelta: agi,
        ),
      ],
    );
  }

  /// Settles every day from `lastActiveDate` up to (not including) [today].
  ///
  /// [lastActiveDay] is the recorded progress for `lastActiveDate`, if any;
  /// every later day has no record and so counts as missed. Running this
  /// twice for the same [today] applies nothing the second time.
  ProgressionResult catchUp(
    ProgressionState state,
    DateTime today, {
    DaySummary? lastActiveDay,
  }) {
    final day = dateOnly(today);
    final lastActive = state.lastActiveDate;
    if (lastActive == null) {
      return ProgressionResult(state.copyWith(lastActiveDate: day));
    }

    var s = state;
    final changes = <LevelChange>[];
    var missed = 0;
    var cursor = dateOnly(lastActive);
    var first = true;
    while (cursor.isBefore(day)) {
      final summary =
          first ? (lastActiveDay ?? DaySummary.empty) : DaySummary.empty;
      final result = finalizeDay(s, summary);
      s = result.state;
      changes.addAll(result.levelChanges);
      missed += result.missedDaysProcessed;
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      first = false;
    }

    return ProgressionResult(
      s.copyWith(lastActiveDate: day),
      levelChanges: changes,
      missedDaysProcessed: missed,
    );
  }

  /// Positive delta, limited so the stat never exceeds the cap.
  int _capped(int value, int gain) {
    final room = config.statCap - value;
    return gain > room ? (room < 0 ? 0 : room) : gain;
  }

  /// Negative delta, limited so the stat never drops below the floor.
  int _floored(int value, int penalty) {
    final room = value - config.statFloor;
    return -(penalty > room ? (room < 0 ? 0 : room) : penalty);
  }
}
