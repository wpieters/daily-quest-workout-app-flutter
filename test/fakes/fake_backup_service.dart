import 'package:daily_quest/services/backup_service.dart';

/// Records downloads and answers [pickFile] with [nextFile].
class FakeBackupService implements BackupService {
  @override
  bool available;

  final List<(String, String)> downloads = [];

  /// What the next pick returns; null means the user cancelled.
  String? nextFile;

  FakeBackupService({this.available = true});

  @override
  Future<void> download(String filename, String text) async {
    downloads.add((filename, text));
  }

  @override
  Future<String?> pickFile() async => nextFile;
}
