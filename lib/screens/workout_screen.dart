import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_button.dart';
import '../widgets/completion_animation.dart';
import '../widgets/stage_completion_overlay.dart';
import '../widgets/level_header.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/quest_info_panel.dart';
import '../widgets/xp_gain_popup.dart';
import '../models/exercise_type.dart';
import '../utils/theme.dart';
import 'character_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final engine = ref.watch(progressionEngineProvider);
    final notifier = ref.read(workoutProvider.notifier);
    final day = workoutState.currentDay;

    if (workoutState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    ExerciseButton button(
      ExerciseType exercise,
      int count,
      double progress,
      int stage, {
      bool isRunning = false,
      bool isEnabled = true,
    }) {
      return ExerciseButton(
        exercise: exercise,
        count: count,
        target: 100,
        progress: progress,
        stage: stage,
        isRunning: isRunning,
        isEnabled: isEnabled,
        onTap: () => notifier.incrementExercise(exercise),
        onLongPress: () => notifier.incrementExercise(exercise, by: 10),
        onDecrement: () => notifier.decrementExercise(exercise),
        onDecrementLong: () => notifier.decrementExercise(exercise, by: 10),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DAILYQUEST',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.getPowerLevelColor(
                      workoutState.progress.powerLevelTier),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                workoutState.progress.powerLevel.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.getPowerLevelColor(
                      workoutState.progress.powerLevelTier),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
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
                QuestInfoPanel(
                  day: day,
                  streak: workoutState.progress.currentStreak,
                ),

                const SizedBox(height: 16),

                // Level, title and XP
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    LevelHeader(
                      progression: workoutState.progress.progression,
                      engine: engine,
                      onTap: () => _openCharacterSheet(context),
                    ),
                    if (workoutState.xpGainId > 0)
                      Positioned(
                        right: 16,
                        top: -8,
                        child: XpGainPopup(
                          key: ValueKey(workoutState.xpGainId),
                          amount: workoutState.lastXpGain,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Exercise buttons grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    button(ExerciseType.pushups, day.pushups,
                        day.pushupsProgress, day.pushupsStage),
                    button(ExerciseType.situps, day.situps,
                        day.situpsProgress, day.situpsStage),
                    button(ExerciseType.squats, day.squats,
                        day.squatsProgress, day.squatsStage),
                    button(ExerciseType.running, day.running,
                        day.runningProgress, day.runningStage,
                        isRunning: true, isEnabled: day.runningEnabled),
                  ],
                ),

                const SizedBox(height: 16),

                // Running toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.panel(),
                  child: Row(
                    children: [
                      Checkbox(
                        value: day.runningEnabled,
                        onChanged: (_) => notifier.toggleRunning(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INCLUDE RUNNING', style: AppTheme.label),
                            SizedBox(height: 2),
                            Text(
                              'Counts toward completion and the all-four XP bonus',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
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
              onComplete: notifier.hideCompletionAnimation,
            ),

          // Stage completion overlay
          if (workoutState.lastCompletedStage > 0 &&
              workoutState.lastCompletedExercise != null)
            StageCompletionOverlay(
              exercise: workoutState.lastCompletedExercise!,
              stage: workoutState.lastCompletedStage,
              onComplete: notifier.hideStageAnimation,
            ),

          // Level-up ceremony, after the daily completion animation
          if (workoutState.pendingLevelUps.isNotEmpty &&
              !workoutState.showCompletionAnimation)
            LevelUpOverlay(
              key: ObjectKey(workoutState.pendingLevelUps.first),
              change: workoutState.pendingLevelUps.first,
              onDismiss: notifier.dismissLevelUp,
            ),
        ],
      ),
    );
  }

  void _openCharacterSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CharacterScreen()),
    );
  }
}
