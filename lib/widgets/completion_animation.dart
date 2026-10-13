import 'package:flutter/material.dart';

import '../sprites/sprite_sheet.dart';
import '../utils/theme.dart';
import 'power_up_aura.dart';
import 'sprite_animation.dart';

/// Full-screen "DAILY QUEST COMPLETE" overlay: the pixel hero strikes a
/// victory pose inside an aura that escalates with the streak tier
/// (handoff 0003, ADR 0013). Calls [onComplete] after about 3.5 s.
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
  /// Hero scale-in and backdrop fade.
  late final AnimationController _intro = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  /// Aura pulse, back and forth.
  late final AnimationController _pulse = AnimationController(
    duration: const Duration(milliseconds: 700),
    vsync: this,
  );

  /// Wall clock for particles and arcs.
  late final AnimationController _clock = AnimationController(
    duration: const Duration(seconds: 30),
    vsync: this,
  );

  /// Text fade in (0–0.3), hold, then the whole overlay fades out (0.8–1).
  late final AnimationController _text = AnimationController(
    duration: const Duration(milliseconds: 2500),
    vsync: this,
  );

  late final Animation<double> _heroScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.7, curve: Curves.elasticOut),
  );
  late final Animation<double> _backdrop = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.3, curve: Curves.easeOut),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _text,
    curve: const Interval(0, 0.3, curve: Curves.easeOut),
  );
  late final Animation<double> _overlayFade = Tween(begin: 1.0, end: 0.0)
      .animate(
        CurvedAnimation(
          parent: _text,
          curve: const Interval(0.8, 1, curve: Curves.easeOut),
        ),
      );

  bool _reduced = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.of(context).disableAnimations;
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    if (_reduced) {
      _intro.value = 1;
      _pulse.value = 0.5;
    } else {
      _intro.forward();
      _pulse.repeat(reverse: true);
      _clock.forward();
    }
    // Let the hero land and the aura build before the text.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    await _text.forward();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _clock.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _powerLevelText => switch (widget.powerLevel) {
    0 => 'NEWBIE POWER!',
    1 => 'POWER UP!',
    2 => 'SUPER SAIYAN!',
    3 => 'SUPER SAIYAN 2!',
    4 => 'ULTRA INSTINCT!',
    _ => 'POWER UP!',
  };

  @override
  Widget build(BuildContext context) {
    final tier = widget.powerLevel;
    final color = AppTheme.getPowerLevelColor(tier);
    final height = MediaQuery.sizeOf(context).height;
    final heroScale = height < 700 ? 3.0 : 4.0;
    // Effect cells are 192 px with the action in the middle; this keeps
    // them in proportion to the 72 px hero.
    final fxScale = heroScale * 0.75;
    final animate = !_reduced;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse, _clock, _text]),
        builder: (context, child) {
          return Opacity(
            opacity: _overlayFade.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15 * _backdrop.value),
                    Colors.black.withValues(alpha: 0.85 * _backdrop.value),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PowerUpAura(
                        color: color,
                        tier: tier,
                        pulse: _pulse.value,
                        seconds: _clock.value * 30,
                        centre: const Alignment(0, -0.15),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(scale: _heroScale.value, child: child),
                        const SizedBox(height: 24),
                        Opacity(
                          opacity: _reduced ? 1 : _textFade.value,
                          child: _CompletionText(
                            color: color,
                            powerLevelText: _powerLevelText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        // The sprites are built once, outside the builder, so their tickers
        // aren't restarted on every frame.
        // The box is hero-sized; effect sheets overflow it on all sides so
        // they don't push the text down.
        child: SizedBox.fromSize(
          size: Sprites.fighter.cellSize * heroScale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (tier == 2)
                _Overflowing(
                  child: SpriteAnimation(
                    key: const ValueKey('fire'),
                    sheet: Sprites.fire,
                    frames: Sprites.fireLoop,
                    fps: 10,
                    scale: fxScale,
                    animate: animate,
                  ),
                ),
              if (tier >= 4)
                _Overflowing(
                  child: SpriteAnimation(
                    key: const ValueKey('revive'),
                    sheet: Sprites.revive,
                    frames: Sprites.reviveSparkle,
                    fps: 10,
                    scale: fxScale * 1.3,
                    colorFilter: hueRotate(240),
                    animate: animate,
                  ),
                ),
              SpriteAnimation(
                key: const ValueKey('fighter'),
                sheet: Sprites.fighter,
                frames: Sprites.fighter.frames(SvMotion.victory),
                fps: 5,
                scale: heroScale,
                animate: animate,
                stillFrame: 2,
              ),
              if (tier >= 3 && animate)
                _Overflowing(
                  child: SpriteAnimation(
                    key: const ValueKey('thunder'),
                    sheet: Sprites.thunder,
                    frames: Sprites.thunderStrike,
                    fps: 12,
                    loop: false,
                    scale: fxScale,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets an effect sheet be larger than the hero's box, centred on it.
class _Overflowing extends StatelessWidget {
  final Widget child;
  const _Overflowing({required this.child});

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: child,
    );
  }
}

class _CompletionText extends StatelessWidget {
  final Color color;
  final String powerLevelText;

  const _CompletionText({required this.color, required this.powerLevelText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DAILY QUEST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'COMPLETE!',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: const [Shadow(color: Colors.white, blurRadius: 5)],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          powerLevelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}
