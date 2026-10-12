import 'reminder_service.dart';

/// Non-web platforms have no push backend yet (ADR 0012 covers the PWA).
ReminderService createReminderService(String apiUrl) =>
    const NoopReminderService();
