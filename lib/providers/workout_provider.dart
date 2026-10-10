import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../models/workout_day.dart';
import '../models/user_progress.dart';
import '../models/exercise_type.dart';
import '../progression/progression_engine.dart';
import '../progression/progression_state.dart';
import '../services/storage_service.dart';

final progressionEngineProvider = Provider<ProgressionEngine>((ref) {
  return ProgressionEngine();
});

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier(
    ref.read(storageServiceProvider),
    ref.read(progressionEngineProvider),
    ref.read(clockProvider),
  );
});

class WorkoutState {
  final WorkoutDay currentDay;
  final UserProgress progress;
  final bool isLoading;
  final bool showCompletionAnimation;
  final int lastCompletedStage;
  final ExerciseType? lastCompletedExercise;

  /// Level-ups waiting to be shown, oldest first.
  final List<LevelChange> pendingLevelUps;

  /// XP from the most recent award; [xpGainId] changes on every award so the
  /// UI can show feedback even when two awards have the same amount.
  final int lastXpGain;
  final int xpGainId;

  const WorkoutState({
    required this.currentDay,
    required this.progress,
    this.isLoading = false,
    this.showCompletionAnimation = false,
    this.lastCompletedStage = -1,
    this.lastCompletedExercise,
    this.pendingLevelUps = const [],
    this.lastXpGain = 0,
    this.xpGainId = 0,
  });

  WorkoutState copyWith({
    WorkoutDay? currentDay,
    UserProgress? progress,
    bool? isLoading,
    bool? showCompletionAnimation,
    int? lastCompletedStage,
    ExerciseType? lastCompletedExercise,
    List<LevelChange>? pendingLevelUps,
    int? lastXpGain,
    int? xpGainId,
  }) {
    return WorkoutState(
      currentDay: currentDay ?? this.currentDay,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      showCompletionAnimation: showCompletionAnimation ?? this.showCompletionAnimation,
      lastCompletedStage: lastCompletedStage ?? this.lastCompletedStage,
      lastCompletedExercise: lastCompletedExercise ?? this.lastCompletedExercise,
      pendingLevelUps: pendingLevelUps ?? this.pendingLevelUps,
      lastXpGain: lastXpGain ?? this.lastXpGain,
      xpGainId: xpGainId ?? this.xpGainId,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final StorageService _storageService;
  final ProgressionEngine _engine;
  final DateTime Function() _clock;

  /// Completes once saved data has been loaded and past days settled.
  late final Future<void> ready;

  WorkoutNotifier(this._storageService, this._engine, this._clock)
      : super(WorkoutState(
          currentDay: WorkoutDay(date: dateOnly(_clock())),
          progress: UserProgress.initial(),
        )) {
    ready = _loadData();
  }

  DateTime get _today => dateOnly(_clock());

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);

    final progress = await _storageService.loadProgress();
    final storedDay = await _storageService.loadStoredWorkout();

    state = state.copyWith(
      currentDay: storedDay ?? WorkoutDay(date: _today),
      progress: progress,
    );

    await rollover();
    // Awards anything earned but not yet recorded, e.g. today's progress from
    // before the progression system existed.
    await _syncXp();

    state = state.copyWith(isLoading: false);
  }

  /// Settles every day that has ended since the last run (missed-day
  /// penalties, fatigue recovery, stat tallies) and starts a fresh day.
  /// Safe to call repeatedly: settled days are never processed twice.
  Future<void> rollover() async {
    final today = _today;
    final day = state.currentDay;
    final lastActive = state.progress.progression.lastActiveDate;

    final dayIsLastActive = lastActive != null &&
        dateOnly(day.date) == dateOnly(lastActive);
    final result = _engine.catchUp(
      state.progress.progression,
      today,
      lastActiveDay: dayIsLastActive ? day.summary : null,
    );

    final dayEnded = dateOnly(day.date).isBefore(today);
    var history = state.progress.history;
    if (dayEnded && day.hasActivity) {
      history = _upsertDay(history, day);
    }

    final progress = state.progress.copyWith(
      progression: result.state,
      history: history,
    );
    final currentDay = dayEnded
        ? WorkoutDay(date: today, runningEnabled: day.runningEnabled)
        : day;

    state = state.copyWith(progress: progress, currentDay: currentDay);

    await _storageService.saveProgress(progress);
    await _storageService.saveTodaysWorkout(currentDay);
  }

  Future<void> incrementExercise(ExerciseType exercise) async {
    if (dateOnly(state.currentDay.date).isBefore(_today)) {
      await rollover();
    }

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
        if (!state.currentDay.runningEnabled) return;
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

    await _haptic(stageCompleted ? 200 : 50);

    await _syncXp();

    // Check for daily completion
    if (!wasComplete && state.currentDay.isComplete) {
      await _completeDay();
    }

    await _storageService.saveTodaysWorkout(state.currentDay);
  }

  /// Awards any XP the current day is worth beyond what it already earned.
  /// Awards only ever grow, so resetting or toggling never re-awards or
  /// revokes XP.
  Future<void> _syncXp() async {
    final day = state.currentDay;
    final summary = day.summary;
    final dayXp = _engine.dayXp(summary);
    final gain = dayXp - day.xpEarned;
    if (gain <= 0) return;

    final result = _engine.awardXp(state.progress.progression, gain, summary);
    final newDay = day.copyWith(
      xpEarned: dayXp,
      bonusAwarded: day.bonusAwarded || summary.earnsBonus,
    );
    final progress = state.progress.copyWith(progression: result.state);

    state = state.copyWith(
      currentDay: newDay,
      progress: progress,
      pendingLevelUps: [...state.pendingLevelUps, ...result.levelChanges],
      lastXpGain: gain,
      xpGainId: state.xpGainId + 1,
    );

    await _storageService.saveProgress(progress);
    await _storageService.saveTodaysWorkout(newDay);
  }

  Future<void> _haptic(int durationMs) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: durationMs);
      }
    } catch (_) {
      // No vibration support on this platform
    }
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
    final alreadyCounted = state.progress.history.any((d) =>
        d.completed && dateOnly(d.date) == dateOnly(completedDay.date));
    final newHistory = _upsertDay(state.progress.history, completedDay);

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
      totalWorkouts: state.progress.totalWorkouts + (alreadyCounted ? 0 : 1),
      history: newHistory,
    );

    state = state.copyWith(
      currentDay: completedDay,
      progress: newProgress,
      showCompletionAnimation: true,
    );

    await _storageService.saveProgress(newProgress);
  }

  /// Replaces the history entry for [day]'s date, or appends it.
  List<WorkoutDay> _upsertDay(List<WorkoutDay> history, WorkoutDay day) {
    final date = dateOnly(day.date);
    final index = history.indexWhere((d) => dateOnly(d.date) == date);
    if (index == -1) return [...history, day];
    return [...history]..[index] = day;
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

  void dismissLevelUp() {
    if (state.pendingLevelUps.isEmpty) return;
    state = state.copyWith(pendingLevelUps: state.pendingLevelUps.sublist(1));
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

  /// Zeroes today's counters. XP already earned today is kept and not
  /// re-awarded.
  Future<void> resetDay() async {
    final newDay = WorkoutDay(
      date: _today,
      runningEnabled: state.currentDay.runningEnabled,
      xpEarned: state.currentDay.xpEarned,
      bonusAwarded: state.currentDay.bonusAwarded,
    );

    state = state.copyWith(currentDay: newDay);
    await _storageService.saveTodaysWorkout(newDay);
  }
}
