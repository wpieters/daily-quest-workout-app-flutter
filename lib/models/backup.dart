import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The backup file format (ADR 0014): every stored key verbatim, plus a
/// checksum so a corrupted file is refused rather than half-imported.
class Backup {
  static const app = 'dailyquest';
  static const format = 1;

  /// Storage keys the file carries, in order.
  static const keys = ['user_progress', 'today_workout', 'reminder_settings'];

  final DateTime exportedAt;

  /// Stored JSON per key; null when that key wasn't set.
  final Map<String, Map<String, dynamic>?> data;

  const Backup({required this.exportedAt, required this.data});

  String encode() {
    final doc = {
      'app': app,
      'format': format,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'data': {for (final k in keys) k: data[k]},
      'checksum': checksum(data),
    };
    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  /// Parses [text]; throws [BackupException] with the reason on refusal.
  static Backup decode(String text) {
    Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const BackupException('This is not a JSON file.');
    }
    if (raw is! Map<String, dynamic>) {
      throw const BackupException('This is not a DailyQuest backup.');
    }
    if (raw['app'] != app) {
      throw const BackupException('This is not a DailyQuest backup.');
    }
    final fileFormat = raw['format'];
    if (fileFormat is! int) {
      throw const BackupException('The backup has no format version.');
    }
    if (fileFormat > format) {
      throw BackupException(
        'This backup is from a newer version of DailyQuest '
        '(format $fileFormat). Update the app first.',
      );
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupException('The backup has no data section.');
    }
    final typed = <String, Map<String, dynamic>?>{};
    for (final k in keys) {
      final v = data[k];
      if (v != null && v is! Map<String, dynamic>) {
        throw BackupException('The backup\'s $k entry is malformed.');
      }
      typed[k] = v as Map<String, dynamic>?;
    }
    if (typed['user_progress'] == null) {
      throw const BackupException('The backup has no progress in it.');
    }
    final sum = raw['checksum'];
    if (sum is! String) {
      throw const BackupException('The backup has no checksum.');
    }
    if (sum != checksum(typed)) {
      throw const BackupException(
        'The backup is corrupted: its checksum does not match.',
      );
    }
    final exportedAt = DateTime.tryParse(raw['exportedAt'] as String? ?? '');
    if (exportedAt == null) {
      throw const BackupException('The backup has no export date.');
    }
    return Backup(exportedAt: exportedAt, data: typed);
  }

  /// SHA-256 of the canonical JSON of [data].
  static String checksum(Map<String, Map<String, dynamic>?> data) =>
      sha256.convert(utf8.encode(canonicalJson(data))).toString();

  /// JSON with keys sorted at every level and no whitespace, so the same
  /// data always hashes the same regardless of how it was serialised.
  static String canonicalJson(Object? value) => jsonEncode(_canonical(value));

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canonical(value[k])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }

  static String filenameFor(DateTime date) {
    final d = date.toLocal();
    return 'dailyquest-backup-'
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}.json';
  }
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}
