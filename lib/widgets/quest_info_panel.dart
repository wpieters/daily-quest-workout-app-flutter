import 'package:flutter/material.dart';

import '../models/workout_day.dart';
import '../utils/theme.dart';
import 'glow_pulse.dart';

/// The "QUEST INFO" system window: today's goals, the penalty warning, and
/// the streak. Glows once the daily quest is complete.
class QuestInfoPanel extends StatelessWidget {
  final WorkoutDay day;
  final int streak;

  const QuestInfoPanel({super.key, required this.day, required this.streak});

  @override
  Widget build(BuildContext context) {
    final complete = day.isComplete;
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.panel(
        borderColor: complete ? AppTheme.questSuccess : null,
        borderAlpha: complete ? 0.7 : 0.3,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: AppTheme.questPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'QUEST INFO',
                style: TextStyle(
                  color: AppTheme.questPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'DAILY QUEST - TRAIN TO BECOME\nA FORMIDABLE COMBATANT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'GOALS',
            style: TextStyle(
              color: AppTheme.questSuccess,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _goal('PUSH-UPS', '${day.pushups}/100', day.pushups >= 100),
          _goal('SIT-UPS', '${day.situps}/100', day.situps >= 100),
          _goal('SQUATS', '${day.squats}/100', day.squats >= 100),
          _goal(
            'RUN',
            day.runningEnabled ? '${formatKm(day.running)}/10KM' : 'DISABLED',
            day.running >= 100,
            enabled: day.runningEnabled,
          ),
          const SizedBox(height: 16),
          if (complete)
            const Text(
              'QUEST COMPLETE',
              style: TextStyle(
                color: AppTheme.questSuccess,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            )
          else
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'CAUTION!',
                    style: TextStyle(
                      color: AppTheme.questDanger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' - IF THE DAILY QUEST\nREMAINS INCOMPLETE, PENALTIES\n'
                        'WILL BE GIVEN ACCORDINGLY.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          if (streak > 0) ...[
            const SizedBox(height: 12),
            Text(
              '🔥 $streak DAY STREAK 🔥',
              style: const TextStyle(
                color: AppTheme.questWarning,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );

    return complete
        ? GlowPulse(color: AppTheme.questSuccess, child: panel)
        : panel;
  }

  Widget _goal(String name, String value, bool done, {bool enabled = true}) {
    final color = !enabled
        ? AppTheme.mutedForeground
        : done
        ? AppTheme.questSuccess
        : AppTheme.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('-$name', style: TextStyle(color: color, fontSize: 14)),
          const Spacer(),
          Text(
            '[$value]',
            style: AppTheme.mono.copyWith(color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// 100m units as kilometres, e.g. 32 -> "3.2KM".
String formatKm(int units) => '${(units / 10).toStringAsFixed(1)}KM';
