import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_day.dart';
import '../models/user_progress.dart';
import '../models/exercise_type.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Workout Day Management
  Future<WorkoutDay> getTodayWorkout() async {
    final today = DateTime.now();
    final todayKey = _formatDateKey(today);
    
    final jsonString = _prefs!.getString(todayKey);
    if (jsonString != null) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkoutDay.fromJson(json);
    }
    
    // Create new workout day for today
    final newWorkoutDay = WorkoutDay(
      date: today,
      runningEnabled: await getRunningEnabled(),
    );
    
    await _saveWorkoutDay(newWorkoutDay);
    return newWorkoutDay;
  }

  Future<void> saveWorkoutDay(WorkoutDay workoutDay) async {
    await _saveWorkoutDay(workoutDay);
    
    // Update user progress if workout is completed
    if (workoutDay.isCompleted) {
      final progress = await getUserProgress();
      final updatedProgress = progress.updateAfterWorkout(workoutDay);
      await saveUserProgress(updatedProgress);
    }
  }

  Future<void> _saveWorkoutDay(WorkoutDay workoutDay) async {
    final dateKey = _formatDateKey(workoutDay.date);
    final jsonString = jsonEncode(workoutDay.toJson());
    await _prefs!.setString(dateKey, jsonString);
  }

  Future<List<WorkoutDay>> getWorkoutHistory({int? limitDays}) async {
    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith('workout_'))
        .toList();
    
    keys.sort((a, b) => b.compareTo(a)); // Most recent first
    
    final workoutDays = <WorkoutDay>[];
    final keysToProcess = limitDays != null 
        ? keys.take(limitDays).toList() 
        : keys;
    
    for (final key in keysToProcess) {
      final jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          workoutDays.add(WorkoutDay.fromJson(json));
        } catch (e) {
          // Skip corrupted entries
          continue;
        }
      }
    }
    
    return workoutDays;
  }

  // User Progress Management
  Future<UserProgress> getUserProgress() async {
    final jsonString = _prefs!.getString(AppConstants.keyCurrentStreak);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserProgress.fromJson(json);
      } catch (e) {
        // Return default if corrupted
        return const UserProgress();
      }
    }
    return const UserProgress();
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    final jsonString = jsonEncode(progress.toJson());
    await _prefs!.setString(AppConstants.keyCurrentStreak, jsonString);
  }

  // Exercise Settings
  Future<bool> getRunningEnabled() async {
    return _prefs!.getBool(AppConstants.keyRunningEnabled) ?? true;
  }

  Future<void> setRunningEnabled(bool enabled) async {
    await _prefs!.setBool(AppConstants.keyRunningEnabled, enabled);
  }

  // Daily Reset Management
  Future<bool> shouldResetDaily() async {
    final lastResetDate = _prefs!.getString(AppConstants.keyCurrentDate);
    final today = DateTime.now();
    final todayString = _formatDateKey(today);
    
    if (lastResetDate == null || lastResetDate != todayString) {
      await _prefs!.setString(AppConstants.keyCurrentDate, todayString);
      return true;
    }
    
    return false;
  }

  // Increment specific exercise
  Future<WorkoutDay> incrementExercise(ExerciseType exerciseType) async {
    final workoutDay = await getTodayWorkout();
    final updatedWorkoutDay = workoutDay.incrementExercise(exerciseType);
    await saveWorkoutDay(updatedWorkoutDay);
    return updatedWorkoutDay;
  }

  // Toggle running enabled/disabled
  Future<WorkoutDay> toggleRunningEnabled() async {
    final currentEnabled = await getRunningEnabled();
    final newEnabled = !currentEnabled;
    await setRunningEnabled(newEnabled);
    
    final workoutDay = await getTodayWorkout();
    final updatedWorkoutDay = workoutDay.copyWith(runningEnabled: newEnabled);
    await saveWorkoutDay(updatedWorkoutDay);
    
    return updatedWorkoutDay;
  }

  // Clear all data (for testing/debugging)
  Future<void> clearAllData() async {
    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith('workout_') || 
               key == AppConstants.keyCurrentStreak ||
               key == AppConstants.keyRunningEnabled ||
               key == AppConstants.keyCurrentDate)
        .toList();
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  // Export data as JSON
  Future<Map<String, dynamic>> exportData() async {
    final workoutHistory = await getWorkoutHistory();
    final userProgress = await getUserProgress();
    
    return {
      'workoutHistory': workoutHistory.map((day) => day.toJson()).toList(),
      'userProgress': userProgress.toJson(),
      'runningEnabled': await getRunningEnabled(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await clearAllData();
      
      // Import workout history
      if (data.containsKey('workoutHistory')) {
        final historyData = data['workoutHistory'] as List<dynamic>;
        for (final dayData in historyData) {
          final workoutDay = WorkoutDay.fromJson(dayData as Map<String, dynamic>);
          await _saveWorkoutDay(workoutDay);
        }
      }
      
      // Import user progress
      if (data.containsKey('userProgress')) {
        final progressData = data['userProgress'] as Map<String, dynamic>;
        final progress = UserProgress.fromJson(progressData);
        await saveUserProgress(progress);
      }
      
      // Import settings
      if (data.containsKey('runningEnabled')) {
        await setRunningEnabled(data['runningEnabled'] as bool);
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  String _formatDateKey(DateTime date) {
    return 'workout_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
