import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_settings.dart';
import '../models/workout_day.dart';
import '../models/user_progress.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const String _progressKey = 'user_progress';
  static const String _todayWorkoutKey = 'today_workout';
  static const String _reminderSettingsKey = 'reminder_settings';

  Future<UserProgress> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);
      
      if (progressJson != null) {
        final progressMap = jsonDecode(progressJson) as Map<String, dynamic>;
        return UserProgress.fromJson(progressMap);
      }
    } catch (e) {
      // If there's an error loading, return default
    }
    
    return UserProgress.initial();
  }

  Future<void> saveProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, progressJson);
    } catch (e) {
      // Handle error silently
    }
  }

  /// The most recently saved workout day, whatever its date. Days that have
  /// ended are settled by the workout provider, so this must not drop them.
  Future<WorkoutDay?> loadStoredWorkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutJson = prefs.getString(_todayWorkoutKey);
      
      if (workoutJson != null) {
        final workoutMap = jsonDecode(workoutJson) as Map<String, dynamic>;
        return WorkoutDay.fromJson(workoutMap);
      }
    } catch (e) {
      // If there's an error loading, return default
    }
    
    return null;
  }

  Future<void> saveTodaysWorkout(WorkoutDay workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutJson = jsonEncode(workout.toJson());
      await prefs.setString(_todayWorkoutKey, workoutJson);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<ReminderSettings> loadReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_reminderSettingsKey);
      if (json != null) {
        return ReminderSettings.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      // Fall through to defaults
    }
    return ReminderSettings.defaults;
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reminderSettingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_todayWorkoutKey);
      await prefs.remove(_reminderSettingsKey);
    } catch (e) {
      // Handle error silently
    }
  }
}