import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_quest/features/workout/data/workout_repository.dart';
import 'package:daily_quest/shared/models/workout_day.dart';
import 'package:daily_quest/shared/models/user_progress.dart';
import 'package:daily_quest/shared/models/exercise_type.dart';

// Provider for the workout repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// Provider for the current workout day
final currentWorkoutProvider = StateNotifierProvider<WorkoutNotifier, AsyncValue<WorkoutDay>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return WorkoutNotifier(repository);
});

// Provider for user progress
final userProgressProvider = StateNotifierProvider<ProgressNotifier, AsyncValue<UserProgress>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return ProgressNotifier(repository);
});

// Notifier for workout state
class WorkoutNotifier extends StateNotifier<AsyncValue<WorkoutDay>> {
  final WorkoutRepository _repository;
  
  WorkoutNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadCurrentWorkout();
  }
  
  // Load the current workout from storage
  Future<void> _loadCurrentWorkout() async {
    try {
      final workout = await _repository.getCurrentWorkout();
      state = AsyncValue.data(workout);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Increment an exercise count
  Future<void> incrementExercise(ExerciseType type) async {
    // Only proceed if we have a valid workout
    if (!state.hasValue) return;
    
    try {
      final currentWorkout = state.value!;
      final updatedWorkout = await _repository.incrementExercise(currentWorkout, type);
      state = AsyncValue.data(updatedWorkout);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Toggle running requirement
  Future<void> toggleRunningEnabled() async {
    // Only proceed if we have a valid workout
    if (!state.hasValue) return;
    
    try {
      final currentWorkout = state.value!;
      final updatedWorkout = await _repository.toggleRunningEnabled(currentWorkout);
      state = AsyncValue.data(updatedWorkout);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Reset workout for a new day
  Future<void> resetWorkout() async {
    try {
      final newWorkout = WorkoutDay.today();
      await _repository.saveCurrentWorkout(newWorkout);
      state = AsyncValue.data(newWorkout);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Notifier for progress state
class ProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  final WorkoutRepository _repository;
  
  ProgressNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProgress();
  }
  
  // Load progress from storage
  Future<void> _loadProgress() async {
    try {
      final progress = await _repository.getUserProgress();
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  // Refresh progress data (call after workout completion)
  Future<void> refreshProgress() async {
    await _loadProgress();
  }
}