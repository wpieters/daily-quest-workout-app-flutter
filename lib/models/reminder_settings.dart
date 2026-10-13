/// The three daily reminder slots. See docs/adr/0012.
enum ReminderSlot {
  morning('Morning', 'The Daily Quest is active'),
  afternoon('Afternoon', 'Only if the quest is still incomplete'),
  evening('Evening', 'Penalty warning if the quest is still incomplete');

  const ReminderSlot(this.label, this.description);
  final String label;
  final String description;
}

/// A local wall-clock time, kept free of Flutter's TimeOfDay so the model
/// stays pure Dart.
class ReminderTime {
  final int hour;
  final int minute;

  const ReminderTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// "HH:MM", the format the reminders API expects.
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static ReminderTime? parse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return ReminderTime(h, min);
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => hhmm;
}

/// What the user asked for. A null slot time means that slot is off.
class ReminderSettings {
  final bool enabled;
  final Map<ReminderSlot, ReminderTime?> times;

  const ReminderSettings({required this.enabled, required this.times});

  static const defaults = ReminderSettings(
    enabled: false,
    times: {
      ReminderSlot.morning: ReminderTime(7, 0),
      ReminderSlot.afternoon: ReminderTime(14, 0),
      ReminderSlot.evening: ReminderTime(20, 0),
    },
  );

  ReminderTime? operator [](ReminderSlot slot) => times[slot];

  bool get anySlotOn => times.values.any((t) => t != null);

  ReminderSettings copyWith({
    bool? enabled,
    Map<ReminderSlot, ReminderTime?>? times,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      times: times ?? this.times,
    );
  }

  ReminderSettings withSlot(ReminderSlot slot, ReminderTime? time) =>
      copyWith(times: {...times, slot: time});

  /// The `times` object the API takes: `{"morning": "07:00", ...}`.
  Map<String, String?> get apiTimes => {
    for (final slot in ReminderSlot.values) slot.name: times[slot]?.hhmm,
  };

  Map<String, dynamic> toJson() => {'enabled': enabled, 'times': apiTimes};

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['times'] as Map<String, dynamic>? ?? const {};
    return ReminderSettings(
      enabled: json['enabled'] == true,
      times: {
        for (final slot in ReminderSlot.values)
          slot: raw.containsKey(slot.name)
              ? ReminderTime.parse(raw[slot.name] as String?)
              : defaults.times[slot],
      },
    );
  }
}
