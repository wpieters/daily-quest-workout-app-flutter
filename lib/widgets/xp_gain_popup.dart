import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// "+100 XP" that floats up and fades out. Give it a new key per award so
/// each award replays the animation.
class XpGainPopup extends StatefulWidget {
  final int amount;

  const XpGainPopup({super.key, required this.amount});

  @override
  State<XpGainPopup> createState() => _XpGainPopupState();
}

class _XpGainPopupState extends State<XpGainPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Opacity(
            opacity: (1 - _controller.value).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -40 * t),
              child: child,
            ),
          );
        },
        child: Text(
          '+${widget.amount} XP',
          style: const TextStyle(
            color: AppTheme.systemBlue,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}
