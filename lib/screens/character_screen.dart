import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';
import '../utils/theme.dart';

/// Character sheet: level, title, derived HP/MP, fatigue and stats.
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

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Status'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Panel(
            children: [
              _row('LEVEL', '$level'),
              _row('TITLE', engine.titleOf(p)),
              _row('XP', span == 0 ? 'MAX' : '$into / $span'),
              _row('TOTAL XP', '${p.totalXp}'),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            children: [
              _bar('HP', p.stats.hp(config), p.stats.hp(config),
                  Colors.redAccent),
              _bar('MP', p.stats.mp(config), p.stats.mp(config),
                  AppTheme.systemBlue),
              _bar('FATIGUE', p.fatigueCurrent, p.fatigueMax, Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            children: [
              _stat('STRENGTH', p.stats.strength, 'Push-ups'),
              _stat('VITALITY', p.stats.vitality, 'Sit-ups'),
              _stat('AGILITY', p.stats.agility, 'Squats'),
              _stat('INTELLIGENCE', p.stats.intelligence, 'Skills & items'),
              _stat('PERCEPTION', p.stats.perception, 'Skills & items'),
              const Divider(color: Colors.white24, height: 24),
              _row('AVAILABLE POINTS', '${p.skillPoints}'),
            ],
          ),
          if (p.consecutiveMissedDays > 0) ...[
            const SizedBox(height: 16),
            _Panel(
              children: [
                _row(
                  'MISSED DAYS',
                  '${p.consecutiveMissedDays} in a row',
                  valueColor: Colors.redAccent,
                ),
                Text(
                  p.consecutiveMissedDays < config.levelProtectionDays
                      ? 'Level protected for '
                          '${config.levelProtectionDays - p.consecutiveMissedDays} '
                          'more missed day(s).'
                      : 'Level protection lost. Complete an exercise to stop '
                          'losing XP.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const _label = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  Widget _row(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: _label),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: _label),
              const Spacer(),
              Text(
                '$value / $max',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, String source) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _label),
                Text(
                  source,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.systemPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.systemBlue.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.systemBlue.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
