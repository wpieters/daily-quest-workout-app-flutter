import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_settings.dart';
import 'reminder_service_stub.dart'
    if (dart.library.js_interop) 'reminder_service_web.dart'
    as platform;

/// Base URL of the reminders API, baked in at build time:
/// `--dart-define=REMINDERS_API_URL=https://...`. Empty means no backend,
/// and the reminder settings stay hidden.
const remindersApiUrl = String.fromEnvironment('REMINDERS_API_URL');

/// What the browser can do about reminders right now.
enum ReminderStatus {
  /// No backend configured, or no push support in this browser.
  unsupported,

  /// iOS Safari outside the home-screen app: push only works once installed.
  needsInstall,

  /// Permission was refused; the browser won't ask again.
  denied,
  off,
  on,
}

ReminderStatus reminderStatusFrom(String name) =>
    ReminderStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ReminderStatus.unsupported,
    );

/// Talks to the push machinery (service worker, permission, reminders API).
/// Pure Dart code never touches JS directly, so tests can swap this out.
abstract class ReminderService {
  /// False when reminders can't work at all (no backend, not web).
  bool get available;

  Future<ReminderStatus> status();

  /// Asks permission, subscribes and registers [settings]. Must be called
  /// from a user tap, or the permission prompt is suppressed.
  Future<ReminderStatus> enable(ReminderSettings settings);

  /// Re-registers the current subscription with [settings]. No-op when not
  /// subscribed.
  Future<ReminderStatus> sync(ReminderSettings settings);

  Future<ReminderStatus> disable();

  /// Tells the backend that [date]'s quest is complete so the remaining
  /// reminders for that day are skipped.
  Future<void> reportCompleted(DateTime date);
}

/// Used off the web, or when no API URL was configured.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  bool get available => false;

  @override
  Future<ReminderStatus> status() async => ReminderStatus.unsupported;

  @override
  Future<ReminderStatus> enable(ReminderSettings settings) async =>
      ReminderStatus.unsupported;

  @override
  Future<ReminderStatus> sync(ReminderSettings settings) async =>
      ReminderStatus.unsupported;

  @override
  Future<ReminderStatus> disable() async => ReminderStatus.unsupported;

  @override
  Future<void> reportCompleted(DateTime date) async {}
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return platform.createReminderService(remindersApiUrl);
});
