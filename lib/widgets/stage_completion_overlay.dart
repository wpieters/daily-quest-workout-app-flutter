import 'package:flutter/material.dart';
import '../models/exercise_type.dart';

class StageCompletionOverlay extends StatefulWidget {
  final ExerciseType exercise;
  final int stage;
  final VoidCallback onComplete;

  const StageCompletionOverlay({
    super.key,
    required this.exercise,
    required this.stage,
    required this.onComplete,
  });

  @override
  State<StageCompletionOverlay> createState() => _StageCompletionOverlayState();
}

class _StageCompletionOverlayState extends State<StageCompletionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _fadeController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Color _getExerciseColor() {
    switch (widget.exercise) {
      case ExerciseType.pushups:
        return Colors.blue;
      case ExerciseType.situps:
        return Colors.orange;
      case ExerciseType.squats:
        return Colors.purple;
      case ExerciseType.running:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseColor = _getExerciseColor();
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          exerciseColor.withOpacity(0.9),
                          exerciseColor.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: exerciseColor.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stage completion icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.exercise.icon,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stage text
                        Text(
                          'STAGE ${widget.stage}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'COMPLETE!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Exercise name
                        Text(
                          widget.exercise.displayName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}