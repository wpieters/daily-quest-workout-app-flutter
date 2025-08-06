import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/workout_day.dart';
import '../../../shared/models/exercise_type.dart';
import '../../../core/constants/app_theme.dart';
import '../../workout/data/workout_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider);
    final historyAsync = ref.watch(workoutHistoryProvider(30)); // Last 30 days

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Progress Card
            progressAsync.when(
              data: (progress) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Power Level',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                progress.powerLevelName,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.getPowerLevelColor(progress.currentStreak),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.flash_on,
                            size: 48,
                            color: AppTheme.getPowerLevelColor(progress.currentStreak),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              'Current Streak',
                              '${progress.currentStreak} days',
                              Icons.local_fire_department,
                              AppTheme.getPowerLevelColor(progress.currentStreak),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              'Longest Streak',
                              '${progress.longestStreak} days',
                              Icons.emoji_events,
                              AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        context,
                        'Total Workouts',
                        '${progress.totalWorkouts}',
                        Icons.fitness_center,
                        AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error loading progress: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Workout History Section
            Text(
              'Recent Workouts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            historyAsync.when(
              data: (workoutHistory) {
                if (workoutHistory.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workouts yet!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your first workout to see your progress here.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: workoutHistory
                      .take(10) // Show only last 10 workouts
                      .map((workout) => _buildWorkoutHistoryItem(context, workout))
                      .toList(),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error loading workout history: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWorkoutHistoryItem(BuildContext context, WorkoutDay workout) {
    final isCompleted = workout.isCompleted;
    final date = workout.date;
    final isToday = DateTime.now().difference(date).inDays == 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date and completion status
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppTheme.stageComplete.withOpacity(0.2)
                    : AppTheme.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted ? AppTheme.stageComplete : AppTheme.textSecondary,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isCompleted ? AppTheme.stageComplete : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(date.month),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCompleted ? AppTheme.stageComplete : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Exercise progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentColor),
                          ),
                          child: Text(
                            'TODAY',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompleted ? AppTheme.stageComplete : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExerciseProgress(context, ExerciseType.pushups, workout),
                      _buildExerciseProgress(context, ExerciseType.situps, workout),
                      _buildExerciseProgress(context, ExerciseType.squats, workout),
                      if (workout.runningEnabled)
                        _buildExerciseProgress(context, ExerciseType.running, workout),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseProgress(BuildContext context, ExerciseType exerciseType, WorkoutDay workout) {
    final count = workout.getCount(exerciseType);
    final isCompleted = workout.isExerciseCompleted(exerciseType);
    final color = AppTheme.getExerciseColor(exerciseType.key);

    return Column(
      children: [
        Text(
          exerciseType.key.substring(0, 1).toUpperCase(), // First letter
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isCompleted ? color : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          exerciseType.formatCount(count),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isCompleted ? color : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}
