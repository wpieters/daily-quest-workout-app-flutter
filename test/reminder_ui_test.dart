import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_quest/providers/reminder_provider.dart';
import 'package:daily_quest/screens/settings_screen.dart';
import 'package:daily_quest/services/daily_reset_service.dart';
import 'package:daily_quest/services/reminder_service.dart';

import 'fakes/fake_reminder_service.dart';

void main() {
  late FakeReminderService fake;

  final reminderSwitch = find.widgetWithText(SwitchListTile, 'Daily reminders');

  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    // Tall viewport: the Reminders section sits below the fold at 600px.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [reminderServiceProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    return ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)));
  }

  /// The settings page starts the midnight timer; cancel it before the tree
  /// is torn down or the test ends with a pending timer.
  void finish(ProviderContainer container) =>
      container.read(dailyResetServiceProvider).dispose();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = FakeReminderService();
  });

  testWidgets('hides the section when reminders are unavailable',
      (tester) async {
    fake.available = false;
    final container = await pumpSettings(tester);

    expect(find.text('Reminders'), findsNothing);
    expect(reminderSwitch, findsNothing);
    finish(container);
  });

  testWidgets('shows the switch and three slots; toggling enables',
      (tester) async {
    final container = await pumpSettings(tester);

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);

    await tester.tap(reminderSwitch);
    await tester.pump(const Duration(milliseconds: 100));

    expect(fake.calls, contains('enable'));
    expect(tester.widget<SwitchListTile>(reminderSwitch).value, isTrue);
    finish(container);
  });

  testWidgets('explains the home-screen requirement on iOS Safari',
      (tester) async {
    fake.current = ReminderStatus.needsInstall;
    final container = await pumpSettings(tester);

    expect(find.textContaining('Home Screen'), findsOneWidget);
    expect(reminderSwitch, findsNothing);
    finish(container);
  });

  testWidgets('unticking a slot switches it off', (tester) async {
    final container = await pumpSettings(tester);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Afternoon'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('14:00'), findsNothing);
    expect(find.text('off'), findsOneWidget);
    expect(container.read(reminderProvider).settings.apiTimes['afternoon'],
        isNull);
    finish(container);
  });
}
