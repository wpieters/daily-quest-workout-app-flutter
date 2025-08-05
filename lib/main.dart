import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/workout_screen.dart';
import 'utils/theme.dart';
import 'services/daily_reset_service.dart';

void main() {
  runApp(const ProviderScope(child: DailyQuestApp()));
}

class AppInitializer extends ConsumerWidget {
  final Widget child;
  
  const AppInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the daily reset service
    ref.watch(dailyResetServiceProvider);
    return child;
  }
}

class DailyQuestApp extends StatelessWidget {
  const DailyQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyQuest',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(child: WorkoutScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}