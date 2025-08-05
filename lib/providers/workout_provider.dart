import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../models/workout_day.dart';
import '../models/user_progress.dart';
import '../models/exercise_type.dart';
import '../services/storage_service.dart';

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier(ref.read(storageServiceProvider));
});

class WorkoutState {
  final WorkoutDay currentDay;
  final UserProgress progress;
  final bool isLoading;
  final bool showCompletionAnimation;
  final int lastCompletedStage;
  final ExerciseType? lastCompletedExercise;

  const WorkoutState({
    required this.currentDay,
    required this.progress,
    this.isLoading = false,
    this.showCompletionAnimation = false,
    this.lastCompletedStage = -1,
    this.lastCompletedExercise,
  });

  WorkoutState copyWith({
    WorkoutDay? currentDay,
    UserProgress? progress,
    bool? isLoading,
    bool? showCompletionAnimation,
    int? lastCompletedStage,
    ExerciseType? lastCompletedExercise,
  }) {
    return WorkoutState(
      currentDay: currentDay ?? this.currentDay,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      showCompletionAnimation: showCompletionAnimation ?? this.showCompletionAnimation,
      lastCompletedStage: lastCompletedStage ?? this.lastCompletedStage,
      lastCompletedExercise: lastCompletedExercise ?? this.lastCompletedExercise,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final StorageService _storageService;

  WorkoutNotifier(this._storageService) : super(WorkoutState(
    currentDay: WorkoutDay(date: DateTime.now()),
    progress: const UserProgress(),
  )) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    
    final progress = await _storageService.loadProgress();
    final currentDay = await _storageService.loadTodaysWorkout();
    
    state = state.copyWith(
      currentDay: currentDay,
      progress: progress,
      isLoading: false,
    );
  }

  Future<void> incrementExercise(ExerciseType exercise) async {
    final wasComplete = state.currentDay.isComplete;
    final oldStage = _getStageForExercise(exercise, state.currentDay);

    WorkoutDay newDay;
    switch (exercise) {
      case ExerciseType.pushups:
        if (state.currentDay.pushups >= 100) return;
        newDay = state.currentDay.copyWith(pushups: state.currentDay.pushups + 1);
        break;
      case ExerciseType.situps:
        if (state.currentDay.situps >= 100) return;
        newDay = state.currentDay.copyWith(situps: state.currentDay.situps + 1);
        break;
      case ExerciseType.squats:
        if (state.currentDay.squats >= 100) return;
        newDay = state.currentDay.copyWith(squats: state.currentDay.squats + 1);
        break;
      case ExerciseType.running:
        if (state.currentDay.running >= 100) return;
        newDay = state.currentDay.copyWith(running: state.currentDay.running + 1);
        break;
    }

    final newStage = _getStageForExercise(exercise, newDay);
    final stageCompleted = newStage > oldStage;

    state = state.copyWith(
      currentDay: newDay,
      lastCompletedStage: stageCompleted ? newStage : -1,
      lastCompletedExercise: stageCompleted ? exercise : null,
    );

    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      if (stageCompleted) {
        Vibration.vibrate(duration: 200);
      } else {
        Vibration.vibrate(duration: 50);
      }
    }

    // Check for daily completion
    if (!wasComplete && newDay.isComplete) {
      await _completeDay();
    }

    await _storageService.saveTodaysWorkout(newDay);
  }

  Future<void> toggleRunning() async {
    final newDay = state.currentDay.copyWith(
      runningEnabled: !state.currentDay.runningEnabled,
    );
    
    state = state.copyWith(currentDay: newDay);
    
    // Check if this change affects completion status
    if (newDay.isComplete && !state.currentDay.isComplete) {
      await _completeDay();
    }
    
    await _storageService.saveTodaysWorkout(newDay);
  }

  Future<void> _completeDay() async {
    final completedDay = state.currentDay.copyWith(completed: true);
    final newHistory = [...state.progress.history, completedDay];
    
    // Calculate new streak
    int newStreak = 1;
    for (int i = newHistory.length - 2; i >= 0; i--) {
      if (newHistory[i].completed && 
          newHistory[i].date.difference(newHistory[i + 1].date).inDays == -1) {
        newStreak++;
      } else {
        break;
      }
    }
    
    final newProgress = state.progress.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > state.progress.longestStreak 
          ? newStreak 
          : state.progress.longestStreak,
      totalWorkouts: state.progress.totalWorkouts + 1,
      history: newHistory,
    );

    state = state.copyWith(
      currentDay: completedDay,
      progress: newProgress,
      showCompletionAnimation: true,
    );

    await _storageService.saveProgress(newProgress);
  }

  void hideCompletionAnimation() {
    state = state.copyWith(showCompletionAnimation: false);
  }

  void hideStageAnimation() {
    state = state.copyWith(
      lastCompletedStage: -1,
      lastCompletedExercise: null,
    );
  }

  int _getStageForExercise(ExerciseType exercise, WorkoutDay day) {
    switch (exercise) {
      case ExerciseType.pushups:
        return day.pushupsStage;
      case ExerciseType.situps:
        return day.situpsStage;
      case ExerciseType.squats:
        return day.squatsStage;
      case ExerciseType.running:
        return day.runningStage;
    }
  }

  Future<void> resetDay() async {
    final newDay = WorkoutDay(
      date: DateTime.now(),
      runningEnabled: state.currentDay.runningEnabled,
    );
    
    state = state.copyWith(currentDay: newDay);
    await _storageService.saveTodaysWorkout(newDay);
  }
}