import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_button.dart';
import '../widgets/completion_animation.dart';
import '../widgets/stage_completion_overlay.dart';
import '../models/exercise_type.dart';
import '../utils/theme.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    
    if (workoutState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DailyQuest',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.getPowerLevelColor(workoutState.progress.powerLevelTier),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                workoutState.progress.powerLevel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Motivational text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'TRAIN TO BECOME A FORMIDABLE COMBATANT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Streak display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPowerLevelGradient(
                      workoutState.progress.powerLevelTier,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getPowerLevelColor(
                          workoutState.progress.powerLevelTier,
                        ).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${workoutState.progress.currentStreak}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'days',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Exercise buttons grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                  children: [
                    ExerciseButton(
                      exercise: ExerciseType.pushups,
                      count: workoutState.currentDay.pushups,
                      target: 100,
                      progress: workoutState.currentDay.pushupsProgress,
                      stage: workoutState.currentDay.pushupsStage,
                      onTap: () => ref.read(workoutProvider.notifier)
                          .incrementExercise(ExerciseType.pushups),
                    ),
                    ExerciseButton(
                      exercise: ExerciseType.situps,
                      count: workoutState.currentDay.situps,
                      target: 100,
                      progress: workoutState.currentDay.situpsProgress,
                      stage: workoutState.currentDay.situpsStage,
                      onTap: () => ref.read(workoutProvider.notifier)
                          .incrementExercise(ExerciseType.situps),
                    ),
                    ExerciseButton(
                      exercise: ExerciseType.squats,
                      count: workoutState.currentDay.squats,
                      target: 100,
                      progress: workoutState.currentDay.squatsProgress,
                      stage: workoutState.currentDay.squatsStage,
                      onTap: () => ref.read(workoutProvider.notifier)
                          .incrementExercise(ExerciseType.squats),
                    ),
                    ExerciseButton(
                      exercise: ExerciseType.running,
                      count: workoutState.currentDay.running,
                      target: 100,
                      progress: workoutState.currentDay.runningProgress,
                      stage: workoutState.currentDay.runningStage,
                      isRunning: true,
                      isEnabled: workoutState.currentDay.runningEnabled,
                      onTap: () => ref.read(workoutProvider.notifier)
                          .incrementExercise(ExerciseType.running),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Running toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: workoutState.currentDay.runningEnabled,
                        onChanged: (_) => ref.read(workoutProvider.notifier)
                            .toggleRunning(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Include Running',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Toggle to include/exclude running from daily completion',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Daily completion status
                if (workoutState.currentDay.isComplete)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Daily Quest Complete!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Amazing work, warrior!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Completion animation overlay
          if (workoutState.showCompletionAnimation)
            CompletionAnimation(
              powerLevel: workoutState.progress.powerLevelTier,
              onComplete: () {
                ref.read(workoutProvider.notifier).hideCompletionAnimation();
              },
            ),
          
          // Stage completion overlay
          if (workoutState.lastCompletedStage > 0 && 
              workoutState.lastCompletedExercise != null)
            StageCompletionOverlay(
              exercise: workoutState.lastCompletedExercise!,
              stage: workoutState.lastCompletedStage,
              onComplete: () {
                ref.read(workoutProvider.notifier).hideStageAnimation();
              },
            ),
        ],
      ),
    );
  }
}