import 'package:flutter_test/flutter_test.dart';
import 'package:logbook/logbook.dart';

void main() {
  group('LogEntry', () {
    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2023, 1, 1);
      final entry = LogEntry(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'Test message',
        error: 'Test error',
      );

      final json = entry.toJson();

      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['level'], 'info');
      expect(json['category'], 'other');
      expect(json['message'], 'Test message');
      expect(json['error'], 'Test error');
    });

    test('should format toString correctly', () {
      final entry = LogEntry(
        timestamp: DateTime(2023, 1, 1),
        level: LogLevel.error,
        message: 'Critical failure',
      );

      expect(entry.toString(), contains('[ERROR] [OTHER] Critical failure'));
    });
  });

  group('Logbook', () {
    test('should be a singleton', () {
      final logbook1 = Logbook();
      final logbook2 = Logbook();
      expect(logbook1, same(logbook2));
    });

    test('should emit logs to stream', () async {
      final logbook = Logbook();

      expectLater(
        logbook.logStream.map((e) => e.message),
        emitsThrough('Stream test message'),
      );

      logbook.info('Stream test message');
    });
  });
}
