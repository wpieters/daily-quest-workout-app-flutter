import 'package:flutter/material.dart';

import '../models/missed_day_penalty.dart';
import '../utils/theme.dart';
import 'glow_pulse.dart';

/// The "QUEST FAILED" system window shown once after a rollover that
/// charged missed days (handoff 0004). Red counterpart of [LevelUpOverlay].
class MissedDayOverlay extends StatefulWidget {
  final MissedDayPenalty penalty;
  final VoidCallback onDismiss;

  const MissedDayOverlay({
    super.key,
    required this.penalty,
    required this.onDismiss,
  });

  @override
  State<MissedDayOverlay> createState() => _MissedDayOverlayState();
}

class _MissedDayOverlayState extends State<MissedDayOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 450),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.penalty;
    final days = p.days == 1 ? '1 day' : '${p.days} days';
    final verdict = p.lostLevel
        ? 'Lv ${p.fromLevel}  →  Lv ${p.toLevel}'
        : p.protectionLeft > 0
        ? 'Level protected · ${p.protectionLeft} '
              '${p.protectionLeft == 1 ? 'miss' : 'misses'} of protection left'
        : 'Level protection lost';

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
                child: GlowPulse(
                  color: AppTheme.questDanger,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.systemPanel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.questDanger,
                        width: 1.5,
                      ),
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
                          'QUEST FAILED',
                          style: TextStyle(
                            color: AppTheme.questDanger,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$days without a completed exercise',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 32),
                        Text(
                          '-${p.xpLost} XP',
                          style: AppTheme.mono.copyWith(
                            color: AppTheme.questDanger,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          verdict,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.lostLevel
                                ? Colors.white
                                : AppTheme.mutedForeground,
                            fontSize: p.lostLevel ? 20 : 13,
                            fontWeight: p.lostLevel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
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
      ),
    );
  }
}
