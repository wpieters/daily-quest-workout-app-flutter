import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_day.dart';
import '../models/user_progress.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const String _progressKey = 'user_progress';
  static const String _todayWorkoutKey = 'today_workout';

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
    
    return const UserProgress();
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

  Future<WorkoutDay> loadTodaysWorkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutJson = prefs.getString(_todayWorkoutKey);
      
      if (workoutJson != null) {
        final workoutMap = jsonDecode(workoutJson) as Map<String, dynamic>;
        final workoutDay = WorkoutDay.fromJson(workoutMap);
        
        // Check if it's still today
        final now = DateTime.now();
        final workoutDate = workoutDay.date;
        
        if (workoutDate.year == now.year &&
            workoutDate.month == now.month &&
            workoutDate.day == now.day) {
          return workoutDay;
        }
      }
    } catch (e) {
      // If there's an error loading, return default
    }
    
    // Return new workout for today
    return WorkoutDay(date: DateTime.now());
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

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_todayWorkoutKey);
    } catch (e) {
      // Handle error silently
    }
  }
}