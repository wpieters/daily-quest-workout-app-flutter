import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';

final dailyResetServiceProvider = Provider<DailyResetService>((ref) {
  return DailyResetService(ref);
});

class DailyResetService {
  final Ref _ref;
  Timer? _resetTimer;

  DailyResetService(this._ref) {
    _scheduleNextReset();
  }

  void _scheduleNextReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    _resetTimer?.cancel();
    _resetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      _scheduleNextReset(); // Schedule the next reset
    });
  }

  void _performDailyReset() {
    final workoutNotifier = _ref.read(workoutProvider.notifier);
    workoutNotifier.resetDay();
  }

  void dispose() {
    _resetTimer?.cancel();
  }

  // Manual reset for testing purposes
  void forceReset() {
    _performDailyReset();
  }

  Duration get timeUntilReset {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }
}