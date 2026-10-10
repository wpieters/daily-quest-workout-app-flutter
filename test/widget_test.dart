import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/exercise_type.dart';
import 'package:daily_quest/widgets/exercise_button.dart';

Widget _runningButton({required bool isEnabled, required VoidCallback onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 260,
        child: ExerciseButton(
          exercise: ExerciseType.running,
          count: 0,
          target: 100,
          progress: 0,
          stage: 0,
          isRunning: true,
          isEnabled: isEnabled,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  group('Running button', () {
    testWidgets('is non-interactive when running is disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_runningButton(isEnabled: false, onTap: () => taps++));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(taps, 0);
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('is greyed out when running is disabled', (tester) async {
      await tester.pumpWidget(_runningButton(isEnabled: false, onTap: () {}));

      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          )
          .first);
      final gradient = (container.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors, [Colors.grey.shade400, Colors.grey.shade600]);
    });

    testWidgets('responds to taps when running is enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_runningButton(isEnabled: true, onTap: () => taps++));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
