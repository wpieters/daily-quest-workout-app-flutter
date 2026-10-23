import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/models/backup.dart';
import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/providers/reminder_provider.dart';
import 'package:daily_quest/providers/workout_provider.dart';
import 'package:daily_quest/screens/settings_screen.dart';
import 'package:daily_quest/services/backup_service.dart';
import 'package:daily_quest/services/daily_reset_service.dart';
import 'package:daily_quest/services/reminder_service.dart';

import 'fakes/fake_backup_service.dart';
import 'fakes/fake_reminder_service.dart';

void main() {
  late FakeBackupService backup;
  late FakeReminderService reminders;
  final now = DateTime(2026, 10, 23, 18, 30);

  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupServiceProvider.overrideWithValue(backup),
          reminderServiceProvider.overrideWithValue(reminders),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    await container.read(workoutProvider.notifier).ready;
    await tester.pump();
    return container;
  }

  void finish(ProviderContainer container) =>
      container.read(dailyResetServiceProvider).dispose();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = FakeBackupService();
    reminders = FakeReminderService();
  });

  testWidgets('hides the section when files cannot move', (tester) async {
    backup.available = false;
    final container = await pumpSettings(tester);
    expect(find.text('Export backup'), findsNothing);
    finish(container);
  });

  testWidgets('export downloads a decodable file and records the date', (
    tester,
  ) async {
    final container = await pumpSettings(tester);
    final workout = container.read(workoutProvider.notifier);
    await workout.incrementExercise(ExerciseType.squats, by: 10);
    expect(
      find.text('Never exported. Save a copy of your progress.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Export backup'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(backup.downloads, hasLength(1));
    final (name, text) = backup.downloads.single;
    expect(name, 'dailyquest-backup-2026-10-23.json');
    final decoded = Backup.decode(text);
    expect(decoded.data['today_workout']!['squats'], 10);
    expect(decoded.data['user_progress'], isNotNull);
    expect(find.text('Last export: 23/10/2026'), findsOneWidget);
    expect(find.text('Backup exported'), findsOneWidget);
    finish(container);
  });

  testWidgets('import asks first, then replaces state', (tester) async {
    final container = await pumpSettings(tester);
    final workout = container.read(workoutProvider.notifier);
    await workout.incrementExercise(ExerciseType.pushups, by: 10);

    backup.nextFile = Backup(
      exportedAt: DateTime.utc(2026, 10, 20),
      data: {
        'user_progress': {
          'schemaVersion': 2,
          'currentStreak': 38,
          'longestStreak': 38,
          'totalWorkouts': 41,
          // Yesterday completed, so the streak survives the reload.
          'history': [
            {
              'date': '2026-10-22T07:00:00.000',
              'pushups': 100,
              'situps': 100,
              'squats': 100,
              'running': 0,
              'runningEnabled': false,
              'completed': true,
            },
          ],
          'progression': {'totalXp': 6000, 'lastActiveDate': '2026-10-23'},
        },
        'today_workout': {
          'date': '2026-10-23T07:00:00.000',
          'squats': 55,
          'runningEnabled': false,
        },
        'reminder_settings': {
          'enabled': true,
          'times': {'morning': '06:30'},
        },
      },
    ).encode();

    await tester.tap(find.text('Import backup'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('38-day streak, 41 workouts'), findsOneWidget);
    expect(find.textContaining('exported 20/10/2026'), findsOneWidget);

    // Cancel leaves things alone.
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(workoutProvider).currentDay.pushups, 10);

    await tester.tap(find.text('Import backup'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Replace'));
    await tester.pump(const Duration(milliseconds: 200));

    final state = container.read(workoutProvider);
    expect(state.currentDay.squats, 55);
    expect(state.currentDay.pushups, 0);
    expect(state.progress.currentStreak, 38);
    expect(state.progress.totalWorkouts, 41);
    expect(state.progress.progression.totalXp, 6000);
    // Reminders were on in the backup but this device isn't subscribed, so
    // the reload turns the switch off and keeps the time.
    final rs = container.read(reminderProvider).settings;
    expect(rs.enabled, isFalse);
    expect(rs.apiTimes['morning'], '06:30');
    expect(find.text('Backup imported'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('user_progress')!)['totalWorkouts'], 41);
    finish(container);
  });

  testWidgets('a bad file is refused with the reason', (tester) async {
    final container = await pumpSettings(tester);
    backup.nextFile = '{"app":"other"}';
    await tester.tap(find.text('Import backup'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Cannot import: This is not a DailyQuest backup.'),
      findsOneWidget,
    );
    expect(find.text('Replace'), findsNothing);
    finish(container);
  });

  testWidgets('cancelling the picker does nothing', (tester) async {
    final container = await pumpSettings(tester);
    backup.nextFile = null;
    await tester.tap(find.text('Import backup'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Backup imported'), findsNothing);
    finish(container);
  });
}
