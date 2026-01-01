// This test file requires 'sqflite_common_ffi' to be added to dev_dependencies.
// Add it via: flutter pub add --dev sqflite_common_ffi

import 'package:flutter_test/flutter_test.dart';
import 'package:logbook/logbook.dart';
import 'package:logbook/src/database_helper.dart';

void main() {
  group('Archiving Feature', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      // Reset database
      final db = await dbHelper.database;
      await db.delete('logs');
      // Delete any archive tables if possible?
      // In a real test env we might use an in-memory db or clean up files.
    });

    test('archiveLogsOlderThan moves logs to archive table', () async {
      // 1. Insert logs
      final oldTimestamp = DateTime.now().subtract(const Duration(days: 2));
      final newTimestamp = DateTime.now();

      await dbHelper.insertLog(
        LogEntry(
          timestamp: oldTimestamp,
          level: LogLevel.info,
          message: 'Old Log',
        ),
      );

      await dbHelper.insertLog(
        LogEntry(
          timestamp: newTimestamp,
          level: LogLevel.info,
          message: 'New Log',
        ),
      );

      // 2. Archive
      final archiveTableName = 'logs_archived_test';
      final cutoff = DateTime.now().subtract(const Duration(days: 1));

      final movedCount = await dbHelper.archiveLogsOlderThan(
        cutoff,
        archiveTableName,
      );

      expect(movedCount, 1);

      // 3. Verify original table
      final logs = await dbHelper.getLogs();
      expect(logs.length, 1);
      expect(logs.first.message, 'New Log');

      // 4. Verify archive table
      final db = await dbHelper.database;
      final archivedLogs = await db.query(archiveTableName);
      expect(archivedLogs.length, 1);
      expect(archivedLogs.first['message'], 'Old Log');
    });
  });
}
