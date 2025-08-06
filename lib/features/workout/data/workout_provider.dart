import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/workout_day.dart';
import '../../../shared/models/user_progress.dart';
import '../../../shared/models/exercise_type.dart';
import '../../../shared/services/storage_service.dart';

// Storage service provider
final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return await StorageService.getInstance();
});

// Current workout day provider
final currentWorkoutProvider = StateNotifierProvider<WorkoutNotifier, AsyncValue<WorkoutDay>>((ref) {
  return WorkoutNotifier(ref);
});

// User progress provider
final userProgressProvider = StateNotifierProvider<UserProgressNotifier, AsyncValue<UserProgress>>((ref) {
  return UserProgressNotifier(ref);
});

// Running enabled provider
final runningEnabledProvider = StateNotifierProvider<RunningEnabledNotifier, AsyncValue<bool>>((ref) {
  return RunningEnabledNotifier(ref);
});

// Workout completion status provider
final workoutCompletionProvider = Provider<bool>((ref) {
  final workoutAsync = ref.watch(currentWorkoutProvider);
  return workoutAsync.maybeWhen(
    data: (workout) => workout.isCompleted,
    orElse: () => false,
  );
});

// Power level provider
final powerLevelProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressProvider);
  return progressAsync.maybeWhen(
    data: (progress) => progress.powerLevel,
    orElse: () => 0,
  );
});

class WorkoutNotifier extends StateNotifier<AsyncValue<WorkoutDay>> {
  final Ref ref;
  StorageService? _storageService;

  WorkoutNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _storageService = await ref.read(storageServiceProvider.future);
      final workoutDay = await _storageService!.getTodayWorkout();
      state = AsyncValue.data(workoutDay);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> incrementExercise(ExerciseType exerciseType) async {
    if (_storageService == null) return;

    try {
      // Optimistic update
      state.whenData((currentWorkout) {
        final updatedWorkout = currentWorkout.incrementExercise(exerciseType);
        state = AsyncValue.data(updatedWorkout);
      });

      // Persist to storage
      final updatedWorkout = await _storageService!.incrementExercise(exerciseType);
      state = AsyncValue.data(updatedWorkout);

      // Update user progress if workout is completed
      if (updatedWorkout.isCompleted) {
        ref.read(userProgressProvider.notifier).refreshProgress();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleRunningEnabled() async {
    if (_storageService == null) return;

    try {
      final updatedWorkout = await _storageService!.toggleRunningEnabled();
      state = AsyncValue.data(updatedWorkout);
      
      // Update running enabled provider
      ref.read(runningEnabledProvider.notifier).setEnabled(updatedWorkout.runningEnabled);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshWorkout() async {
    if (_storageService == null) return;

    try {
      final workoutDay = await _storageService!.getTodayWorkout();
      state = AsyncValue.data(workoutDay);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetDailyWorkout() async {
    if (_storageService == null) return;

    try {
      final shouldReset = await _storageService!.shouldResetDaily();
      if (shouldReset) {
        await refreshWorkout();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class UserProgressNotifier extends StateNotifier<AsyncValue<UserProgress>> {
  final Ref ref;
  StorageService? _storageService;

  UserProgressNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _storageService = await ref.read(storageServiceProvider.future);
      final progress = await _storageService!.getUserProgress();
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshProgress() async {
    if (_storageService == null) return;

    try {
      final progress = await _storageService!.getUserProgress();
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProgress(UserProgress newProgress) async {
    if (_storageService == null) return;

    try {
      await _storageService!.saveUserProgress(newProgress);
      state = AsyncValue.data(newProgress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class RunningEnabledNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;
  StorageService? _storageService;

  RunningEnabledNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _storageService = await ref.read(storageServiceProvider.future);
      final enabled = await _storageService!.getRunningEnabled();
      state = AsyncValue.data(enabled);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (_storageService == null) return;

    try {
      await _storageService!.setRunningEnabled(enabled);
      state = AsyncValue.data(enabled);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggle() async {
    final currentEnabled = state.maybeWhen(
      data: (enabled) => enabled,
      orElse: () => true,
    );
    
    await setEnabled(!currentEnabled);
  }
}

// Workout history provider
final workoutHistoryProvider = FutureProvider.family<List<WorkoutDay>, int?>((ref, limitDays) async {
  final storageService = await ref.read(storageServiceProvider.future);
  return await storageService.getWorkoutHistory(limitDays: limitDays);
});

// Exercise-specific providers for UI convenience
final exerciseCountProvider = Provider.family<int, ExerciseType>((ref, exerciseType) {
  final workoutAsync = ref.watch(currentWorkoutProvider);
  return workoutAsync.maybeWhen(
    data: (workout) => workout.getCount(exerciseType),
    orElse: () => 0,
  );
});

final exerciseCompletionProvider = Provider.family<double, ExerciseType>((ref, exerciseType) {
  final workoutAsync = ref.watch(currentWorkoutProvider);
  return workoutAsync.maybeWhen(
    data: (workout) => workout.getCompletionPercentage(exerciseType),
    orElse: () => 0.0,
  );
});

final exerciseStageProvider = Provider.family<int, ExerciseType>((ref, exerciseType) {
  final workoutAsync = ref.watch(currentWorkoutProvider);
  return workoutAsync.maybeWhen(
    data: (workout) => workout.getCurrentStage(exerciseType),
    orElse: () => 0,
  );
});

final exerciseStageProgressProvider = Provider.family<double, ExerciseType>((ref, exerciseType) {
  final workoutAsync = ref.watch(currentWorkoutProvider);
  return workoutAsync.maybeWhen(
    data: (workout) => workout.getStageProgress(exerciseType),
    orElse: () => 0.0,
  );
});

// Debug provider for clearing data
final debugProvider = Provider<DebugActions>((ref) {
  return DebugActions(ref);
});

class DebugActions {
  final Ref ref;
  
  DebugActions(this.ref);

  Future<void> clearAllData() async {
    final storageService = await ref.read(storageServiceProvider.future);
    await storageService.clearAllData();
    
    // Refresh all providers
    ref.invalidate(currentWorkoutProvider);
    ref.invalidate(userProgressProvider);
    ref.invalidate(runningEnabledProvider);
  }

  Future<Map<String, dynamic>> exportData() async {
    final storageService = await ref.read(storageServiceProvider.future);
    return await storageService.exportData();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final storageService = await ref.read(storageServiceProvider.future);
    await storageService.importData(data);
    
    // Refresh all providers
    ref.invalidate(currentWorkoutProvider);
    ref.invalidate(userProgressProvider);
    ref.invalidate(runningEnabledProvider);
  }
}
