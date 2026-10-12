import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/models/reminder_settings.dart';
import 'package:daily_quest/providers/reminder_provider.dart';
import 'package:daily_quest/providers/workout_provider.dart';
import 'package:daily_quest/services/reminder_service.dart';

import '../fakes/fake_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReminderService fake;

  Future<(ProviderContainer, ReminderNotifier)> open() async {
    final container = ProviderContainer(overrides: [
      reminderServiceProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
    ]);
    final notifier = container.read(reminderProvider.notifier);
    await notifier.ready;
    return (container, notifier);
  }

  Future<Map<String, dynamic>?> stored() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('reminder_settings');
    return s == null ? null : jsonDecode(s);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = FakeReminderService();
  });

  group('Availability', () {
    test('is hidden when the service is unavailable', () async {
      fake.available = false;
      final (c, _) = await open();
      expect(c.read(reminderProvider).hidden, isTrue);
      expect(fake.calls, isEmpty);
    });

    test('is off but offered when available', () async {
      final (c, _) = await open();
      expect(c.read(reminderProvider).status, ReminderStatus.off);
      expect(c.read(reminderProvider).hidden, isFalse);
    });
  });

  group('Enable and disable', () {
    test('enabling asks the service with the saved times and persists',
        () async {
      final (c, n) = await open();
      await n.enable();

      final s = c.read(reminderProvider);
      expect(s.status, ReminderStatus.on);
      expect(s.settings.enabled, isTrue);
      expect(fake.calls, ['status', 'enable']);
      expect(fake.synced.single.apiTimes['morning'], '07:00');
      expect((await stored())!['enabled'], isTrue);
    });

    test('a refused permission leaves reminders off with an error', () async {
      fake.grantsOn = false;
      final (c, n) = await open();
      await n.enable();

      final s = c.read(reminderProvider);
      expect(s.status, ReminderStatus.denied);
      expect(s.settings.enabled, isFalse);
      expect(s.error, contains('blocked'));
      expect(await stored(), isNull);
    });

    test('a failing backend is reported, not thrown', () async {
      final (c, n) = await open();
      fake.failure = Exception('503');
      await n.enable();

      final s = c.read(reminderProvider);
      expect(s.settings.enabled, isFalse);
      expect(s.busy, isFalse);
      expect(s.error, contains('503'));
    });

    test('disabling unsubscribes and persists', () async {
      final (c, n) = await open();
      await n.enable();
      await n.disable();

      expect(c.read(reminderProvider).status, ReminderStatus.off);
      expect(fake.calls.last, 'disable');
      expect((await stored())!['enabled'], isFalse);
    });
  });

  group('Slots', () {
    test('changing a time syncs only while enabled', () async {
      final (c, n) = await open();
      await n.setSlot(ReminderSlot.evening, const ReminderTime(21, 0));
      expect(fake.calls, ['status']);

      await n.enable();
      await n.setSlot(ReminderSlot.afternoon, null);

      expect(fake.calls.last, 'sync');
      final sent = fake.synced.last.apiTimes;
      expect(sent, {'morning': '07:00', 'afternoon': null, 'evening': '21:00'});
      expect(c.read(reminderProvider).settings[ReminderSlot.afternoon], isNull);
      expect((await stored())!['times']['evening'], '21:00');
    });
  });

  group('Launch', () {
    test('re-syncs an enabled subscription so the server copy stays fresh',
        () async {
      SharedPreferences.setMockInitialValues({
        'reminder_settings': jsonEncode({
          'enabled': true,
          'times': {'morning': '06:30', 'afternoon': null, 'evening': '20:00'},
        }),
      });
      fake.current = ReminderStatus.on;
      final (c, _) = await open();

      expect(fake.calls, ['status', 'sync']);
      expect(fake.synced.single.apiTimes['morning'], '06:30');
      expect(c.read(reminderProvider).settings.enabled, isTrue);
    });

    test('turns itself off when the browser lost the subscription', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_settings': jsonEncode({'enabled': true, 'times': {}}),
      });
      fake.current = ReminderStatus.off;
      final (c, _) = await open();

      expect(c.read(reminderProvider).settings.enabled, isFalse);
      expect((await stored())!['enabled'], isFalse);
      expect(fake.calls, ['status']);
    });
  });

  group('Completion hook', () {
    Future<WorkoutNotifier> openWorkout() async {
      final container = ProviderContainer(overrides: [
        reminderServiceProvider.overrideWithValue(fake),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
      ]);
      final n = container.read(workoutProvider.notifier);
      await n.ready;
      return n;
    }

    Future<void> finish(WorkoutNotifier n) async {
      // Running is on by default; the day only completes without it.
      await n.toggleRunning();
      for (final e in [
        ExerciseType.pushups,
        ExerciseType.situps,
        ExerciseType.squats
      ]) {
        for (var i = 0; i < 100; i++) {
          await n.incrementExercise(e);
        }
      }
    }

    test('reports the first completion of the day exactly once', () async {
      final n = await openWorkout();
      await finish(n);
      // Let the fire-and-forget call land.
      await Future<void>.delayed(Duration.zero);

      expect(fake.completed, [DateTime(2026, 10, 12)]);

      // Undo and redo: still complete once.
      await n.decrementExercise(ExerciseType.squats);
      await n.incrementExercise(ExerciseType.squats);
      await Future<void>.delayed(Duration.zero);
      expect(fake.completed, hasLength(1));
    });

    test('a failing report never surfaces to the workout', () async {
      fake.failure = Exception('offline');
      final n = await openWorkout();
      await finish(n);
      await Future<void>.delayed(Duration.zero);
      // Reaching here without an unhandled error is the assertion.
      expect(fake.calls, contains('complete'));
    });
  });
}
