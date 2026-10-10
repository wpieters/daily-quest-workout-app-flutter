import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../utils/theme.dart';

/// The STATUS window: level, job, title, bars, and the stat grid.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(progressionEngineProvider);
    final p = ref.watch(workoutProvider).progress.progression;
    final config = engine.config;
    final leveling = engine.leveling;
    final level = engine.levelOf(p);
    final span = leveling.xpSpanOfLevel(p.totalXp);
    final into = leveling.xpIntoLevel(p.totalXp);
    final hp = p.stats.hp(config);
    final mp = p.stats.mp(config);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STATUS',
          style: TextStyle(
            color: AppTheme.questPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.questPrimary.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Level, job and title
          Column(
            children: [
              Text(
                '$level',
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'LEVEL',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _labelled('JOB', 'Hunter'),
              const SizedBox(height: 4),
              _labelled('TITLE', engine.titleOf(p)),
            ],
          ),
          const SizedBox(height: 20),

          // Bars
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.panel(borderAlpha: 0.2),
            child: Column(
              children: [
                _bar('EXP', into, span == 0 ? into : span, AppTheme.powerPurple,
                    span == 0 ? 'MAX' : null),
                _bar('HP', hp, hp, AppTheme.questDanger),
                _bar('MP', mp, mp, AppTheme.questPrimary),
                _bar('FATIGUE', p.fatigueCurrent, p.fatigueMax,
                    AppTheme.questSuccess),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stat grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.panel(borderAlpha: 0.2),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _stat('STR', p.stats.strength),
                          _stat('VIT', p.stats.vitality),
                          _stat('AGI', p.stats.agility),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _stat('INT', p.stats.intelligence),
                          _stat('PER', p.stats.perception),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Text('POINTS:', style: _statLabel),
                                const Spacer(),
                                Text(
                                  '${p.skillPoints}',
                                  style: const TextStyle(
                                    color: AppTheme.questWarning,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
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
                const Divider(height: 24),
                const Text(
                  'STR ← PUSH-UPS · VIT ← SIT-UPS · AGI ← SQUATS\n'
                  'INT & PER ← SKILLS AND ITEMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 10,
                    letterSpacing: 1,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (p.consecutiveMissedDays > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.panel(borderColor: AppTheme.questDanger),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WARNING - ${p.consecutiveMissedDays} DAILY QUEST(S) '
                    'MISSED IN A ROW',
                    style: const TextStyle(
                      color: AppTheme.questDanger,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.consecutiveMissedDays < config.levelProtectionDays
                        ? 'Level protected for '
                            '${config.levelProtectionDays - p.consecutiveMissedDays} '
                            'more missed day(s).'
                        : 'Level protection lost. Complete an exercise to stop '
                            'losing XP.',
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _statLabel = TextStyle(
    color: AppTheme.foreground,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  Widget _labelled(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
    );
  }

  Widget _bar(String label, int value, int max, Color color, [String? text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                text ?? '$value/$max',
                style: AppTheme.mono.copyWith(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 6,
              backgroundColor: AppTheme.muted,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: _statLabel),
          const Spacer(),
          Text(
            '$value',
            style: AppTheme.mono.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
