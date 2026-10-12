import 'package:daily_quest/models/reminder_settings.dart';
import 'package:daily_quest/services/reminder_service.dart';

/// Records calls and answers with whatever [next] status is set.
class FakeReminderService implements ReminderService {
  @override
  bool available;

  /// Status reported by [status], and by [enable]/[sync] when [grantsOn].
  ReminderStatus current;

  /// Whether [enable] succeeds (true -> on) or is refused (false -> denied).
  bool grantsOn;

  /// When set, every call throws this, like a network failure would.
  Object? failure;

  final List<String> calls = [];
  final List<ReminderSettings> synced = [];
  final List<DateTime> completed = [];

  FakeReminderService({
    this.available = true,
    this.current = ReminderStatus.off,
    this.grantsOn = true,
  });

  void _record(String call) {
    calls.add(call);
    if (failure != null) throw failure!;
  }

  @override
  Future<ReminderStatus> status() async {
    _record('status');
    return current;
  }

  @override
  Future<ReminderStatus> enable(ReminderSettings settings) async {
    _record('enable');
    synced.add(settings);
    current = grantsOn ? ReminderStatus.on : ReminderStatus.denied;
    return current;
  }

  @override
  Future<ReminderStatus> sync(ReminderSettings settings) async {
    _record('sync');
    synced.add(settings);
    return current;
  }

  @override
  Future<ReminderStatus> disable() async {
    _record('disable');
    current = ReminderStatus.off;
    return current;
  }

  @override
  Future<void> reportCompleted(DateTime date) async {
    _record('complete');
    completed.add(date);
  }
}
