import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_quest/core/constants/app_theme.dart';
import 'package:daily_quest/shared/models/exercise_type.dart';

class ExerciseButton extends StatelessWidget {
  final ExerciseType exerciseType;
  final int count;
  final VoidCallback onTap;
  final double completionPercentage;
  final int completedStages;
  final bool enabled;

  const ExerciseButton({
    Key? key,
    required this.exerciseType,
    required this.count,
    required this.onTap,
    required this.completionPercentage,
    required this.completedStages,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = AppTheme.getProgressColor(completionPercentage);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () {
          // Provide haptic feedback on tap
          HapticFeedback.mediumImpact();
          onTap();
        } : null,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: progressColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: progressColor,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Exercise emoji and name
              Text(
                exerciseType.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseType.displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Counter display
              Text(
                '$count / ${exerciseType.target}',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),

              // Progress bar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: completionPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Stage indicators
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    10,
                    (index) => _buildStageIndicator(index < completedStages, progressColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageIndicator(bool completed, Color progressColor) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? progressColor : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}
