import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/sprites/sprite_sheet.dart';

void main() {
  group('SpriteSheet', () {
    test('rectOf walks the grid row-major', () {
      const sheet = SpriteSheet(
        asset: 'x',
        cellWidth: 10,
        cellHeight: 20,
        columns: 3,
        rows: 2,
      );
      expect(sheet.cellCount, 6);
      expect(sheet.rectOf(0), const Rect.fromLTWH(0, 0, 10, 20));
      expect(sheet.rectOf(2), const Rect.fromLTWH(20, 0, 10, 20));
      expect(sheet.rectOf(3), const Rect.fromLTWH(0, 20, 10, 20));
      expect(sheet.rectOf(5), const Rect.fromLTWH(20, 20, 10, 20));
      expect(sheet.imageSize, const Size(30, 40));
    });
  });

  group('SvActorSheet', () {
    const sheet = Sprites.fighter;

    test('matches the RPG Maker MV layout', () {
      expect(sheet.columns, 9);
      expect(sheet.rows, 6);
      expect(sheet.cellSize, const Size(72, 72));
      expect(sheet.imageSize, const Size(648, 432));
    });

    test('motions sit three to a row, three frames each', () {
      expect(sheet.frames(SvMotion.walk), [0, 1, 2, 1]);
      expect(sheet.frames(SvMotion.chant), [6, 7, 8, 7]);
      expect(sheet.frames(SvMotion.guard), [9, 10, 11, 10]);
      expect(sheet.frames(SvMotion.victory), [39, 40, 41, 40]);
      expect(sheet.frames(SvMotion.dead, pingPong: false), [51, 52, 53]);
    });

    test('victory frames are in row 4, columns 3-5', () {
      expect(sheet.rectOf(39), const Rect.fromLTWH(216, 288, 72, 72));
      expect(sheet.rectOf(41), const Rect.fromLTWH(360, 288, 72, 72));
    });
  });

  group('RmmvAnimationSheet', () {
    test('uses 192 px cells, five per row', () {
      expect(
        Sprites.thunder.rectOf(7),
        const Rect.fromLTWH(384, 192, 192, 192),
      );
      expect(Sprites.revive.cellCount, 35);
      expect(Sprites.revive.imageSize, const Size(960, 1344));
    });

    test('frame lists stay inside their sheets', () {
      for (final f in Sprites.fireLoop) {
        expect(f, lessThan(Sprites.fire.cellCount));
      }
      for (final f in Sprites.thunderStrike) {
        expect(f, lessThan(Sprites.thunder.cellCount));
      }
      for (final f in Sprites.reviveSparkle) {
        expect(f, lessThan(Sprites.revive.cellCount));
      }
    });
  });
}
