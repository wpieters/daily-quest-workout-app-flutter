import 'package:flutter/material.dart';
import '../progression/progression_engine.dart';
import '../utils/theme.dart';

/// Solo Leveling style "system window" for a level-up, including any title
/// unlocked. Placeholder animation (fade + scale) until real assets exist.
class LevelUpOverlay extends StatefulWidget {
  final LevelChange change;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.change,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.change;
    final newTitle = change.newTitle;
    final gains = <String>[
      if (change.strengthDelta != 0) 'STR  +${change.strengthDelta}',
      if (change.vitalityDelta != 0) 'VIT  +${change.vitalityDelta}',
      if (change.agilityDelta != 0) 'AGI  +${change.agilityDelta}',
      if (change.skillPointsGained != 0)
        'Skill points  +${change.skillPointsGained}',
      if (change.fatigueMaxGained != 0)
        'Max fatigue  +${change.fatigueMaxGained}',
    ];

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: FadeTransition(
          opacity: _controller,
          child: Container(
            color: Colors.black.withValues(alpha: 0.8),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.systemPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.systemBlue, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.systemBlue.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NOTIFICATION',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          color: AppTheme.systemBlue,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lv ${change.fromLevel}  →  Lv ${change.toLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (gains.isNotEmpty) ...[
                        const Divider(color: Colors.white24, height: 32),
                        for (final gain in gains)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              gain,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                      ],
                      if (newTitle != null) ...[
                        const Divider(color: Colors.white24, height: 32),
                        const Text(
                          'TITLE ACQUIRED',
                          style: TextStyle(
                            color: AppTheme.powerYellow,
                            fontSize: 12,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '[$newTitle]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.powerYellow,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Tap to continue',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
