import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/progression/progression_engine.dart';
import 'package:daily_quest/progression/progression_state.dart';
import 'package:daily_quest/screens/character_screen.dart';
import 'package:daily_quest/screens/workout_screen.dart';
import 'package:daily_quest/widgets/level_header.dart';
import 'package:daily_quest/widgets/level_up_overlay.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Stack(children: [child])));

void main() {
  final engine = ProgressionEngine();

  testWidgets('LevelHeader shows level, title and XP into level',
      (tester) async {
    final p = ProgressionState.initial()
        .copyWith(totalXp: engine.leveling.levelFloor(10) + 50);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LevelHeader(progression: p, engine: engine)),
    ));

    expect(find.text('LV. 10'), findsOneWidget);
    expect(find.text('Fledgling Warrior'), findsOneWidget);
    expect(find.text('50 / ${engine.leveling.xpToNextLevel(10)} XP'),
        findsOneWidget);
  });

  testWidgets('LevelUpOverlay shows gains and a newly acquired title',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(_wrap(LevelUpOverlay(
      change: const LevelChange(
        fromLevel: 9,
        toLevel: 10,
        strengthDelta: 2,
        skillPointsGained: 3,
        fatigueMaxGained: 1,
      ),
      onDismiss: () => dismissed = true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL UP!'), findsOneWidget);
    expect(find.text('Lv 9  →  Lv 10'), findsOneWidget);
    expect(find.text('STR  +2'), findsOneWidget);
    expect(find.text('Skill points  +3'), findsOneWidget);
    expect(find.text('Max fatigue  +1'), findsOneWidget);
    expect(find.text('[Fledgling Warrior]'), findsOneWidget);

    await tester.tap(find.text('LEVEL UP!'));
    expect(dismissed, isTrue);
  });

  testWidgets('LevelUpOverlay omits the title section when unchanged',
      (tester) async {
    await tester.pumpWidget(_wrap(LevelUpOverlay(
      change: const LevelChange(fromLevel: 11, toLevel: 12),
      onDismiss: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('TITLE ACQUIRED'), findsNothing);
  });

  testWidgets('Main screen and character sheet render progression',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Wide enough that the test font (every glyph a full square) fits.
    tester.view.physicalSize = const Size(2400, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: WorkoutScreen())));
    await tester.pumpAndSettle();

    expect(find.text('LV. 1'), findsOneWidget);
    expect(find.text("World's Weakest"), findsOneWidget);

    await tester.tap(find.byType(LevelHeader));
    await tester.pumpAndSettle();

    expect(find.byType(CharacterScreen), findsOneWidget);
    expect(find.text('STRENGTH'), findsOneWidget);
    expect(find.text('100 / 100'), findsOneWidget); // HP
    expect(find.text('7 / 7'), findsOneWidget); // fatigue
  });
}
