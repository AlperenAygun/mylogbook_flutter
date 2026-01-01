import 'log_category.dart';

export 'log_category.dart';

/// Variable log levels for the application.
enum LogLevel { info, warning, error }

/// A data class that represents a single log entry.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    this.category = LogCategory.other,
    required this.message,
    this.error,
    this.stackTrace,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      level: LogLevel.values.firstWhere(
        (l) => l.toString().split('.').last == map['level'],
        orElse: () => LogLevel.info,
      ),
      category: LogCategory.values.firstWhere(
        (c) => c.toString().split('.').last == map['category'],
        orElse: () => LogCategory.other,
      ),
      message: map['message'] as String,
      error: map['error'],
      stackTrace: map['stack_trace'] != null
          ? StackTrace.fromString(map['stack_trace'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
      'category': category.toString().split('.').last,
      'message': message,
      'error': error?.toString(),
      'stack_trace': stackTrace?.toString(),
    };
  }

  @override
  String toString() {
    return '[$timestamp] [${level.toString().split('.').last.toUpperCase()}] [${category.toString().split('.').last.toUpperCase()}] $message'
        '${error != null ? '\nError: $error' : ''}'
        '${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}';
  }
}
