import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/widgets/exercise_button.dart';

Widget _runningButton({
  required bool isEnabled,
  required VoidCallback onTap,
  VoidCallback? onDecrement,
  int count = 0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 260,
        child: ExerciseButton(
          exercise: ExerciseType.running,
          count: count,
          target: 100,
          progress: count / 100,
          stage: 0,
          isRunning: true,
          isEnabled: isEnabled,
          onTap: onTap,
          onDecrement: onDecrement,
        ),
      ),
    ),
  );
}

void main() {
  group('Running button', () {
    testWidgets('is non-interactive when running is disabled', (tester) async {
      var taps = 0;
      await tester
          .pumpWidget(_runningButton(isEnabled: false, onTap: () => taps++));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(taps, 0);
      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(inkWell.onTap, isNull);
    });

    testWidgets('is greyed out when running is disabled', (tester) async {
      await tester.pumpWidget(_runningButton(isEnabled: false, onTap: () {}));

      final opacity = tester.widget<Opacity>(find
          .ancestor(
            of: find.byType(InkWell).first,
            matching: find.byType(Opacity),
          )
          .first);
      expect(opacity.opacity, 0.4);
      expect(find.text('DISABLED'), findsOneWidget);
    });

    testWidgets('minus is disabled when running is disabled', (tester) async {
      var decrements = 0;
      await tester.pumpWidget(_runningButton(
          isEnabled: false,
          count: 5,
          onTap: () {},
          onDecrement: () => decrements++));

      await tester.tap(find.byIcon(Icons.remove));
      expect(decrements, 0);
    });

    testWidgets('responds to taps when running is enabled', (tester) async {
      var taps = 0;
      await tester
          .pumpWidget(_runningButton(isEnabled: true, onTap: () => taps++));

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('Minus button', () {
    testWidgets('removes one without adding one', (tester) async {
      var taps = 0, decrements = 0;
      await tester.pumpWidget(_runningButton(
          isEnabled: true,
          count: 5,
          onTap: () => taps++,
          onDecrement: () => decrements++));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(decrements, 1);
      expect(taps, 0);
    });

    testWidgets('is disabled at zero', (tester) async {
      var decrements = 0;
      await tester.pumpWidget(_runningButton(
          isEnabled: true, onTap: () {}, onDecrement: () => decrements++));

      await tester.tap(find.byIcon(Icons.remove));
      expect(decrements, 0);
    });
  });
}
