import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../sprites/sprite_sheet.dart';

/// Decoded sheet images, cached for the session.
class SpriteImages {
  SpriteImages._();

  static final Map<String, Future<ui.Image>> _cache = {};

  /// Replaces asset decoding, for tests.
  @visibleForTesting
  static Future<ui.Image> Function(String asset)? loader;

  static Future<ui.Image> load(String asset) =>
      _cache.putIfAbsent(asset, () => (loader ?? _decode)(asset));

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    return decodeImageFromList(data.buffer.asUint8List());
  }

  /// Starts decoding every bundled sheet so the first overlay has no blank
  /// frame. Safe to call more than once.
  static void warmUp() {
    for (final sheet in Sprites.all) {
      load(sheet.asset).ignore();
    }
  }

  @visibleForTesting
  static void reset() => _cache.clear();
}

/// Rotates hues by [degrees], for recolouring an effect sheet at runtime.
ColorFilter hueRotate(double degrees) {
  final a = degrees * math.pi / 180;
  final c = math.cos(a), s = math.sin(a);
  // Rec. 601 luma weights keep brightness steady while hue turns.
  const lr = 0.213, lg = 0.715, lb = 0.072;
  return ColorFilter.matrix([
    lr + c * (1 - lr) + s * -lr,
    lg + c * -lg + s * -lg,
    lb + c * -lb + s * (1 - lb),
    0,
    0, //
    lr + c * -lr + s * 0.143,
    lg + c * (1 - lg) + s * 0.140,
    lb + c * -lb + s * -0.283,
    0,
    0,
    lr + c * -lr + s * -(1 - lr),
    lg + c * -lg + s * lg,
    lb + c * (1 - lb) + s * lb,
    0,
    0,
    0, 0, 0, 1, 0,
  ]);
}

/// Plays [frames] (cell indices into [sheet]) at [fps], scaled by [scale]
/// with nearest-neighbour sampling so pixels stay crisp.
class SpriteAnimation extends StatefulWidget {
  final SpriteSheet sheet;
  final List<int> frames;
  final double fps;
  final bool loop;
  final double scale;
  final ColorFilter? colorFilter;

  /// When false, shows [stillFrame] (default: the last frame) and never
  /// starts a ticker, for reduced motion.
  final bool animate;
  final int? stillFrame;

  /// Called once when a non-looping animation has played through. After
  /// that nothing is painted: one-shot effects end empty, as in RPG Maker.
  final VoidCallback? onDone;

  const SpriteAnimation({
    super.key,
    required this.sheet,
    required this.frames,
    this.fps = 8,
    this.loop = true,
    this.scale = 1,
    this.colorFilter,
    this.animate = true,
    this.stillFrame,
    this.onDone,
  }) : assert(frames.length > 0);

  @override
  State<SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<SpriteAnimation>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late Future<ui.Image> _image;
  int _frame = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _image = SpriteImages.load(widget.sheet.asset);
    _frame = widget.animate ? 0 : _still;
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(SpriteAnimation old) {
    super.didUpdateWidget(old);
    if (old.sheet.asset != widget.sheet.asset) {
      _image = SpriteImages.load(widget.sheet.asset);
    }
    if (old.frames != widget.frames && _frame >= widget.frames.length) {
      _frame = widget.animate ? 0 : _still;
    }
    if (old.animate != widget.animate) {
      if (widget.animate) {
        _done = false;
        _ticker.start();
      } else {
        _ticker.stop();
        _frame = _still;
      }
    }
  }

  int get _still => widget.stillFrame ?? widget.frames.length - 1;

  void _tick(Duration elapsed) {
    final n = widget.frames.length;
    var index = (elapsed.inMicroseconds / 1e6 * widget.fps).floor();
    if (widget.loop) {
      index %= n;
    } else if (index >= n) {
      _ticker.stop();
      if (!_done) {
        setState(() => _done = true);
        widget.onDone?.call();
      }
      return;
    }
    if (index != _frame) setState(() => _frame = index);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.sheet.cellSize * widget.scale;
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null || _done) return SizedBox.fromSize(size: size);
        return CustomPaint(
          size: size,
          painter: SpritePainter(
            image: image,
            source: widget.sheet.rectOf(widget.frames[_frame]),
            frame: _frame,
            colorFilter: widget.colorFilter,
          ),
        );
      },
    );
  }
}

class SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect source;

  /// Position within the frame list; exposed for tests.
  final int frame;
  final ColorFilter? colorFilter;

  SpritePainter({
    required this.image,
    required this.source,
    required this.frame,
    this.colorFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..colorFilter = colorFilter;
    canvas.drawImageRect(image, source, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(SpritePainter old) =>
      old.image != image ||
      old.source != source ||
      old.colorFilter != colorFilter;
}
