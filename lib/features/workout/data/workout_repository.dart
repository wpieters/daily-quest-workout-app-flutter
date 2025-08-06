import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_quest/shared/models/workout_day.dart';
import 'package:daily_quest/shared/models/user_progress.dart';
import 'package:daily_quest/shared/models/exercise_type.dart';

class WorkoutRepository {
  static const String _currentWorkoutKey = 'current_workout';
  static const String _userProgressKey = 'user_progress';

  // Save the current workout day
  Future<void> saveCurrentWorkout(WorkoutDay workoutDay) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutJson = jsonEncode(workoutDay.toJson());
    await prefs.setString(_currentWorkoutKey, workoutJson);

    // If workout is completed, update progress
    if (workoutDay.isCompleted) {
      final progress = await getUserProgress();
      final updatedProgress = progress.addCompletedWorkout(workoutDay);
      await saveUserProgress(updatedProgress);
    }
  }

  // Get the current workout day
  Future<WorkoutDay> getCurrentWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutJson = prefs.getString(_currentWorkoutKey);

    if (workoutJson == null) {
      // No current workout, create a new one for today
      return WorkoutDay.today();
    }

    try {
      final workoutMap = jsonDecode(workoutJson) as Map<String, dynamic>;
      final workout = WorkoutDay.fromJson(workoutMap);

      // Check if the workout is from today
      final now = DateTime.now();
      if (workout.date.year == now.year && 
          workout.date.month == now.month && 
          workout.date.day == now.day) {
        return workout;
      } else {
        // It's a new day, create a fresh workout
        return WorkoutDay.today();
      }
    } catch (e) {
      // Error parsing, create a new workout
      return WorkoutDay.today();
    }
  }

  // Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = jsonEncode(progress.toJson());
    await prefs.setString(_userProgressKey, progressJson);
  }

  // Get user progress
  Future<UserProgress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_userProgressKey);

    if (progressJson == null) {
      // No progress saved yet
      return UserProgress();
    }

    try {
      final progressMap = jsonDecode(progressJson) as Map<String, dynamic>;
      return UserProgress.fromJson(progressMap);
    } catch (e) {
      // Error parsing, return empty progress
      return UserProgress();
    }
  }

  // Update exercise count
  Future<WorkoutDay> incrementExercise(WorkoutDay workout, ExerciseType type) async {
    WorkoutDay updatedWorkout;

    switch (type) {
      case ExerciseType.pushups:
        updatedWorkout = workout.copyWith(pushups: workout.pushups + 1);
        break;
      case ExerciseType.situps:
        updatedWorkout = workout.copyWith(situps: workout.situps + 1);
        break;
      case ExerciseType.squats:
        updatedWorkout = workout.copyWith(squats: workout.squats + 1);
        break;
      case ExerciseType.running:
        updatedWorkout = workout.copyWith(running: workout.running + 1);
        break;
    }

    // Check if this update completes the workout
    final isNewlyCompleted = !workout.isCompleted && updatedWorkout.isCompleted;
    final finalWorkout = isNewlyCompleted 
        ? updatedWorkout.copyWith(completed: true)
        : updatedWorkout;

    // Save the updated workout
    await saveCurrentWorkout(finalWorkout);
    return finalWorkout;
  }

  // Toggle running requirement
  Future<WorkoutDay> toggleRunningEnabled(WorkoutDay workout) async {
    final updatedWorkout = workout.copyWith(
      runningEnabled: !workout.runningEnabled,
    );

    // Check if this toggle completes the workout
    final isNewlyCompleted = !workout.isCompleted && updatedWorkout.isCompleted;
    final finalWorkout = isNewlyCompleted 
        ? updatedWorkout.copyWith(completed: true)
        : updatedWorkout;

    // Save the updated workout
    await saveCurrentWorkout(finalWorkout);
    return finalWorkout;
  }
}
