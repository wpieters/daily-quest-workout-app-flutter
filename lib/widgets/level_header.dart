import 'package:flutter/material.dart';
import '../progression/progression_engine.dart';
import '../progression/progression_state.dart';
import '../utils/theme.dart';

/// Level, title and XP bar for the main screen.
class LevelHeader extends StatelessWidget {
  final ProgressionState progression;
  final ProgressionEngine engine;
  final VoidCallback? onTap;

  const LevelHeader({
    super.key,
    required this.progression,
    required this.engine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leveling = engine.leveling;
    final level = engine.levelOf(progression);
    final into = leveling.xpIntoLevel(progression.totalXp);
    final span = leveling.xpSpanOfLevel(progression.totalXp);
    final isMax = span == 0;

    return Semantics(
      button: onTap != null,
      label: 'Level $level, ${engine.titleOf(progression)}. '
          '${isMax ? 'Max level' : '$into of $span XP'}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.panel(borderAlpha: 0.5),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LV. $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          engine.titleOf(progression),
                          style: const TextStyle(
                            color: AppTheme.systemBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isMax ? 1 : into / span,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.systemBlue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMax ? 'MAX LEVEL' : '$into / $span XP',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
