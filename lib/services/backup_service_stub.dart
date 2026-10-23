import 'backup_service.dart';

/// Off the web there is no file picker wired up yet.
BackupService createBackupService() => const NoopBackupService();
