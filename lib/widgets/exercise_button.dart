import 'package:flutter/material.dart';
import '../models/exercise_type.dart';
import '../utils/theme.dart';
import 'quest_info_panel.dart';

/// A quest panel for one exercise. Tapping the panel adds a rep (or 100m);
/// the minus button undoes a mis-tap.
class ExerciseButton extends StatefulWidget {
  final ExerciseType exercise;
  final int count;
  final int target;
  final double progress;
  final int stage;
  final bool isRunning;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;

  const ExerciseButton({
    super.key,
    required this.exercise,
    required this.count,
    required this.target,
    required this.progress,
    required this.stage,
    required this.onTap,
    this.onDecrement,
    this.isRunning = false,
    this.isEnabled = true,
  });

  @override
  State<ExerciseButton> createState() => _ExerciseButtonState();
}

class _ExerciseButtonState extends State<ExerciseButton>
    with SingleTickerProviderStateMixin {
  // Drives both the press scale and the expanding power-up ring.
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  String _format(int units) => widget.isRunning ? formatKm(units) : '$units';

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.count >= widget.target;
    final canTap = widget.isEnabled && !isComplete;
    final canDecrement =
        widget.isEnabled && widget.count > 0 && widget.onDecrement != null;
    final accent = isComplete ? AppTheme.questSuccess : AppTheme.questPrimary;
    final title = widget.exercise.displayName.toUpperCase();

    return Opacity(
      opacity: widget.isEnabled ? 1 : 0.4,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final active = _controller.isAnimating;
          // Scale 1 -> 1.04 -> 1; ring spreads 0 -> 16px while fading out.
          final scale = 1 + 0.04 * (1 - (2 * t - 1).abs());
          return Transform.scale(
            scale: active ? scale : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.questPrimary
                              .withValues(alpha: 0.7 * (1 - t)),
                          spreadRadius: 16 * t,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: AppTheme.panel(
              borderColor: widget.isEnabled ? accent : AppTheme.mutedForeground,
              borderAlpha: isComplete ? 0.8 : 0.3,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              splashColor: AppTheme.questPrimary.withValues(alpha: 0.2),
              onTap: canTap ? _handleTap : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(widget.exercise.icon,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '[${_format(widget.count)} / '
                        '${widget.isRunning ? '10KM' : widget.target}]',
                        style: AppTheme.mono.copyWith(
                          fontSize: 20,
                          color: isComplete
                              ? AppTheme.questSuccess
                              : AppTheme.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? '⚡ QUEST COMPLETE ⚡'
                          : widget.isEnabled
                              ? 'TAP TO ADD ${widget.isRunning ? '100M' : '1'}'
                              : 'DISABLED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isComplete
                            ? AppTheme.questSuccess
                            : AppTheme.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.muted,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip:
                              'Remove ${widget.isRunning ? '100m' : 'one rep'}',
                          color: AppTheme.questPrimary,
                          disabledColor:
                              AppTheme.mutedForeground.withValues(alpha: 0.4),
                          visualDensity: VisualDensity.compact,
                          onPressed: canDecrement ? widget.onDecrement : null,
                        ),
                        const Spacer(),
                        Text(
                          'STAGE ${widget.stage}/10',
                          style: const TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
