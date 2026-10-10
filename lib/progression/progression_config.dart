/// Every tunable number in the progression system lives here.
///
/// Values marked "proposed" are defaults from the progression handoff that
/// have not been confirmed yet; keep them configurable.
class ProgressionConfig {
  // Leveling curve: XP from level L to L+1 = base + linear*L + power*L^exponent
  final double curveBase;
  final double curveLinear;
  final double curvePower;
  final double curveExponent;
  final int maxLevel;

  // XP awards
  final int exerciseTarget; // reps (or 100m units for running)
  final int xpPerExercise;
  final int allCompleteBonusXp;
  final int missedDayPenaltyXp;

  // Level protection: misses below this count are clamped at the level floor.
  final int levelProtectionDays;

  // Stats
  final int skillPointsPerLevel;
  final int startingStat; // proposed
  final int statGainPerLevel; // proposed
  final double statGainCompletionRatio; // proposed
  final int levelDownStatPenalty; // proposed
  final int statFloor; // proposed
  final int statCap;
  final int hpPerVitality; // proposed
  final int mpPerIntelligence; // proposed

  // Fatigue
  final int startingFatigue;
  final int fatigueRecoveryPerDay;
  final int fatigueLevelSpan; // proposed
  final double fatigueRunningRatio; // proposed
  final int fatigueGainPerSpan; // proposed

  const ProgressionConfig({
    this.curveBase = 100,
    this.curveLinear = 18,
    this.curvePower = 2.5,
    this.curveExponent = 1.35,
    this.maxLevel = 100,
    this.exerciseTarget = 100,
    this.xpPerExercise = 100,
    this.allCompleteBonusXp = 100,
    this.missedDayPenaltyXp = 150,
    this.levelProtectionDays = 7,
    this.skillPointsPerLevel = 3,
    this.startingStat = 10,
    this.statGainPerLevel = 2,
    this.statGainCompletionRatio = 0.5,
    this.levelDownStatPenalty = 5,
    this.statFloor = 10,
    this.statCap = 255,
    this.hpPerVitality = 10,
    this.mpPerIntelligence = 5,
    this.startingFatigue = 7,
    this.fatigueRecoveryPerDay = 1,
    this.fatigueLevelSpan = 10,
    this.fatigueRunningRatio = 0.5,
    this.fatigueGainPerSpan = 1,
  });

  static const standard = ProgressionConfig();
}
