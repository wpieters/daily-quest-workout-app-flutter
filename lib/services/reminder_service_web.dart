import 'dart:convert';
import 'dart:js_interop';

import '../models/reminder_settings.dart';
import 'reminder_service.dart';

// Bindings for web/push.js. Everything crosses as JSON strings.
@JS('dqPush.support')
external JSPromise<JSString> _support();

@JS('dqPush.enable')
external JSPromise<JSString> _enable(JSString apiUrl, JSString settings);

@JS('dqPush.sync')
external JSPromise<JSString> _sync(JSString apiUrl, JSString settings);

@JS('dqPush.disable')
external JSPromise<JSString> _disable(JSString apiUrl);

@JS('dqPush.complete')
external JSPromise<JSString> _complete(JSString apiUrl, JSString date);

@JS('dqPush')
external JSObject? get _dqPush;

ReminderService createReminderService(String apiUrl) {
  if (apiUrl.isEmpty || _dqPush == null) return const NoopReminderService();
  return WebReminderService(apiUrl);
}

class WebReminderService implements ReminderService {
  final String apiUrl;

  WebReminderService(this.apiUrl);

  @override
  bool get available => true;

  Future<ReminderStatus> _status(JSPromise<JSString> call) async {
    final json = jsonDecode((await call.toDart).toDart) as Map<String, dynamic>;
    return reminderStatusFrom(json['status'] as String? ?? 'unsupported');
  }

  JSString _settingsJson(ReminderSettings s) =>
      jsonEncode({'times': s.apiTimes}).toJS;

  @override
  Future<ReminderStatus> status() => _status(_support());

  @override
  Future<ReminderStatus> enable(ReminderSettings settings) =>
      _status(_enable(apiUrl.toJS, _settingsJson(settings)));

  @override
  Future<ReminderStatus> sync(ReminderSettings settings) =>
      _status(_sync(apiUrl.toJS, _settingsJson(settings)));

  @override
  Future<ReminderStatus> disable() => _status(_disable(apiUrl.toJS));

  @override
  Future<void> reportCompleted(DateTime date) async {
    final ymd = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    await _complete(apiUrl.toJS, ymd.toJS).toDart;
  }
}
