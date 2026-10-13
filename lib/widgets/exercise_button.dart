import 'package:flutter/material.dart';
import '../models/exercise_type.dart';
import '../utils/theme.dart';
import 'quest_info_panel.dart';

/// A quest panel for one exercise. Tapping the panel adds a rep (or 100m),
/// holding it adds a set of ten; the minus button undoes a mis-tap, and
/// holding that removes ten.
class ExerciseButton extends StatefulWidget {
  final ExerciseType exercise;
  final int count;
  final int target;
  final double progress;
  final int stage;
  final bool isRunning;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDecrement;
  final VoidCallback? onDecrementLong;

  const ExerciseButton({
    super.key,
    required this.exercise,
    required this.count,
    required this.target,
    required this.progress,
    required this.stage,
    required this.onTap,
    this.onLongPress,
    this.onDecrement,
    this.onDecrementLong,
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

  bool _set = false;

  // setState so the cached panel subtree picks up the "+10" label.
  void _handleTap() {
    setState(() => _set = false);
    _controller.forward(from: 0);
    widget.onTap();
  }

  void _handleLongPress() {
    setState(() => _set = true);
    _controller.forward(from: 0);
    widget.onLongPress!();
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
              onLongPress: canTap && widget.onLongPress != null
                  ? _handleLongPress
                  : null,
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
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
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
                        // "+10" floats up and fades after a long press.
                        if (_set)
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final t = _controller.value;
                              if (!_controller.isAnimating) {
                                return const SizedBox.shrink();
                              }
                              return Transform.translate(
                                offset: Offset(0, -16 - 20 * t),
                                child: Opacity(
                                  opacity: 1 - t,
                                  child: Text(
                                    widget.isRunning ? '+1KM' : '+10',
                                    style: AppTheme.mono.copyWith(
                                      fontSize: 16,
                                      color: AppTheme.questPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? '⚡ QUEST COMPLETE ⚡'
                          : widget.isEnabled
                              ? (widget.isRunning
                                  ? 'TAP +100M · HOLD +1KM'
                                  : 'TAP +1 · HOLD +10')
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
                        // The tooltip's default trigger is a long press,
                        // which would swallow the hold; hover still shows it.
                        TooltipTheme(
                          data: const TooltipThemeData(
                              triggerMode: TooltipTriggerMode.manual),
                          child: IconButton(
                            icon: const Icon(Icons.remove),
                            tooltip: widget.isRunning
                                ? 'Remove 100m (hold: 1km)'
                                : 'Remove one rep (hold: ten)',
                            color: AppTheme.questPrimary,
                            disabledColor:
                                AppTheme.mutedForeground.withValues(alpha: 0.4),
                            visualDensity: VisualDensity.compact,
                            onPressed: canDecrement ? widget.onDecrement : null,
                            onLongPress:
                                canDecrement ? widget.onDecrementLong : null,
                          ),
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
