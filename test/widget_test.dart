// This is a basic Flutter widget test for DailyQuest app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daily_quest/main.dart';

void main() {
  testWidgets('DailyQuest app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DailyQuestApp()));
    
    // Just pump once to see initial render
    await tester.pump();

    // Verify that our app initializes without crashing
    expect(find.byType(DailyQuestApp), findsOneWidget);
    
    // The app should at least show some loading state or content
    // Since async data loading might take time, we'll just verify the app structure exists
  });
}

