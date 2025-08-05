import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../services/daily_reset_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final resetService = ref.watch(dailyResetServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress Section
          _buildSection(
            context,
            'Progress',
            [
              _buildInfoTile(
                'Current Streak',
                '${workoutState.progress.currentStreak} days',
                AppTheme.getPowerLevelColor(workoutState.progress.powerLevelTier),
              ),
              _buildInfoTile(
                'Longest Streak',
                '${workoutState.progress.longestStreak} days',
                Colors.orange,
              ),
              _buildInfoTile(
                'Total Workouts',
                '${workoutState.progress.totalWorkouts}',
                Colors.blue,
              ),
              _buildInfoTile(
                'Power Level',
                workoutState.progress.powerLevel,
                AppTheme.getPowerLevelColor(workoutState.progress.powerLevelTier),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Workout Settings
          _buildSection(
            context,
            'Workout Settings',
            [
              SwitchListTile(
                title: const Text('Include Running'),
                subtitle: const Text('Toggle running requirement for daily completion'),
                value: workoutState.currentDay.runningEnabled,
                onChanged: (_) => ref.read(workoutProvider.notifier).toggleRunning(),
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // System Info
          _buildSection(
            context,
            'System',
            [
              _buildInfoTile(
                'Time Until Reset',
                _formatDuration(resetService.timeUntilReset),
                Colors.purple,
              ),
              _buildInfoTile(
                'Today\'s Date',
                '${workoutState.currentDay.date.day}/${workoutState.currentDay.date.month}/${workoutState.currentDay.date.year}',
                Colors.grey,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          _buildSection(
            context,
            'Actions',
            [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reset Today\'s Progress'),
                subtitle: const Text('Clear today\'s workout counters'),
                onTap: () => _showResetDialog(context, ref, false),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Reset All Data'),
                subtitle: const Text('Clear all progress and start fresh'),
                onTap: () => _showResetDialog(context, ref, true),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // App Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'DailyQuest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Workout Tracker inspired by One Punch Man',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0',
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
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.info_outline,
          color: color,
          size: 20,
        ),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, bool resetAll) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resetAll ? 'Reset All Data' : 'Reset Today\'s Progress'),
        content: Text(
          resetAll
              ? 'This will permanently delete all your progress, streaks, and workout history. This action cannot be undone.'
              : 'This will reset today\'s workout counters to zero. Your streak and history will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (resetAll) {
                // TODO: Implement full reset
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full reset not implemented yet')),
                );
              } else {
                ref.read(workoutProvider.notifier).resetDay();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Today\'s progress reset')),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: resetAll ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}