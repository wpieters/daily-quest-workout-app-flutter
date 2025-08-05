import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CompletionAnimation extends StatefulWidget {
  final int powerLevel;
  final VoidCallback onComplete;

  const CompletionAnimation({
    super.key,
    required this.powerLevel,
    required this.onComplete,
  });

  @override
  State<CompletionAnimation> createState() => _CompletionAnimationState();
}

class _CompletionAnimationState extends State<CompletionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _overlayFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _overlayFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    _mainController.forward();
    _particleController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 800));
    await _textController.forward();
    
    widget.onComplete();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _getPowerLevelText() {
    switch (widget.powerLevel) {
      case 0: return 'NEWBIE POWER!';
      case 1: return 'POWER UP!';
      case 2: return 'SUPER SAIYAN!';
      case 3: return 'SUPER SAIYAN 2!';
      case 4: return 'ULTRA INSTINCT!';
      default: return 'POWER UP!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final powerColor = AppTheme.getPowerLevelColor(widget.powerLevel);
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _rotationAnimation,
          _particleAnimation,
          _textFadeAnimation,
          _overlayFadeAnimation,
        ]),
        builder: (context, child) {
          return Opacity(
            opacity: _overlayFadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    powerColor.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Animated particles
                  ...List.generate(20, (index) {
                    final angle = (index * 18.0) * (3.14159 / 180);
                    final radius = 150 + (50 * _particleAnimation.value);
                    final x = MediaQuery.of(context).size.width / 2 + 
                             (radius * _particleAnimation.value) * 
                             (index.isEven ? 1 : -1) * 
                             (0.5 + 0.5 * index / 20);
                    final y = MediaQuery.of(context).size.height / 2 + 
                             (radius * _particleAnimation.value) * 
                             (index.isOdd ? 1 : -1) * 
                             (0.5 + 0.5 * index / 20);
                    
                    return Positioned(
                      left: x,
                      top: y,
                      child: Transform.rotate(
                        angle: angle + (_rotationAnimation.value * 3.14159),
                        child: Opacity(
                          opacity: (1.0 - _particleAnimation.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: powerColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: powerColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // Main power-up animation
                  Center(
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 3.14159,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                powerColor.withOpacity(0.9),
                                powerColor.withOpacity(0.6),
                                powerColor.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 0.8, 1.0],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: powerColor.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '⚡',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Power level text
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 250),
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DAILY QUEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: powerColor,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'COMPLETE!',
                              style: TextStyle(
                                color: powerColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              _getPowerLevelText(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: powerColor,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}