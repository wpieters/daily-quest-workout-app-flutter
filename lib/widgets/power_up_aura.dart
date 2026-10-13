import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Flutter-drawn part of the power-up: a pulsing glow behind the hero,
/// particles rising from the feet, and for tier 3 up, electric arcs.
///
/// [pulse] runs 0..1 and back; [seconds] is wall-clock time since the
/// overlay opened and drives particle motion. Everything is deterministic
/// for a given input, so it's stable under reduced motion.
class PowerUpAura extends CustomPainter {
  final Color color;
  final int tier;
  final double pulse;
  final double seconds;

  /// Where the hero's centre is, as a fraction of the canvas.
  final Alignment centre;

  const PowerUpAura({
    required this.color,
    required this.tier,
    required this.pulse,
    required this.seconds,
    this.centre = Alignment.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = centre.alongSize(size);
    final base = math.min(size.width, size.height);
    _glow(canvas, c, base);
    if (tier >= 1) _particles(canvas, c, base);
    if (tier >= 3) _arcs(canvas, c, base);
  }

  void _glow(Canvas canvas, Offset c, double base) {
    final radius = base * (0.22 + 0.04 * tier) * (0.9 + 0.2 * pulse);
    final alpha = tier == 0 ? 0.35 : 0.5 + 0.1 * pulse;
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.4),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
    if (tier >= 4) {
      // Ultra Instinct: a silver halo over the colour.
      canvas.drawCircle(
        c,
        radius * 0.8,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 + 0.15 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
  }

  void _particles(Canvas canvas, Offset c, double base) {
    final count = 10 + 8 * tier;
    final rise = base * 0.45;
    final speed = 0.5 + 0.15 * tier; // cycles per second
    final paint = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final rnd = math.Random(i * 7919);
      final phase = rnd.nextDouble();
      final spread = (rnd.nextDouble() * 2 - 1) * base * 0.22;
      final wobble = rnd.nextDouble() * 8;
      final t = (seconds * speed + phase) % 1.0;
      final x = c.dx + spread + math.sin(seconds * 3 + i) * wobble;
      final y = c.dy + base * 0.12 - t * rise;
      final sz = (3 + rnd.nextInt(4)) * (1.5 - t).clamp(0.5, 1.5);
      paint.color = color.withValues(alpha: (1 - t) * 0.9);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: sz, height: sz),
        paint,
      );
    }
  }

  void _arcs(Canvas canvas, Offset c, double base) {
    // New arcs every 80 ms, so they crackle rather than flow.
    final rnd = math.Random((seconds * 12.5).floor());
    final glow = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final arcs = 3 + tier;
    for (var a = 0; a < arcs; a++) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final r0 = base * (0.12 + rnd.nextDouble() * 0.08);
      final r1 = r0 + base * (0.1 + rnd.nextDouble() * 0.12);
      final path = Path()
        ..moveTo(c.dx + math.cos(angle) * r0, c.dy + math.sin(angle) * r0);
      const steps = 5;
      for (var s = 1; s <= steps; s++) {
        final r = r0 + (r1 - r0) * s / steps;
        final jitter = (rnd.nextDouble() - 0.5) * base * 0.06;
        final p = Offset(
          c.dx + math.cos(angle) * r + math.cos(angle + math.pi / 2) * jitter,
          c.dy + math.sin(angle) * r + math.sin(angle + math.pi / 2) * jitter,
        );
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }

  @override
  bool shouldRepaint(PowerUpAura old) =>
      old.pulse != pulse ||
      old.seconds != seconds ||
      old.tier != tier ||
      old.color != color;
}
