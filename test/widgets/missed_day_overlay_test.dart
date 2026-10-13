import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/missed_day_penalty.dart';
import 'package:daily_quest/widgets/missed_day_overlay.dart';

Widget _app(MissedDayPenalty penalty, VoidCallback onDismiss) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [MissedDayOverlay(penalty: penalty, onDismiss: onDismiss)],
      ),
    ),
  );
}

void main() {
  testWidgets('protected miss: days, XP and protection left', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      _app(
        const MissedDayPenalty(
          days: 3,
          xpLost: 300,
          fromLevel: 10,
          toLevel: 10,
          protectionLeft: 4,
        ),
        () => dismissed++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('QUEST FAILED'), findsOneWidget);
    expect(find.text('3 days without a completed exercise'), findsOneWidget);
    expect(find.text('-300 XP'), findsOneWidget);
    expect(
      find.text('Level protected · 4 misses of protection left'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tap to continue'));
    expect(dismissed, 1);
  });

  testWidgets('one miss, singular wording', (tester) async {
    await tester.pumpWidget(
      _app(
        const MissedDayPenalty(
          days: 1,
          xpLost: 0,
          fromLevel: 3,
          toLevel: 3,
          protectionLeft: 1,
        ),
        () {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1 day without a completed exercise'), findsOneWidget);
    expect(find.text('-0 XP'), findsOneWidget);
    expect(
      find.text('Level protected · 1 miss of protection left'),
      findsOneWidget,
    );
  });

  testWidgets('lost level shows the level change', (tester) async {
    await tester.pumpWidget(
      _app(
        const MissedDayPenalty(
          days: 8,
          xpLost: 1200,
          fromLevel: 10,
          toLevel: 9,
          protectionLeft: 0,
        ),
        () {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Lv 10  →  Lv 9'), findsOneWidget);
    expect(find.textContaining('protect'), findsNothing);
  });
}
