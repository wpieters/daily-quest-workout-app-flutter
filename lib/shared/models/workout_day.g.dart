// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutDay _$WorkoutDayFromJson(Map<String, dynamic> json) => WorkoutDay(
      date: DateTime.parse(json['date'] as String),
      pushups: (json['pushups'] as num?)?.toInt() ?? 0,
      situps: (json['situps'] as num?)?.toInt() ?? 0,
      squats: (json['squats'] as num?)?.toInt() ?? 0,
      running: (json['running'] as num?)?.toInt() ?? 0,
      runningEnabled: json['runningEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$WorkoutDayToJson(WorkoutDay instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'pushups': instance.pushups,
      'situps': instance.situps,
      'squats': instance.squats,
      'running': instance.running,
      'runningEnabled': instance.runningEnabled,
    };
