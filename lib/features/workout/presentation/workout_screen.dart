import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/exercise_type.dart';
import '../../../shared/widgets/exercise_button.dart';
import '../../../core/constants/app_theme.dart';
import '../data/workout_provider.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Check for daily reset when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentWorkoutProvider.notifier).resetDailyWorkout();
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          '🎉 Daily Quest Complete!',
          style: TextStyle(color: AppTheme.textPrimary),
          textAlign: TextAlign.center,
        ),
        content: Consumer(
          builder: (context, ref, child) {
            final progress = ref.watch(userProgressProvider);
            return progress.when(
              data: (userProgress) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Congratulations! You\'ve completed today\'s workout.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getPowerLevelColor(userProgress.currentStreak).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getPowerLevelColor(userProgress.currentStreak),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Power Level: ${userProgress.powerLevelName}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.getPowerLevelColor(userProgress.currentStreak),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Streak: ${userProgress.currentStreak} days',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Longest Streak: ${userProgress.longestStreak} days',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text(
                'Error loading progress: $error',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Continue',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(currentWorkoutProvider);
    final runningEnabledAsync = ref.watch(runningEnabledProvider);
    final isCompleted = ref.watch(workoutCompletionProvider);
    final powerLevel = ref.watch(powerLevelProvider);

    // Show completion dialog when workout is completed
    ref.listen(workoutCompletionProvider, (previous, next) {
      if (previous == false && next == true) {
        Future.delayed(const Duration(milliseconds: 500), _showCompletionDialog);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyQuest'),
        actions: [
          // Power level indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.getPowerLevelColor(powerLevel).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getPowerLevelColor(powerLevel),
                width: 1,
              ),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final progressAsync = ref.watch(userProgressProvider);
                return progressAsync.when(
                  data: (progress) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: AppTheme.getPowerLevelColor(powerLevel),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progress.currentStreak}',
                        style: TextStyle(
                          color: AppTheme.getPowerLevelColor(powerLevel),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error),
                );
              },
            ),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header with completion status
                  if (isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.stageComplete.withOpacity(0.8),
                            AppTheme.stageComplete.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🎉 Daily Quest Complete! 🎉',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Motivational text
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'TRAIN TO BECOME A FORMIDABLE COMBATANT',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Exercise buttons grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      ExerciseButton(
                        exerciseType: ExerciseType.pushups,
                        onStageComplete: () {
                          // Could add stage completion effects here
                        },
                      ),
                      ExerciseButton(
                        exerciseType: ExerciseType.situps,
                        onStageComplete: () {
                          // Could add stage completion effects here
                        },
                      ),
                      ExerciseButton(
                        exerciseType: ExerciseType.squats,
                        onStageComplete: () {
                          // Could add stage completion effects here
                        },
                      ),
                      ExerciseButton(
                        exerciseType: ExerciseType.running,
                        onStageComplete: () {
                          // Could add stage completion effects here
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Running toggle
                  runningEnabledAsync.when(
                    data: (runningEnabled) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_run,
                              color: AppTheme.runningColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Include Running',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    runningEnabled 
                                        ? 'Running required for daily completion'
                                        : 'Running disabled for daily completion',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: runningEnabled,
                              onChanged: isCompleted 
                                  ? null 
                                  : (_) => ref.read(runningEnabledProvider.notifier).toggle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.directions_run, color: AppTheme.runningColor),
                            SizedBox(width: 12),
                            Expanded(child: Text('Loading...')),
                            CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading running setting: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick stats
                  Consumer(
                    builder: (context, ref, child) {
                      final progressAsync = ref.watch(userProgressProvider);
                      return progressAsync.when(
                        data: (progress) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              context,
                              'Current Streak',
                              '${progress.currentStreak}',
                              Icons.local_fire_department,
                              AppTheme.getPowerLevelColor(progress.currentStreak),
                            ),
                            _buildStatCard(
                              context,
                              'Total Workouts',
                              '${progress.totalWorkouts}',
                              Icons.fitness_center,
                              AppTheme.primaryColor,
                            ),
                            _buildStatCard(
                              context,
                              'Best Streak',
                              '${progress.longestStreak}',
                              Icons.emoji_events,
                              AppTheme.accentColor,
                            ),
                          ],
                        ),
                        loading: () => const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CircularProgressIndicator(),
                            CircularProgressIndicator(),
                            CircularProgressIndicator(),
                          ],
                        ),
                        error: (error, stack) => Text(
                          'Error loading stats: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error loading workout data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentWorkoutProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
