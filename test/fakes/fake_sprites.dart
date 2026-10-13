import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:daily_quest/sprites/sprite_sheet.dart';
import 'package:daily_quest/widgets/sprite_animation.dart';

/// Routes [SpriteImages] through synchronously drawn blank images sized
/// like the real sheets, so widget tests never touch the asset bundle or
/// the engine's async decoder.
void useFakeSpriteImages() {
  SpriteImages.reset();
  SpriteImages.loader = (asset) {
    final sheet = Sprites.all.firstWhere(
      (s) => s.asset == asset,
      orElse: () => const SpriteSheet(
        asset: '',
        cellWidth: 8,
        cellHeight: 8,
        columns: 1,
        rows: 1,
      ),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & sheet.imageSize,
      Paint()..color = const Color(0xFFFF00FF),
    );
    final picture = recorder.endRecording();
    return Future.value(
      picture.toImageSync(
        sheet.imageSize.width.toInt(),
        sheet.imageSize.height.toInt(),
      ),
    );
  };
}
