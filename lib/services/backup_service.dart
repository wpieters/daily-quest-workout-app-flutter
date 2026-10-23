import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_service_stub.dart'
    if (dart.library.js_interop) 'backup_service_web.dart'
    as platform;

/// Moves backup files in and out of the browser (handoff 0005). Pure Dart
/// code never touches JS directly, so tests can swap this out.
abstract class BackupService {
  /// False where files can't be offered or picked; the section is hidden.
  bool get available;

  /// Offers [text] as a download named [filename].
  Future<void> download(String filename, String text);

  /// Lets the user choose a file; null when they cancel.
  Future<String?> pickFile();
}

class NoopBackupService implements BackupService {
  const NoopBackupService();

  @override
  bool get available => false;

  @override
  Future<void> download(String filename, String text) async {}

  @override
  Future<String?> pickFile() async => null;
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return platform.createBackupService();
});
