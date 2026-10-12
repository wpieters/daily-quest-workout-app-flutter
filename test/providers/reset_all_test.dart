import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/providers/reminder_provider.dart';
import 'package:daily_quest/providers/workout_provider.dart';
import 'package:daily_quest/services/reminder_service.dart';

import '../fakes/fake_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resetAll wipes progress, today and reminder settings', () async {
    SharedPreferences.setMockInitialValues({
      'reminder_settings': jsonEncode({'enabled': false, 'times': {}}),
    });
    final fake = FakeReminderService();
    final container = ProviderContainer(overrides: [
      reminderServiceProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
    ]);
    final workout = container.read(workoutProvider.notifier);
    await workout.ready;
    final reminders = container.read(reminderProvider.notifier);
    await reminders.ready;

    // Build up some state worth losing.
    for (var i = 0; i < 100; i++) {
      await workout.incrementExercise(ExerciseType.pushups);
    }
    await reminders.enable();
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_progress'), isNotNull);
    expect(prefs.getString('today_workout'), isNotNull);
    expect(jsonDecode(prefs.getString('reminder_settings')!)['enabled'], true);
    expect(container.read(workoutProvider).progress.progression.totalXp,
        greaterThan(0));

    await reminders.disable();
    await workout.resetAll();
    await reminders.reload();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_progress'), isNull);
    expect(prefs.getString('today_workout'), isNull);
    expect(prefs.getString('reminder_settings'), isNull);

    final state = container.read(workoutProvider);
    expect(state.currentDay.pushups, 0);
    expect(state.currentDay.xpEarned, 0);
    expect(state.progress.progression.totalXp, 0);
    expect(state.progress.currentStreak, 0);
    expect(state.progress.history, isEmpty);
    expect(state.isLoading, isFalse);

    expect(container.read(reminderProvider).settings.enabled, isFalse);
    expect(fake.calls.last, 'status');
    expect(fake.current, ReminderStatus.off);
  });
}
