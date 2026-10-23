import 'dart:js_interop';

import 'backup_service.dart';

// Bindings for web/backup.js.
@JS('dqBackup.download')
external void _download(JSString filename, JSString text);

@JS('dqBackup.pickFile')
external JSPromise<JSString?> _pickFile();

@JS('dqBackup')
external JSObject? get _dqBackup;

BackupService createBackupService() =>
    _dqBackup == null ? const NoopBackupService() : const WebBackupService();

class WebBackupService implements BackupService {
  const WebBackupService();

  @override
  bool get available => true;

  @override
  Future<void> download(String filename, String text) async =>
      _download(filename.toJS, text.toJS);

  @override
  Future<String?> pickFile() async => (await _pickFile().toDart)?.toDart;
}
