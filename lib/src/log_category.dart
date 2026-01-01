/// Categorization for log entries.
enum LogCategory {
  /// Network requests and responses.
  network,

  /// Database operations.
  database,

  /// UI events and errors.
  ui,

  /// General code errors and other logs.
  error,

  /// Logs that don't fit into other categories (default)
  other,
}
