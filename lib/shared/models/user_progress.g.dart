// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
  totalWorkouts: (json['totalWorkouts'] as num?)?.toInt() ?? 0,
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'totalWorkouts': instance.totalWorkouts,
      'history': instance.history,
    };
