import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/reminder_settings.dart';

void main() {
  group('ReminderTime', () {
    test('formats as HH:MM', () {
      expect(const ReminderTime(7, 5).hhmm, '07:05');
      expect(const ReminderTime(20, 30).hhmm, '20:30');
    });

    test('parses valid strings and rejects the rest', () {
      expect(ReminderTime.parse('14:00'), const ReminderTime(14, 0));
      expect(ReminderTime.parse('24:00'), isNull);
      expect(ReminderTime.parse('7:00'), isNull);
      expect(ReminderTime.parse(null), isNull);
    });
  });

  group('ReminderSettings', () {
    test('defaults are off with 07:00, 14:00 and 20:00', () {
      const d = ReminderSettings.defaults;
      expect(d.enabled, isFalse);
      expect(d.apiTimes, {
        'morning': '07:00',
        'afternoon': '14:00',
        'evening': '20:00',
      });
    });

    test('round-trips through JSON, including a slot that is off', () {
      final s = ReminderSettings.defaults
          .copyWith(enabled: true)
          .withSlot(ReminderSlot.afternoon, null)
          .withSlot(ReminderSlot.evening, const ReminderTime(21, 15));

      final back = ReminderSettings.fromJson(s.toJson());

      expect(back.enabled, isTrue);
      expect(back[ReminderSlot.morning], const ReminderTime(7, 0));
      expect(back[ReminderSlot.afternoon], isNull);
      expect(back[ReminderSlot.evening], const ReminderTime(21, 15));
    });

    test('missing slots fall back to defaults; invalid ones are off', () {
      final s = ReminderSettings.fromJson({
        'enabled': false,
        'times': {'morning': 'garbage'},
      });
      expect(s[ReminderSlot.morning], isNull);
      expect(s[ReminderSlot.afternoon], const ReminderTime(14, 0));
      expect(s[ReminderSlot.evening], const ReminderTime(20, 0));
    });

    test('anySlotOn is false only when every slot is off', () {
      var s = ReminderSettings.defaults;
      for (final slot in ReminderSlot.values) {
        s = s.withSlot(slot, null);
      }
      expect(s.anySlotOn, isFalse);
      expect(
        s.withSlot(ReminderSlot.morning, const ReminderTime(6, 0)).anySlotOn,
        isTrue,
      );
    });
  });
}
