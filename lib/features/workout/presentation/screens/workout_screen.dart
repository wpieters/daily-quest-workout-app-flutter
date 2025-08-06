import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_quest/features/workout/domain/workout_providers.dart';
import 'package:daily_quest/features/workout/presentation/widgets/exercise_button.dart';
import 'package:daily_quest/shared/models/exercise_type.dart';
import 'package:daily_quest/shared/models/workout_day.dart';
import 'package:daily_quest/shared/services/animation_service.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  // Track previous workout state to detect changes
  WorkoutDay? _previousWorkout;
  bool _wasCompleted = false;
  Map<ExerciseType, int> _previousStages = {};

  @override
  void initState() {
    super.initState();
    // Initialize previous stages map
    for (final type in ExerciseType.values) {
      _previousStages[type] = 0;
    }
  }

  // Check for stage completion and show animation
  void _checkStageCompletion(WorkoutDay workout) {
    if (_previousWorkout == null) {
      // First build, just store the current state
      _previousWorkout = workout;
      _wasCompleted = workout.isCompleted;

      for (final type in ExerciseType.values) {
        _previousStages[type] = workout.getCompletedStages(type);
      }
      return;
    }

    // Check for stage completion
    bool stageCompleted = false;
    for (final type in ExerciseType.values) {
      final previousStages = _previousStages[type] ?? 0;
      final currentStages = workout.getCompletedStages(type);

      if (currentStages > previousStages) {
        // A new stage was completed
        stageCompleted = true;
      }

      // Update previous stages for all exercise types
      _previousStages[type] = currentStages;
    }

    // Show animation only if a stage was completed
    if (stageCompleted) {
      // Schedule animation to show after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnimationService.showStageCompletionAnimation(context);
      });
    }

    // Check for workout completion
    if (workout.isCompleted && !_wasCompleted) {
      // Workout was just completed
      final streak = ref.read(userProgressProvider).maybeWhen(
        data: (progress) => progress.currentStreak + 1, // +1 because the streak hasn't been updated yet
        orElse: () => 1,
      );

      // Schedule completion animation to show after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show completion animation
        AnimationService.showDailyGoalCompletionAnimation(context, streak);

        // Refresh progress to update streak
        Future.delayed(const Duration(seconds: 4), () {
          ref.read(userProgressProvider.notifier).refreshProgress();
        });
      });
    }

    // Update previous state
    _previousWorkout = workout;
    _wasCompleted = workout.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(currentWorkoutProvider);
    final progressState = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyQuest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to history screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: workoutState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
        data: (workout) {
          // Check for stage completion and show animations
          _checkStageCompletion(workout);

          // Calculate streak for display
          final streak = progressState.maybeWhen(
            data: (progress) => progress.currentStreak,
            orElse: () => 0,
          );

          return Column(
            children: [
              // Streak display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Current Streak: $streak days',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),

              // Motivational text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'TRAIN TO BECOME A FORMIDABLE COMBATANT',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Exercise grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // Push-ups button
                      ExerciseButton(
                        exerciseType: ExerciseType.pushups,
                        count: workout.pushups,
                        completionPercentage: workout.getCompletionPercentage(ExerciseType.pushups),
                        completedStages: workout.getCompletedStages(ExerciseType.pushups),
                        onTap: () {
                          ref.read(currentWorkoutProvider.notifier)
                              .incrementExercise(ExerciseType.pushups);
                        },
                      ),

                      // Sit-ups button
                      ExerciseButton(
                        exerciseType: ExerciseType.situps,
                        count: workout.situps,
                        completionPercentage: workout.getCompletionPercentage(ExerciseType.situps),
                        completedStages: workout.getCompletedStages(ExerciseType.situps),
                        onTap: () {
                          ref.read(currentWorkoutProvider.notifier)
                              .incrementExercise(ExerciseType.situps);
                        },
                      ),

                      // Squats button
                      ExerciseButton(
                        exerciseType: ExerciseType.squats,
                        count: workout.squats,
                        completionPercentage: workout.getCompletionPercentage(ExerciseType.squats),
                        completedStages: workout.getCompletedStages(ExerciseType.squats),
                        onTap: () {
                          ref.read(currentWorkoutProvider.notifier)
                              .incrementExercise(ExerciseType.squats);
                        },
                      ),

                      // Running button
                      ExerciseButton(
                        exerciseType: ExerciseType.running,
                        count: workout.running,
                        completionPercentage: workout.getCompletionPercentage(ExerciseType.running),
                        completedStages: workout.getCompletedStages(ExerciseType.running),
                        enabled: workout.runningEnabled,
                        onTap: () {
                          ref.read(currentWorkoutProvider.notifier)
                              .incrementExercise(ExerciseType.running);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Running toggle
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: workout.runningEnabled,
                      onChanged: (_) {
                        ref.read(currentWorkoutProvider.notifier)
                            .toggleRunningEnabled();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Include running in daily goal'),
                  ],
                ),
              ),

              // Completion status
              if (workout.isCompleted)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Daily goal completed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
