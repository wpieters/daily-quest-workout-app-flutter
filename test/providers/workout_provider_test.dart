import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/models/user_progress.dart';
import 'package:daily_quest/progression/leveling.dart';
import 'package:daily_quest/progression/progression_state.dart';
import 'package:daily_quest/providers/workout_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final leveling = Leveling();
  late DateTime now;

  Future<(ProviderContainer, WorkoutNotifier)> open() async {
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
    ]);
    final notifier = container.read(workoutProvider.notifier);
    await notifier.ready;
    return (container, notifier);
  }

  Future<Map<String, dynamic>> storedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return jsonDecode(prefs.getString('user_progress')!);
  }

  Future<void> tap(WorkoutNotifier n, ExerciseType e, int times) async {
    for (var i = 0; i < times; i++) {
      await n.incrementExercise(e);
    }
  }

  setUp(() {
    now = DateTime(2026, 10, 9, 18, 30); // a Friday
  });

  group('Migration from v1 data', () {
    final v1Progress = {
      'currentStreak': 3,
      'longestStreak': 5,
      'totalWorkouts': 12,
      'history': [
        {
          'date': '2026-10-08T07:00:00.000',
          'pushups': 100,
          'situps': 100,
          'squats': 100,
          'running': 0,
          'runningEnabled': false,
          'completed': true,
        },
      ],
    };

    test('keeps history and streaks, starts progression fresh', () async {
      SharedPreferences.setMockInitialValues({
        'user_progress': jsonEncode(v1Progress),
      });
      final (c, _) = await open();
      final state = c.read(workoutProvider);

      expect(state.progress.currentStreak, 3);
      expect(state.progress.longestStreak, 5);
      expect(state.progress.totalWorkouts, 12);
      expect(state.progress.history, hasLength(1));
      expect(state.progress.history.single.completed, isTrue);

      final p = state.progress.progression;
      expect(p.totalXp, 0);
      expect(p.stats.strength, 10);
      expect(p.fatigueMax, 7);
      expect(p.consecutiveMissedDays, 0);
      expect(p.lastActiveDate, DateTime(2026, 10, 9));

      final saved = await storedProgress();
      expect(saved['schemaVersion'], UserProgress.schemaVersion);
      expect(saved['progression']['lastActiveDate'], isNotNull);
    });

    test('a stale v1 day causes no retroactive penalties', () async {
      SharedPreferences.setMockInitialValues({
        'user_progress': jsonEncode(v1Progress),
        'today_workout': jsonEncode({
          'date': '2026-10-01T09:00:00.000',
          'pushups': 40,
          'situps': 0,
          'squats': 0,
          'running': 0,
          'runningEnabled': true,
          'completed': false,
        }),
      });
      final (c, _) = await open();
      final state = c.read(workoutProvider);

      expect(state.progress.progression.consecutiveMissedDays, 0);
      expect(state.currentDay.date, DateTime(2026, 10, 9));
      expect(state.currentDay.pushups, 0);
      // The stale day had activity, so it is kept in history.
      expect(state.progress.history, hasLength(2));
    });

    test("awards XP for today's pre-upgrade progress once", () async {
      SharedPreferences.setMockInitialValues({
        'user_progress': jsonEncode(v1Progress),
        'today_workout': jsonEncode({
          'date': '2026-10-09T07:00:00.000',
          'pushups': 100,
          'situps': 100,
          'squats': 0,
          'running': 0,
          'runningEnabled': true,
          'completed': false,
        }),
      });
      var (c, _) = await open();
      expect(c.read(workoutProvider).progress.progression.totalXp, 200);

      (c, _) = await open();
      expect(c.read(workoutProvider).progress.progression.totalXp, 200);
    });
  });

  group('XP awards', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a full day earns 500 XP and queues level-ups', () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.pushups, 100);
      expect(c.read(workoutProvider).progress.progression.totalXp, 100);
      await tap(n, ExerciseType.situps, 100);
      await tap(n, ExerciseType.squats, 100);
      expect(c.read(workoutProvider).progress.progression.totalXp, 300);
      await tap(n, ExerciseType.running, 100);

      final state = c.read(workoutProvider);
      expect(state.progress.progression.totalXp, 500);
      expect(state.currentDay.xpEarned, 500);
      expect(state.currentDay.bonusAwarded, isTrue);
      expect(state.lastXpGain, 200); // running + bonus together
      expect(state.pendingLevelUps.map((l) => l.toLevel), [2, 3, 4]);

      n.dismissLevelUp();
      expect(c.read(workoutProvider).pendingLevelUps.first.toLevel, 3);
    });

    test('a day without running earns 300 XP and no bonus', () async {
      final (c, n) = await open();
      await n.toggleRunning();
      await tap(n, ExerciseType.pushups, 100);
      await tap(n, ExerciseType.situps, 100);
      await tap(n, ExerciseType.squats, 100);
      await tap(n, ExerciseType.running, 5);

      final state = c.read(workoutProvider);
      expect(state.currentDay.running, 0);
      expect(state.currentDay.isComplete, isTrue);
      expect(state.progress.progression.totalXp, 300);
      expect(state.currentDay.bonusAwarded, isFalse);
    });

    test('resetting the day does not re-award XP', () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.pushups, 100);
      await n.resetDay();
      await tap(n, ExerciseType.pushups, 100);
      expect(c.read(workoutProvider).progress.progression.totalXp, 100);
    });
  });

  group('Minus button', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('floors at zero', () async {
      final (c, n) = await open();
      await n.decrementExercise(ExerciseType.pushups);
      expect(c.read(workoutProvider).currentDay.pushups, 0);
      await tap(n, ExerciseType.pushups, 3);
      await n.decrementExercise(ExerciseType.pushups);
      expect(c.read(workoutProvider).currentDay.pushups, 2);
    });

    test('does nothing to running while running is disabled', () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.running, 3);
      await n.toggleRunning();
      await n.decrementExercise(ExerciseType.running);
      expect(c.read(workoutProvider).currentDay.running, 3);
    });

    test('undoing a rep keeps XP and re-completing does not re-award',
        () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.pushups, 100);
      await n.decrementExercise(ExerciseType.pushups);

      var state = c.read(workoutProvider);
      expect(state.currentDay.pushups, 99);
      expect(state.progress.progression.totalXp, 100);

      await n.incrementExercise(ExerciseType.pushups);
      state = c.read(workoutProvider);
      expect(state.progress.progression.totalXp, 100);
      expect(state.xpGainId, 1);
    });

    test('re-completing the day does not replay the celebration', () async {
      final (c, n) = await open();
      await n.toggleRunning();
      await tap(n, ExerciseType.pushups, 100);
      await tap(n, ExerciseType.situps, 100);
      await tap(n, ExerciseType.squats, 100);
      expect(c.read(workoutProvider).showCompletionAnimation, isTrue);
      expect(c.read(workoutProvider).lastCompletedStage, -1,
          reason: 'the stage-10 popup yields to the daily power-up');
      n.hideCompletionAnimation();

      await n.decrementExercise(ExerciseType.squats);
      await n.incrementExercise(ExerciseType.squats);

      final state = c.read(workoutProvider);
      expect(state.currentDay.isComplete, isTrue);
      expect(state.showCompletionAnimation, isFalse);
      expect(state.progress.totalWorkouts, 1);
    });
  });

  group('Sets of ten (long press)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('adds ten, lands on the stage and fires its popup once', () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.squats, 3);
      await n.incrementExercise(ExerciseType.squats, by: 10);
      final state = c.read(workoutProvider);
      expect(state.currentDay.squats, 13);
      expect(state.lastCompletedStage, 1);
      expect(state.lastCompletedExercise, ExerciseType.squats);
      expect(state.progress.progression.totalXp, 0,
          reason: 'XP is awarded on reaching the target, not per set');
    });

    test('clamps at the target and completes the day', () async {
      final (c, n) = await open();
      await n.toggleRunning();
      await tap(n, ExerciseType.pushups, 100);
      await tap(n, ExerciseType.situps, 100);
      await tap(n, ExerciseType.squats, 95);
      await n.incrementExercise(ExerciseType.squats, by: 10);
      final state = c.read(workoutProvider);
      expect(state.currentDay.squats, 100);
      expect(state.currentDay.isComplete, isTrue);
      expect(state.showCompletionAnimation, isTrue);
      expect(state.progress.progression.totalXp, 300);
    });

    test('removes ten, floored at zero', () async {
      final (c, n) = await open();
      await tap(n, ExerciseType.pushups, 23);
      await n.decrementExercise(ExerciseType.pushups, by: 10);
      expect(c.read(workoutProvider).currentDay.pushups, 13);
      await n.decrementExercise(ExerciseType.pushups, by: 10);
      await n.decrementExercise(ExerciseType.pushups, by: 10);
      expect(c.read(workoutProvider).currentDay.pushups, 0);
    });
  });

  group('Missed days', () {
    ProgressionState activeMonday() => ProgressionState.initial().copyWith(
          totalXp: leveling.levelFloor(10) + 300,
          highestLevel: 10,
          lastActiveDate: DateTime(2026, 10, 5),
        );

    void seed(ProgressionState p, Map<String, dynamic> day) {
      SharedPreferences.setMockInitialValues({
        'user_progress': jsonEncode(
            UserProgress.initial().copyWith(progression: p).toJson()),
        'today_workout': jsonEncode(day),
      });
    }

    test('skipping app opens applies penalties exactly once', () async {
      // Did push-ups Monday, next open is Friday: Tue, Wed, Thu missed.
      seed(activeMonday(), {
        'date': '2026-10-05T07:00:00.000',
        'pushups': 100,
        'situps': 30,
        'squats': 0,
        'running': 0,
        'runningEnabled': true,
        'xpEarned': 100,
      });

      var (c, n) = await open();
      var p = c.read(workoutProvider).progress.progression;
      expect(p.consecutiveMissedDays, 3);
      expect(p.totalXp, leveling.levelFloor(10)); // -450, clamped at floor
      expect(p.lastActiveDate, DateTime(2026, 10, 9));
      expect(c.read(workoutProvider).progress.history.single.pushups, 100);

      // Calling rollover again, and reopening the app, changes nothing.
      await n.rollover();
      (c, n) = await open();
      p = c.read(workoutProvider).progress.progression;
      expect(p.consecutiveMissedDays, 3);
      expect(p.totalXp, leveling.levelFloor(10));
    });

    test('a week away drops a level', () async {
      seed(activeMonday(), {
        'date': '2026-10-05T07:00:00.000',
        'pushups': 10,
        'runningEnabled': true,
      });
      now = DateTime(2026, 10, 13, 8);

      final (c, _) = await open();
      final p = c.read(workoutProvider).progress.progression;
      expect(p.consecutiveMissedDays, 8); // Mon (partial, no target) .. Mon
      expect(leveling.levelForXp(p.totalXp), 9);
      expect(p.stats.strength, 10); // penalty floored at 10
    });

    test('midnight rollover while the app is open', () async {
      SharedPreferences.setMockInitialValues({});
      final (c, n) = await open();
      await tap(n, ExerciseType.squats, 100);

      now = DateTime(2026, 10, 10, 0, 0, 1);
      await n.rollover();

      final state = c.read(workoutProvider);
      expect(state.currentDay.date, DateTime(2026, 10, 10));
      expect(state.currentDay.squats, 0);
      expect(state.currentDay.xpEarned, 0);
      expect(state.progress.history.single.squats, 100);
      expect(state.progress.progression.consecutiveMissedDays, 0);
      expect(state.progress.progression.levelTally.days, 1);
    });

    test('a tap after midnight settles the old day first', () async {
      SharedPreferences.setMockInitialValues({});
      final (c, n) = await open();
      await tap(n, ExerciseType.pushups, 50);

      now = DateTime(2026, 10, 10, 6);
      await n.incrementExercise(ExerciseType.pushups);

      final state = c.read(workoutProvider);
      expect(state.currentDay.pushups, 1);
      expect(state.progress.progression.consecutiveMissedDays, 1);
    });
  });
}
