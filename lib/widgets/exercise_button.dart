import 'package:flutter/material.dart';
import '../models/exercise_type.dart';

class ExerciseButton extends StatefulWidget {
  final ExerciseType exercise;
  final int count;
  final int target;
  final double progress;
  final int stage;
  final bool isRunning;
  final bool isEnabled;
  final VoidCallback onTap;

  const ExerciseButton({
    super.key,
    required this.exercise,
    required this.count,
    required this.target,
    required this.progress,
    required this.stage,
    required this.onTap,
    this.isRunning = false,
    this.isEnabled = true,
  });

  @override
  State<ExerciseButton> createState() => _ExerciseButtonState();
}

class _ExerciseButtonState extends State<ExerciseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  Color _getButtonColor() {
    final baseColors = {
      ExerciseType.pushups: Colors.blue,
      ExerciseType.situps: Colors.orange,
      ExerciseType.squats: Colors.purple,
      ExerciseType.running: Colors.green,
    };
    
    return baseColors[widget.exercise] ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor();
    final isComplete = widget.count >= widget.target;
    final canTap = widget.isEnabled && !isComplete;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: canTap ? _handleTap : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: !widget.isEnabled
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : isComplete
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [
                              buttonColor.withOpacity(0.8),
                              buttonColor,
                              buttonColor.withOpacity(0.8),
                            ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: !widget.isEnabled
                        ? Colors.grey.withOpacity(0.3)
                        : (isComplete ? Colors.green : buttonColor)
                            .withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: canTap ? _handleTap : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Exercise icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.exercise.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Exercise name
                        Text(
                          widget.exercise.displayName,
                          style: TextStyle(
                            color: widget.isEnabled ? Colors.white : Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Count display
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: '${widget.count}'),
                              TextSpan(
                                text: '/${widget.target}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress bar
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: widget.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Stage indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Stage ${widget.stage}/10',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isComplete) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        
                        // Running distance indicator
                        if (widget.isRunning) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(widget.count * 0.1).toStringAsFixed(1)}km',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}