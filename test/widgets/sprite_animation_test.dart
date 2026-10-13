import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/sprites/sprite_sheet.dart';
import 'package:daily_quest/widgets/sprite_animation.dart';

import '../fakes/fake_sprites.dart';

SpritePainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is SpritePainter,
    ),
  );
  return paint.painter as SpritePainter;
}

void main() {
  setUp(useFakeSpriteImages);
  tearDown(() => SpriteImages.loader = null);

  testWidgets('advances frames at the given fps and loops', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SpriteAnimation(
            sheet: Sprites.fighter,
            frames: Sprites.fighter.frames(SvMotion.victory),
            fps: 10,
            scale: 2,
          ),
        ),
      ),
    );
    await tester.pump(); // image future resolves
    expect(_painter(tester).frame, 0);
    expect(_painter(tester).source, Sprites.fighter.rectOf(39));
    expect(tester.getSize(find.byType(CustomPaint)), const Size(144, 144));

    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).frame, 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).frame, 2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).frame, 3);
    expect(_painter(tester).source, Sprites.fighter.rectOf(40));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_painter(tester).frame, 0, reason: 'loops');
  });

  testWidgets(
    'non-looping animation plays through, reports, then paints nothing',
    (tester) async {
      var done = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SpriteAnimation(
            sheet: Sprites.thunder,
            frames: const [0, 1, 2],
            fps: 10,
            loop: false,
            onDone: () => done++,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(_painter(tester).frame, 2);
      expect(done, 0, reason: 'last frame still showing');
      await tester.pump(const Duration(milliseconds: 100));
      expect(done, 1);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SpritePainter,
        ),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(done, 1);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('animate: false shows the still frame with no ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SpriteAnimation(
          sheet: Sprites.fighter,
          frames: Sprites.fighter.frames(SvMotion.victory),
          animate: false,
          stillFrame: 2,
        ),
      ),
    );
    await tester.pump();
    expect(_painter(tester).frame, 2);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(_painter(tester).frame, 2);
  });

  test('hueRotate(0) is the identity', () {
    expect(
      hueRotate(0),
      const ColorFilter.matrix([
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]),
    );
  });
}
