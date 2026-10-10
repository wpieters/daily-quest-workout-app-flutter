import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A panel whose cyan glow pulses (5px -> 30px and back, every 2s).
/// Shows a steady glow when the platform asks for reduced motion.
class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;

  const GlowPulse({
    super.key,
    required this.child,
    this.color = AppTheme.questPrimary,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 + 0.3 * t),
                blurRadius: 5 + 15 * t,
              ),
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * t),
                blurRadius: 30 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
