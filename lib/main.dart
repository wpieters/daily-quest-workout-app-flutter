import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_quest/core/constants/app_theme.dart';
import 'package:daily_quest/features/workout/presentation/screens/workout_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DailyQuestApp(),
    ),
  );
}

class DailyQuestApp extends StatelessWidget {
  const DailyQuestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyQuest',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Use system theme preference
      home: const WorkoutScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
