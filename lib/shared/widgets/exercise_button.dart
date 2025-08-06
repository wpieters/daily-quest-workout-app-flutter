import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_type.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../features/workout/data/workout_provider.dart';

class ExerciseButton extends ConsumerStatefulWidget {
  final ExerciseType exerciseType;
  final VoidCallback? onStageComplete;

  const ExerciseButton({
    super.key,
    required this.exerciseType,
    this.onStageComplete,
  });

  @override
  ConsumerState<ExerciseButton> createState() => _ExerciseButtonState();
}

class _ExerciseButtonState extends ConsumerState<ExerciseButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _stageController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _stageAnimation;

  int? _previousStage;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: AppConstants.buttonAnimationDuration,
      vsync: this,
    );
    
    _stageController = AnimationController(
      duration: AppConstants.stageAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _stageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stageController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _stageController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    // Haptic feedback
    await HapticFeedback.lightImpact();
    
    // Scale animation
    await _scaleController.forward();
    await _scaleController.reverse();

    // Check for stage completion
    final currentStage = ref.read(exerciseStageProvider(widget.exerciseType));
    if (_previousStage != null && currentStage > _previousStage!) {
      _triggerStageAnimation();
      widget.onStageComplete?.call();
    }
    _previousStage = currentStage;

    // Increment exercise
    ref.read(currentWorkoutProvider.notifier).incrementExercise(widget.exerciseType);
  }

  void _triggerStageAnimation() {
    _stageController.reset();
    _stageController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(exerciseCountProvider(widget.exerciseType));
    final completion = ref.watch(exerciseCompletionProvider(widget.exerciseType));
    final stage = ref.watch(exerciseStageProvider(widget.exerciseType));
    final stageProgress = ref.watch(exerciseStageProgressProvider(widget.exerciseType));
    final runningEnabledAsync = ref.watch(runningEnabledProvider);
    
    final exerciseColor = AppTheme.getExerciseColor(widget.exerciseType.key);
    final isCompleted = completion >= 1.0;
    
    // Check if this is the running button and if running is disabled
    final isRunningDisabled = widget.exerciseType == ExerciseType.running && 
        runningEnabledAsync.maybeWhen(
          data: (enabled) => !enabled,
          orElse: () => false,
        );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRunningDisabled
                    ? [
                        Colors.grey.withOpacity(0.4),
                        Colors.grey.withOpacity(0.3),
                      ]
                    : [
                        exerciseColor.withOpacity(0.8),
                        exerciseColor.withOpacity(0.6),
                      ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
              boxShadow: isRunningDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: exerciseColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
              border: isCompleted
                  ? Border.all(
                      color: AppTheme.stageComplete,
                      width: 2,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                onTap: (isCompleted || isRunningDisabled) ? null : _handleTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Exercise name and completion status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.exerciseType.displayName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCompleted)
                            AnimatedBuilder(
                              animation: _stageAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_stageAnimation.value * 0.2),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.stageComplete,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      
                      // Counter (or disabled text)
                      isRunningDisabled
                          ? Column(
                              children: [
                                const Icon(
                                  Icons.block,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DISABLED',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  widget.exerciseType.formatCount(count),
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '/ ${widget.exerciseType.formatTarget()}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                      
                      // Progress bar
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: completion,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? AppTheme.stageComplete : Colors.white,
                            ),
                            minHeight: AppConstants.progressBarHeight,
                          ),
                          const SizedBox(height: 8),
                          
                          // Stage indicators
                          _buildStageIndicators(stage, stageProgress),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageIndicators(int currentStage, double stageProgress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(AppConstants.totalStages, (index) {
        final isCompleted = index < currentStage;
        final isActive = index == currentStage && stageProgress > 0;
        final isCurrent = index == currentStage;
        
        Color indicatorColor;
        double size = AppConstants.stageIndicatorSize;
        
        if (isCompleted) {
          indicatorColor = AppTheme.stageComplete;
          size *= 1.2;
        } else if (isActive) {
          indicatorColor = Colors.white.withOpacity(0.7);
          size *= 1.1;
        } else {
          indicatorColor = Colors.white.withOpacity(0.3);
        }

        Widget indicator = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
            border: isCurrent && !isCompleted
                ? Border.all(color: Colors.white, width: 1)
                : null,
          ),
        );

        // Add stage completion animation
        if (isCurrent && stageProgress > 0) {
          indicator = AnimatedBuilder(
            animation: _stageAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_stageAnimation.value * 0.5),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                    boxShadow: _stageAnimation.value > 0.5
                        ? [
                            BoxShadow(
                              color: AppTheme.stageComplete.withOpacity(
                                (_stageAnimation.value).clamp(0.0, 1.0),
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          );
        }

        return Expanded(
          child: Center(child: indicator),
        );
      }),
    );
  }
}
