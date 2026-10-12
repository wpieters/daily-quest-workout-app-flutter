import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_settings.dart';
import '../services/reminder_service.dart';
import '../services/storage_service.dart';

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderState>(ReminderNotifier.new);

class ReminderState {
  final ReminderSettings settings;
  final ReminderStatus status;
  final bool busy;
  final String? error;

  const ReminderState({
    required this.settings,
    required this.status,
    this.busy = false,
    this.error,
  });

  /// Reminders can't be offered at all: hide the settings.
  bool get hidden => status == ReminderStatus.unsupported;

  ReminderState copyWith({
    ReminderSettings? settings,
    ReminderStatus? status,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return ReminderState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReminderNotifier extends Notifier<ReminderState> {
  late ReminderService _service;
  late StorageService _storage;

  /// Completes once saved settings are loaded and the subscription refreshed.
  late Future<void> ready;

  @override
  ReminderState build() {
    _service = ref.read(reminderServiceProvider);
    _storage = ref.read(storageServiceProvider);
    ready = Future.microtask(_load);
    return ReminderState(
      settings: ReminderSettings.defaults,
      status: _service.available
          ? ReminderStatus.off
          : ReminderStatus.unsupported,
    );
  }

  Future<void> _load() async {
    var settings = await _storage.loadReminderSettings();
    if (!_service.available) {
      state = state.copyWith(settings: settings);
      return;
    }

    var status = await _service.status();
    if (settings.enabled && status == ReminderStatus.on) {
      // Refreshes the server's copy (and its TTL) with the current times
      // and timezone on every launch.
      status = await _guard(() => _service.sync(settings)) ?? status;
    } else if (settings.enabled) {
      // The browser dropped the subscription (or permission); reflect it.
      settings = settings.copyWith(enabled: false);
      await _storage.saveReminderSettings(settings);
    }
    state = state.copyWith(settings: settings, status: status);
  }

  /// Must be called from a tap: the browser only prompts for permission in
  /// response to a user gesture.
  Future<void> enable() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    final status = await _guard(() => _service.enable(state.settings));
    final on = status == ReminderStatus.on;
    final settings = state.settings.copyWith(enabled: on);
    if (on) await _storage.saveReminderSettings(settings);
    state = state.copyWith(
      settings: settings,
      status: status ?? state.status,
      busy: false,
      error: status == ReminderStatus.denied
          ? 'Notifications are blocked for this site.'
          : null,
    );
  }

  Future<void> disable() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    final status = await _guard(_service.disable);
    final settings = state.settings.copyWith(enabled: false);
    await _storage.saveReminderSettings(settings);
    state = state.copyWith(
      settings: settings,
      status: status ?? ReminderStatus.off,
      busy: false,
    );
  }

  Future<void> setEnabled(bool on) => on ? enable() : disable();

  /// Sets or clears (null) one slot's time, and pushes it to the server when
  /// reminders are on.
  Future<void> setSlot(ReminderSlot slot, ReminderTime? time) async {
    final settings = state.settings.withSlot(slot, time);
    state = state.copyWith(settings: settings, clearError: true);
    await _storage.saveReminderSettings(settings);
    if (settings.enabled) {
      final status = await _guard(() => _service.sync(settings));
      if (status != null) state = state.copyWith(status: status);
    }
  }

  /// Runs a service call, turning failures into [ReminderState.error]
  /// rather than exceptions, since reminders must never break the app.
  Future<ReminderStatus?> _guard(Future<ReminderStatus> Function() op) async {
    try {
      return await op();
    } catch (e) {
      state = state.copyWith(error: 'Reminder service unavailable: $e');
      return null;
    }
  }
}
