import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../models/workout_day.dart';
import '../utils/theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final history = workoutState.progress.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: history.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final workout = history[history.length - 1 - index]; // Reverse order
                return _buildWorkoutCard(context, workout, index == 0);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Workout History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first daily quest to see your progress here!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutDay workout, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isToday 
            ? Border.all(color: AppTheme.primaryBlue, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isToday ? AppTheme.primaryBlue : Colors.black)
                .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(workout.date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                _buildCompletionBadge(workout),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Exercise Progress
            Row(
              children: [
                Expanded(
                  child: _buildExerciseProgress(
                    '💪',
                    'Push-ups',
                    workout.pushups,
                    100,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExerciseProgress(
                    '🔥',
                    'Sit-ups',
                    workout.situps,
                    100,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildExerciseProgress(
                    '🦵',
                    'Squats',
                    workout.squats,
                    100,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExerciseProgress(
                    '🏃',
                    'Running',
                    workout.running,
                    100,
                    Colors.green,
                    isRunning: true,
                    enabled: workout.runningEnabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBadge(WorkoutDay workout) {
    if (workout.isComplete) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 20,
        ),
      );
    } else {
      final totalProgress = (workout.pushups + workout.situps + workout.squats + 
                           (workout.runningEnabled ? workout.running : 100)) / 
                          (workout.runningEnabled ? 400 : 300);
      
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: totalProgress,
              strokeWidth: 3,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
            ),
          ),
          Text(
            '${(totalProgress * 100).round()}%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildExerciseProgress(
    String emoji,
    String name,
    int count,
    int target,
    Color color, {
    bool isRunning = false,
    bool enabled = true,
  }) {
    final progress = enabled ? (count / target).clamp(0.0, 1.0) : 1.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: enabled ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: enabled ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: enabled ? color : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                enabled ? '$count/$target' : 'Disabled',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: enabled ? color : Colors.grey,
                ),
              ),
              if (isRunning && enabled)
                Text(
                  '${(count * 0.1).toStringAsFixed(1)}km',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}