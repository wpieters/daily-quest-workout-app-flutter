import 'dart:math' as math;

import 'progression_config.dart';

/// Title thresholds, highest first. A title is derived from level, never stored.
const List<(int, String)> titleThresholds = [
  (100, "World's Strongest Hunter"),
  (90, 'S-Rank Hunter'),
  (80, 'Shadow Sovereign Candidate'),
  (70, 'National Level Hunter'),
  (60, 'A-Rank Hunter'),
  (50, 'B-Rank Hunter'),
  (40, 'C-Rank Hunter'),
  (30, 'D-Rank Hunter'),
  (20, 'E-Rank Hunter'),
  (10, 'Fledgling Warrior'),
  (1, "World's Weakest"),
];

String titleForLevel(int level) {
  for (final (threshold, title) in titleThresholds) {
    if (level >= threshold) return title;
  }
  return titleThresholds.last.$2;
}

/// The XP curve: levels 1..maxLevel, with cumulative XP thresholds precomputed.
class Leveling {
  final ProgressionConfig config;
  final List<int> _levelFloors; // index L-1 => total XP needed to reach level L

  Leveling([this.config = ProgressionConfig.standard])
      : _levelFloors = _buildFloors(config);

  static List<int> _buildFloors(ProgressionConfig c) {
    final floors = <int>[0];
    for (var level = 1; level < c.maxLevel; level++) {
      floors.add(floors.last + _xpToNext(c, level));
    }
    return floors;
  }

  static int _xpToNext(ProgressionConfig c, int level) {
    return (c.curveBase +
            c.curveLinear * level +
            c.curvePower * math.pow(level, c.curveExponent))
        .round();
  }

  /// XP needed to go from [level] to level + 1.
  int xpToNextLevel(int level) => _xpToNext(config, level);

  /// Total XP at which [level] is reached.
  int levelFloor(int level) =>
      _levelFloors[level.clamp(1, config.maxLevel) - 1];

  int levelForXp(int totalXp) {
    var level = 1;
    while (level < config.maxLevel && totalXp >= _levelFloors[level]) {
      level++;
    }
    return level;
  }

  /// XP earned within the current level.
  int xpIntoLevel(int totalXp) => totalXp - levelFloor(levelForXp(totalXp));

  /// XP the current level spans; 0 once the max level is reached.
  int xpSpanOfLevel(int totalXp) {
    final level = levelForXp(totalXp);
    return level >= config.maxLevel ? 0 : xpToNextLevel(level);
  }
}
