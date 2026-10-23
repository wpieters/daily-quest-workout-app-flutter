import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/backup.dart';

void main() {
  final data = <String, Map<String, dynamic>?>{
    'user_progress': {
      'schemaVersion': 2,
      'currentStreak': 3,
      'totalWorkouts': 7,
      'history': [],
    },
    'today_workout': {'date': '2026-10-23T07:00:00.000', 'pushups': 40},
    'reminder_settings': null,
  };
  final at = DateTime.utc(2026, 10, 23, 18, 4, 11);

  test('round-trips through encode and decode', () {
    final text = Backup(exportedAt: at, data: data).encode();
    final doc = jsonDecode(text) as Map<String, dynamic>;
    expect(doc['app'], 'dailyquest');
    expect(doc['format'], 1);
    expect(doc['exportedAt'], '2026-10-23T18:04:11.000Z');
    expect((doc['data'] as Map).keys, Backup.keys);

    final back = Backup.decode(text);
    expect(back.exportedAt, at);
    expect(back.data, data);
  });

  test('canonical JSON sorts keys at every level and strips whitespace', () {
    expect(
      Backup.canonicalJson({
        'b': [
          {'z': 1, 'a': 2},
        ],
        'a': 'x',
      }),
      '{"a":"x","b":[{"a":2,"z":1}]}',
    );
    // Same data, different key order: same checksum.
    expect(
      Backup.checksum({
        'user_progress': {'x': 1, 'y': 2},
      }),
      Backup.checksum({
        'user_progress': {'y': 2, 'x': 1},
      }),
    );
  });

  group('refuses', () {
    String tamper(Map<String, dynamic> Function(Map<String, dynamic>) f) {
      final doc = jsonDecode(
        Backup(exportedAt: at, data: data).encode(),
      ) as Map<String, dynamic>;
      return jsonEncode(f(doc));
    }

    void expectRefusal(String text, String reason) {
      expect(
        () => Backup.decode(text),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains(reason),
          ),
        ),
      );
    }

    test('non-JSON', () => expectRefusal('not json', 'not a JSON file'));
    test('wrong app', () {
      expectRefusal(tamper((d) => d..['app'] = 'other'), 'not a DailyQuest');
    });
    test('newer format', () {
      expectRefusal(tamper((d) => d..['format'] = 2), 'newer version');
    });
    test('missing checksum', () {
      expectRefusal(tamper((d) => d..remove('checksum')), 'no checksum');
    });
    test('edited data', () {
      expectRefusal(
        tamper((d) {
          (d['data'] as Map)['user_progress']['currentStreak'] = 999;
          return d;
        }),
        'corrupted',
      );
    });
    test('no progress', () {
      expectRefusal(
        tamper((d) {
          (d['data'] as Map)['user_progress'] = null;
          return d;
        }),
        'no progress',
      );
    });
  });

  test('filename carries the local date', () {
    expect(
      Backup.filenameFor(DateTime(2026, 10, 3, 23, 59)),
      'dailyquest-backup-2026-10-03.json',
    );
  });
}
