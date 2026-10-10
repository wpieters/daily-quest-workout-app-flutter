import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/progression/leveling.dart';
import 'package:daily_quest/progression/progression_config.dart';
import 'package:daily_quest/progression/progression_engine.dart';
import 'package:daily_quest/progression/progression_state.dart';

const fullDay = DaySummary(
    pushups: true, situps: true, squats: true, running: true);
const noRunDay = DaySummary(
    pushups: true, situps: true, squats: true, runningEnabled: false);

void main() {
  final engine = ProgressionEngine();
  final leveling = engine.leveling;
  const config = ProgressionConfig.standard;

  /// Simulates [days] identical days: award the day's XP, then finalize it.
  ProgressionState simulate(ProgressionState s, DaySummary day, int days) {
    for (var i = 0; i < days; i++) {
      s = engine.awardXp(s, engine.dayXp(day), day).state;
      s = engine.finalizeDay(s, day).state;
    }
    return s;
  }

  int daysToMaxLevel(int xpPerDay) =>
      (leveling.levelFloor(100) / xpPerDay).ceil();

  group('Leveling curve', () {
    test('XP per level follows 100 + 18L + 2.5L^1.35, rounded', () {
      expect(leveling.xpToNextLevel(1), 121); // 100 + 18 + 2.5
      expect(leveling.xpToNextLevel(10), 336); // 100 + 180 + 2.5*22.39
      expect(leveling.xpToNextLevel(99), 3118); // 100 + 1782 + 2.5*494.3
    });

    test('total XP to reach level 100 is roughly 152-155k', () {
      expect(leveling.levelFloor(100), inInclusiveRange(150000, 155000));
    });

    test('level 100 takes ~300-350 days at 500 XP/day', () {
      expect(daysToMaxLevel(500), inInclusiveRange(300, 350));
    });

    test('pace: ~a year at 440/day, ~17 months at 300/day', () {
      expect(daysToMaxLevel(440), inInclusiveRange(330, 380));
      expect(daysToMaxLevel(300), inInclusiveRange(490, 530));
    });

    test('levelForXp respects boundaries and caps at max level', () {
      expect(leveling.levelForXp(0), 1);
      expect(leveling.levelForXp(120), 1);
      expect(leveling.levelForXp(121), 2);
      expect(leveling.levelForXp(leveling.levelFloor(50) - 1), 49);
      expect(leveling.levelForXp(leveling.levelFloor(50)), 50);
      expect(leveling.levelForXp(leveling.levelFloor(100) * 2), 100);
    });

    test('xpIntoLevel and span', () {
      expect(leveling.xpIntoLevel(130), 9);
      expect(leveling.xpSpanOfLevel(130), leveling.xpToNextLevel(2));
      expect(leveling.xpSpanOfLevel(leveling.levelFloor(100)), 0);
    });

    test('curve constants are configurable', () {
      final flat = Leveling(const ProgressionConfig(
          curveLinear: 0, curvePower: 0, maxLevel: 10));
      expect(flat.xpToNextLevel(5), 100);
      expect(flat.levelFloor(10), 900);
    });
  });

  group('Titles', () {
    final expected = {
      1: "World's Weakest",
      9: "World's Weakest",
      10: 'Fledgling Warrior',
      19: 'Fledgling Warrior',
      20: 'E-Rank Hunter',
      29: 'E-Rank Hunter',
      30: 'D-Rank Hunter',
      39: 'D-Rank Hunter',
      40: 'C-Rank Hunter',
      49: 'C-Rank Hunter',
      50: 'B-Rank Hunter',
      59: 'B-Rank Hunter',
      60: 'A-Rank Hunter',
      69: 'A-Rank Hunter',
      70: 'National Level Hunter',
      79: 'National Level Hunter',
      80: 'Shadow Sovereign Candidate',
      89: 'Shadow Sovereign Candidate',
      90: 'S-Rank Hunter',
      99: 'S-Rank Hunter',
      100: "World's Strongest Hunter",
    };
    expected.forEach((level, title) {
      test('level $level is $title', () {
        expect(titleForLevel(level), title);
      });
    });

    test('title drops with level', () {
      final s = ProgressionState.initial()
          .copyWith(totalXp: leveling.levelFloor(20));
      expect(engine.titleOf(s), 'E-Rank Hunter');
      expect(engine.titleOf(s.copyWith(totalXp: leveling.levelFloor(20) - 1)),
          'Fledgling Warrior');
    });

    test('LevelChange reports a newly unlocked title only on crossing', () {
      expect(const LevelChange(fromLevel: 9, toLevel: 10).newTitle,
          'Fledgling Warrior');
      expect(const LevelChange(fromLevel: 10, toLevel: 11).newTitle, isNull);
    });
  });

  group('XP awards', () {
    test('a full day is 500 XP', () {
      expect(engine.dayXp(fullDay), 500);
    });

    test('a day without running is 300 XP', () {
      expect(engine.dayXp(noRunDay), 300);
    });

    test('each exercise is worth 100 XP on its own', () {
      expect(engine.dayXp(const DaySummary(pushups: true)), 100);
      expect(engine.dayXp(const DaySummary(pushups: true, squats: true)), 200);
      expect(engine.dayXp(DaySummary.empty), 0);
    });

    test('the bonus requires running to be enabled and completed', () {
      expect(fullDay.earnsBonus, isTrue);
      expect(noRunDay.earnsBonus, isFalse);
      const ranButDisabled = DaySummary(
          pushups: true,
          situps: true,
          squats: true,
          running: true,
          runningEnabled: false);
      expect(ranButDisabled.earnsBonus, isFalse);
    });

    test('fromCounts ignores running when disabled', () {
      final day = DaySummary.fromCounts(
          pushups: 100, situps: 100, squats: 100, running: 100,
          runningEnabled: false);
      expect(day.running, isFalse);
      expect(engine.dayXp(day), 300);
    });

    test('awardXp crosses multiple levels in one go', () {
      final result = engine.awardXp(ProgressionState.initial(), 500, fullDay);
      expect(engine.levelOf(result.state), 4); // 121 + 142 + 165 = 428
      expect(result.levelChanges.map((c) => c.toLevel), [2, 3, 4]);
    });

    test('3 skill points per level, only for new highest levels', () {
      var s = engine.awardXp(ProgressionState.initial(), 500, fullDay).state;
      expect(s.skillPoints, 9);
      // Drop a level, then climb back: no skill points the second time.
      s = s.copyWith(
          totalXp: leveling.levelFloor(3), consecutiveMissedDays: 0);
      s = engine.awardXp(s, leveling.xpToNextLevel(3), fullDay).state;
      expect(engine.levelOf(s), 4);
      expect(s.skillPoints, 9);
    });
  });

  group('Missed days and level protection', () {
    ProgressionState atFloorOf(int level) => ProgressionState.initial()
        .copyWith(totalXp: leveling.levelFloor(level), highestLevel: level);

    ProgressionState missDays(ProgressionState s, int n) {
      for (var i = 0; i < n; i++) {
        s = engine.finalizeDay(s, DaySummary.empty).state;
      }
      return s;
    }

    test('a missed day costs 150 XP', () {
      final s = atFloorOf(10).copyWith(totalXp: leveling.levelFloor(10) + 200);
      expect(missDays(s, 1).totalXp, leveling.levelFloor(10) + 50);
    });

    test('6 consecutive misses do not drop a level', () {
      final s = missDays(atFloorOf(10), 6);
      expect(engine.levelOf(s), 10);
      expect(s.totalXp, leveling.levelFloor(10));
      expect(s.consecutiveMissedDays, 6);
    });

    test('the 7th consecutive miss can drop a level', () {
      final s = missDays(atFloorOf(10), 7);
      expect(engine.levelOf(s), 9);
      expect(s.totalXp, leveling.levelFloor(10) - 150);
    });

    test('protected penalties are not banked', () {
      // Lots of XP into the level: misses 1-6 eat into it, clamped at floor.
      final s = missDays(
          atFloorOf(10).copyWith(totalXp: leveling.levelFloor(10) + 100), 7);
      expect(s.totalXp, leveling.levelFloor(10) - 150);
    });

    test('partial days are not penalised and reset the miss counter', () {
      var s = missDays(atFloorOf(10), 6);
      s = engine.finalizeDay(s, const DaySummary(squats: true)).state;
      expect(s.consecutiveMissedDays, 0);
      s = missDays(s, 6);
      expect(engine.levelOf(s), 10);
    });

    test('a day with progress but no completed exercise is a miss', () {
      final s = engine.finalizeDay(atFloorOf(10), DaySummary.empty).state;
      expect(s.consecutiveMissedDays, 1);
    });

    test('XP never goes below zero', () {
      final s = missDays(ProgressionState.initial(), 20);
      expect(s.totalXp, 0);
      expect(engine.levelOf(s), 1);
    });
  });

  group('Stats', () {
    test('start at 10 each; HP and MP are derived', () {
      final s = ProgressionState.initial();
      expect(s.stats.strength, 10);
      expect(s.stats.intelligence, 10);
      expect(s.stats.perception, 10);
      expect(s.stats.hp(config), 100);
      expect(s.stats.mp(config), 50);
    });

    test('+2 to each stat whose exercise was done on >=50% of level days', () {
      final s = engine
          .awardXp(ProgressionState.initial(), 121, const DaySummary(
              pushups: true, situps: true))
          .state;
      expect(s.stats.strength, 12);
      expect(s.stats.vitality, 12);
      expect(s.stats.agility, 10);
    });

    test('the 50% rule counts days spent in the level', () {
      var s = ProgressionState.initial();
      // Two finished days at level 1: squats on one, pushups on neither.
      s = engine.finalizeDay(s, const DaySummary(squats: true)).state;
      s = engine.finalizeDay(s, const DaySummary(situps: true)).state;
      // Level-up day: situps + squats so far. Squats 2/3, situps 2/3.
      s = engine
          .awardXp(s, 121, const DaySummary(situps: true, squats: true))
          .state;
      expect(s.stats.strength, 10);
      expect(s.stats.vitality, 12);
      expect(s.stats.agility, 12);
    });

    test('INT and PER never grow from leveling', () {
      final s = simulate(ProgressionState.initial(), fullDay, 60);
      expect(s.stats.intelligence, 10);
      expect(s.stats.perception, 10);
    });

    test('consistent training reaches ~210 by level 100, under the cap', () {
      final s = simulate(ProgressionState.initial(), fullDay, 400);
      expect(engine.levelOf(s), 100);
      expect(s.stats.strength, 10 + 99 * 2);
      expect(s.stats.strength, lessThanOrEqualTo(config.statCap));
      expect(s.skillPoints, 99 * 3);
    });

    test('stats never exceed the cap', () {
      final s = ProgressionState.initial().copyWith(
          stats: const CharacterStats(
              strength: 254,
              vitality: 255,
              agility: 10,
              intelligence: 10,
              perception: 10));
      final result = engine.awardXp(s, 121, fullDay);
      expect(result.state.stats.strength, 255);
      expect(result.state.stats.vitality, 255);
      expect(result.levelChanges.single.strengthDelta, 1);
    });

    test('losing a level costs 5 STR/VIT/AGI, floored at 10', () {
      final s = ProgressionState.initial().copyWith(
        totalXp: leveling.levelFloor(10),
        consecutiveMissedDays: 6,
        stats: const CharacterStats(
            strength: 30,
            vitality: 12,
            agility: 10,
            intelligence: 10,
            perception: 10),
      );
      final result = engine.finalizeDay(s, DaySummary.empty);
      expect(engine.levelOf(result.state), 9);
      expect(result.state.stats.strength, 25);
      expect(result.state.stats.vitality, 10);
      expect(result.state.stats.agility, 10);
      final change = result.levelChanges.single;
      expect(change.isLevelUp, isFalse);
      expect(change.strengthDelta, -5);
      expect(change.vitalityDelta, -2);
    });

    test('penalty scales with levels lost in one missed day', () {
      // Low levels are cheaper than 150 XP? No: L1->2 is 121, so a 150 XP
      // penalty from the floor of level 3 can only cost one level. Use a
      // config with a tiny curve to cross two levels at once.
      final tiny = ProgressionEngine(const ProgressionConfig(
          curveBase: 50, curveLinear: 0, curvePower: 0));
      final s = ProgressionState.initial().copyWith(
        totalXp: tiny.leveling.levelFloor(5),
        consecutiveMissedDays: 6,
        stats: const CharacterStats(
            strength: 50,
            vitality: 50,
            agility: 50,
            intelligence: 10,
            perception: 10),
      );
      final result = tiny.finalizeDay(s, DaySummary.empty);
      expect(tiny.levelOf(result.state), 2); // 200 - 150 = 50 => level 2
      expect(result.state.stats.strength, 35);
    });
  });

  group('Fatigue', () {
    test('starts at 7 and recovers 1 per day up to max', () {
      var s = ProgressionState.initial();
      expect(s.fatigueCurrent, 7);
      expect(s.fatigueMax, 7);
      s = s.copyWith(fatigueCurrent: 5);
      s = engine.finalizeDay(s, fullDay).state;
      expect(s.fatigueCurrent, 6);
      s = engine.finalizeDay(s, fullDay).state;
      s = engine.finalizeDay(s, fullDay).state;
      expect(s.fatigueCurrent, 7);
    });

    test('max grows by 1 per 10 levels for runners, up to 17', () {
      final s = simulate(ProgressionState.initial(), fullDay, 400);
      expect(s.fatigueMax, 17);
    });

    test('max does not grow without running', () {
      final s = simulate(ProgressionState.initial(), noRunDay, 600);
      expect(engine.levelOf(s), 100);
      expect(s.fatigueMax, 7);
    });

    test('milestones are not re-earned after dropping and re-climbing', () {
      var s = simulate(ProgressionState.initial(), fullDay, 4);
      expect(engine.levelOf(s), 10);
      expect(s.fatigueMax, 8);
      s = s.copyWith(totalXp: leveling.levelFloor(9));
      s = simulate(s, fullDay, 1);
      expect(engine.levelOf(s), 10);
      expect(s.fatigueMax, 8);
    });
  });

  group('catchUp', () {
    final monday = DateTime(2026, 10, 5);

    ProgressionState activeOn(DateTime d, int level) => ProgressionState.initial()
        .copyWith(totalXp: leveling.levelFloor(level), lastActiveDate: d);

    test('first run just records today', () {
      final result =
          engine.catchUp(ProgressionState.initial(), monday.add(const Duration(hours: 9)));
      expect(result.state.lastActiveDate, monday);
      expect(result.missedDaysProcessed, 0);
    });

    test('same day: nothing to settle', () {
      final result = engine.catchUp(activeOn(monday, 10), monday);
      expect(result.missedDaysProcessed, 0);
      expect(result.state.totalXp, leveling.levelFloor(10));
    });

    test('settles the last active day using its record', () {
      final result = engine.catchUp(
          activeOn(monday, 10), monday.add(const Duration(days: 1)),
          lastActiveDay: fullDay);
      expect(result.missedDaysProcessed, 0);
      expect(result.state.levelTally.days, 1);
    });

    test('skipped days after the last active day count as misses', () {
      final s = activeOn(monday, 10)
          .copyWith(totalXp: leveling.levelFloor(10) + 300);
      // Active Monday (did pushups), opens again Friday: Tue-Thu missed.
      final result = engine.catchUp(s, DateTime(2026, 10, 9),
          lastActiveDay: const DaySummary(pushups: true));
      expect(result.missedDaysProcessed, 3);
      expect(result.state.consecutiveMissedDays, 3);
      expect(result.state.totalXp, leveling.levelFloor(10)); // 300 - 450, clamped
      expect(result.state.lastActiveDate, DateTime(2026, 10, 9));
    });

    test('a long absence drops levels from the 7th miss on', () {
      final result = engine.catchUp(
          activeOn(monday, 10), monday.add(const Duration(days: 10)));
      // Monday itself had no record, so it is a miss too: 10 misses.
      expect(result.missedDaysProcessed, 10);
      expect(engine.levelOf(result.state), lessThan(10));
      expect(result.levelChanges, isNotEmpty);
      expect(result.levelChanges.every((c) => !c.isLevelUp), isTrue);
    });

    test('penalties are applied exactly once', () {
      final friday = DateTime(2026, 10, 9, 8);
      final first = engine.catchUp(activeOn(monday, 10), friday);
      final again = engine.catchUp(first.state, friday.add(const Duration(hours: 6)));
      expect(again.missedDaysProcessed, 0);
      expect(again.state.totalXp, first.state.totalXp);
      expect(again.state.consecutiveMissedDays,
          first.state.consecutiveMissedDays);
    });

    test('handles month and DST boundaries by calendar day', () {
      final result = engine.catchUp(
          activeOn(DateTime(2026, 3, 28), 10), DateTime(2026, 4, 2));
      expect(result.missedDaysProcessed, 5);
    });
  });

  group('Serialization', () {
    test('round-trips through JSON', () {
      final s = simulate(ProgressionState.initial(), fullDay, 12)
          .copyWith(lastActiveDate: DateTime(2026, 10, 10));
      final restored = ProgressionState.fromJson(s.toJson());
      expect(restored.toJson(), s.toJson());
    });

    test('missing JSON yields starting values', () {
      final s = ProgressionState.fromJson(null);
      expect(s.totalXp, 0);
      expect(s.stats.strength, 10);
      expect(s.fatigueMax, 7);
      expect(s.lastActiveDate, isNull);
    });
  });
}
