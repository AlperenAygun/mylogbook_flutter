import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'src/database_helper.dart';
import 'src/log_entry.dart';
import 'src/log_retention.dart';

export 'src/log_entry.dart';
export 'src/http_logs.dart';
export 'src/log_retention.dart';
export 'src/ui/logbook_log_view.dart';

/// A comprehensive logging package for Flutter applications.
class MyLogbook {
  static final MyLogbook _instance = MyLogbook._internal();

  factory MyLogbook() => _instance;

  MyLogbook._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final StreamController<LogEntry> _logStreamController =
      StreamController.broadcast();

  /// Stream of log entries.
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Initializes the Logbook package.
  ///
  /// This method sets up the error handling hooks and initializes the database.
  /// [retention] specifies how long logs should be kept. Defaults to [LogRetention.daily].
  /// [enableArchiving] if true, moves expired logs to an archive table instead of deleting them. Defaults to false.
  Future<void> init({
    LogRetention retention = LogRetention.daily,
    bool enableArchiving = false,
  }) async {
    try {
      // Initialize database
      await _databaseHelper.database;

      // Clean up old logs
      await _cleanupLogs(retention, enableArchiving);

      _setupErrorHooks();
      info(
        'MyLogbook initialized with SQLite. Retention: ${retention.name}, Archiving: $enableArchiving',
      );
    } catch (e, stack) {
      // Fallback logging if initialization fails
      // ignore: avoid_print
      print('Failed to initialize MyLogbook: $e\n$stack');
    }
  }

  Future<void> _cleanupLogs(
    LogRetention retention,
    bool enableArchiving,
  ) async {
    final now = DateTime.now();
    DateTime cutoff;

    switch (retention) {
      case LogRetention.daily:
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case LogRetention.weekly:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case LogRetention.monthly:
        cutoff = now.subtract(const Duration(days: 30));
        break;
    }

    try {
      int deletedCount;
      if (enableArchiving) {
        final day = now.day.toString().padLeft(2, '0');
        final month = now.month.toString().padLeft(2, '0');
        final year = now.year.toString();
        final tableName = 'logs_archived_$day$month$year';

        deletedCount = await _databaseHelper.archiveLogsOlderThan(
          cutoff,
          tableName,
        );
        if (deletedCount > 0) {
          // ignore: avoid_print
          print(
            'MyLogbook cleanup: archived $deletedCount logs older than $cutoff to $tableName',
          );
        }
      } else {
        deletedCount = await _databaseHelper.deleteLogsOlderThan(cutoff);
        if (deletedCount > 0) {
          // We probably don't want to log this to the stream/db to avoid noise or recursion if not careful,
          // but printing to console is fine for debug.
          // ignore: avoid_print
          print(
            'MyLogbook cleanup: deleted $deletedCount logs older than $cutoff',
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to cleanup logs: $e');
    }
  }

  void _setupErrorHooks() {
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _log(
        LogLevel.error,
        'Flutter Error: ${details.summary}',
        category: LogCategory.ui,
        error: details.exception,
        stackTrace: details.stack,
      );
      // Call the original handler if it exists and is not this function
      FlutterError.presentError(details);
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _log(
        LogLevel.error,
        'Async Error',
        category: LogCategory.error,
        error: error,
        stackTrace: stack,
      );
      return true; // Use true if the error is handled
    };
  }

  /// Logs a message with level [info].
  void info(String message, {LogCategory category = LogCategory.other}) {
    _log(LogLevel.info, message, category: category);
  }

  /// Logs a message with level [warning].
  void warning(
    String message, {
    LogCategory category = LogCategory.other,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a message with level [error].
  void error(
    String message, {
    LogCategory category = LogCategory.other,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    LogCategory category = LogCategory.other,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    // Add to stream
    _logStreamController.add(entry);

    // Print to console (formatted)
    // ignore: avoid_print
    print(entry.toString());

    // Write to database
    _writeToDatabase(entry);
  }

  Future<void> _writeToDatabase(LogEntry entry) async {
    try {
      await _databaseHelper.insertLog(entry);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to write to database: $e');
    }
  }

  /// Retrieves logs from the database.
  Future<List<LogEntry>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    LogCategory? category,
    String? searchQuery,
  }) async {
    return await _databaseHelper.getLogs(
      startDate: startDate,
      endDate: endDate,
      level: level,
      category: category,
      searchQuery: searchQuery,
    );
  }

  /// Clears all logs from the database.
  Future<void> clearLogs() async {
    await _databaseHelper.clearLogs();
  }

  /// Exports the database file as a zip archive and shares it.
  Future<void> exportAndShareLogs({String? text}) async {
    try {
      final zipPath = await _databaseHelper.createZipArchive();
      await Share.shareXFiles([XFile(zipPath)], text: text ?? 'Logbook Logs');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to export and share logs: $e');
      rethrow;
    }
  }
}
