import 'dart:ui';

/// A grid of equally sized cells in one image asset. Pure Dart so the frame
/// maths can be unit-tested without an image.
class SpriteSheet {
  final String asset;
  final int cellWidth;
  final int cellHeight;
  final int columns;
  final int rows;

  const SpriteSheet({
    required this.asset,
    required this.cellWidth,
    required this.cellHeight,
    required this.columns,
    required this.rows,
  });

  int get cellCount => columns * rows;
  Size get cellSize => Size(cellWidth.toDouble(), cellHeight.toDouble());
  Size get imageSize =>
      Size((columns * cellWidth).toDouble(), (rows * cellHeight).toDouble());

  /// Source rectangle of [cell], counted row-major from the top left.
  Rect rectOf(int cell) {
    assert(cell >= 0 && cell < cellCount, 'cell $cell outside sheet $asset');
    final c = cell % columns;
    final r = cell ~/ columns;
    return Rect.fromLTWH(
      (c * cellWidth).toDouble(),
      (r * cellHeight).toDouble(),
      cellWidth.toDouble(),
      cellHeight.toDouble(),
    );
  }
}

/// The 18 motions of an RPG Maker MV side-view actor, in sheet order.
enum SvMotion {
  walk,
  wait,
  chant,
  guard,
  damage,
  evade,
  thrust,
  swing,
  missile,
  skill,
  spell,
  item,
  escape,
  victory,
  dying,
  abnormal,
  sleep,
  dead,
}

/// RPG Maker MV side-view actor sheet: 9 columns × 6 rows, three motions per
/// row, three frames per motion.
class SvActorSheet extends SpriteSheet {
  const SvActorSheet(String asset, {int cell = 72})
    : super(
        asset: asset,
        cellWidth: cell,
        cellHeight: cell,
        columns: 9,
        rows: 6,
      );

  /// Cells of [motion]. RPG Maker plays looping motions as 0-1-2-1, which
  /// is what [pingPong] gives.
  List<int> frames(SvMotion motion, {bool pingPong = true}) {
    final row = motion.index ~/ 3;
    final first = row * columns + (motion.index % 3) * 3;
    return pingPong
        ? [first, first + 1, first + 2, first + 1]
        : [first, first + 1, first + 2];
  }
}

/// RPG Maker MV animation sheet: 192 px cells, five per row.
class RmmvAnimationSheet extends SpriteSheet {
  const RmmvAnimationSheet(String asset, {required super.rows})
    : super(asset: asset, cellWidth: 192, cellHeight: 192, columns: 5);
}

/// The sheets bundled with the app. See `assets/sprites/LICENSE.md`.
class Sprites {
  Sprites._();

  static const fighter = SvActorSheet(
    'assets/sprites/20240926bundleFighter3f.png',
  );

  static const fire = RmmvAnimationSheet(
    'assets/sprites/20221110bundleFireFX-Sheet.png',
    rows: 3,
  );

  /// The flame body, played back and forth so it burns steadily.
  static const fireLoop = [6, 7, 8, 9, 8, 7];

  static const thunder = RmmvAnimationSheet(
    'assets/sprites/20221110bundleThunderFX-Sheet.png',
    rows: 3,
  );

  /// One strike, top to bottom. Blank cells are the artist's flicker.
  static const thunderStrike = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  static const revive = RmmvAnimationSheet(
    'assets/sprites/20221110bundleReviveFX-Sheet.png',
    rows: 7,
  );

  /// Rows 0–3: drifting sparkles. Rows 4–6 are a burst we don't use.
  static const reviveSparkle = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, //
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  ];

  static const all = [fighter, fire, thunder, revive];
}
