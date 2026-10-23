import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/services/storage_service.dart';

void main() {
  test(
    'exportAll returns stored JSON verbatim, with nulls for missing keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'user_progress': jsonEncode({'schemaVersion': 2, 'currentStreak': 4}),
        'reminder_settings': jsonEncode({'enabled': true, 'times': {}}),
      });
      final data = await StorageService().exportAll();
      expect(data['user_progress'], {'schemaVersion': 2, 'currentStreak': 4});
      expect(data['today_workout'], isNull);
      expect(data['reminder_settings'], {'enabled': true, 'times': {}});
    },
  );

  test('importAll replaces every key and removes nulls', () async {
    SharedPreferences.setMockInitialValues({
      'today_workout': jsonEncode({'pushups': 99}),
      'last_export_at': '2026-10-01T00:00:00.000Z',
    });
    final storage = StorageService();
    await storage.importAll({
      'user_progress': {'schemaVersion': 2, 'currentStreak': 1},
      'today_workout': null,
      'reminder_settings': null,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('user_progress')!)['currentStreak'], 1);
    expect(prefs.getString('today_workout'), isNull);
    expect(prefs.getString('reminder_settings'), isNull);
    // The last export date is this device's, not the backup's.
    expect(await storage.loadLastExport(), DateTime.utc(2026, 10));
  });

  test('clearAllData also forgets the last export', () async {
    SharedPreferences.setMockInitialValues({
      'last_export_at': '2026-10-01T00:00:00.000Z',
    });
    final storage = StorageService();
    await storage.clearAllData();
    expect(await storage.loadLastExport(), isNull);
  });
}
