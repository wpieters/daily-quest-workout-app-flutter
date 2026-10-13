import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/sprites/sprite_sheet.dart';
import 'package:daily_quest/widgets/completion_animation.dart';
import 'package:daily_quest/widgets/power_up_aura.dart';
import 'package:daily_quest/widgets/sprite_animation.dart';

import '../fakes/fake_sprites.dart';

Widget _app(int tier, VoidCallback onComplete, {bool reduced = false}) {
  // Phone-sized surface, matching the MediaQuery below.
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.first.physicalSize = const Size(400, 800);
  binding.platformDispatcher.views.first.devicePixelRatio = 1;
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      disableAnimations: reduced,
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          CompletionAnimation(powerLevel: tier, onComplete: onComplete),
        ],
      ),
    ),
  );
}

Iterable<SpriteAnimation> _sprites(WidgetTester tester) =>
    tester.widgetList<SpriteAnimation>(find.byType(SpriteAnimation));

void main() {
  setUp(() {
    useFakeSpriteImages();
  });
  tearDown(() => SpriteImages.loader = null);

  testWidgets('shows the hero, text and aura, then completes', (tester) async {
    var completed = 0;
    await tester.pumpWidget(_app(1, () => completed++));
    await tester.pump();

    expect(_sprites(tester).map((s) => s.sheet), [Sprites.fighter]);
    expect(
      _sprites(tester).first.frames,
      Sprites.fighter.frames(SvMotion.victory),
    );
    expect(find.text('DAILY QUEST'), findsOneWidget);
    expect(find.text('POWER UP!'), findsOneWidget);
    final aura = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PowerUpAura,
      ),
    );
    expect((aura.painter as PowerUpAura).tier, 1);

    await tester.pump(const Duration(milliseconds: 800));
    expect(completed, 0);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(completed, 1);
  });

  testWidgets('layers effect sheets by tier', (tester) async {
    for (final (tier, sheets) in [
      (0, [Sprites.fighter]),
      (2, [Sprites.fire, Sprites.fighter]),
      (3, [Sprites.fighter, Sprites.thunder]),
      (4, [Sprites.revive, Sprites.fighter, Sprites.thunder]),
    ]) {
      await tester.pumpWidget(_app(tier, () {}));
      await tester.pump();
      expect(
        _sprites(tester).map((s) => s.sheet).toList(),
        sheets,
        reason: 'tier $tier',
      );
      // Let the overlay finish so the next pump starts clean.
      await tester.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('reduced motion: still hero, no strike, still completes', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_app(3, () => completed++, reduced: true));
    await tester.pump();
    final sprites = _sprites(tester).toList();
    expect(sprites.map((s) => s.sheet), [Sprites.fighter]);
    expect(sprites.single.animate, isFalse);
    expect(find.text('SUPER SAIYAN 2!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(completed, 1);
  });
}
