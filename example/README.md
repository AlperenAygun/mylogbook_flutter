# MyLogbook Example

A complete demonstration of the `mylogbook_flutter` package capabilities.

## Features Showcased
- **Log Categories**: Creating logs for Network, Database, UI, and General categories.
- **Log Levels**: Handling Info, Warning, and Error logs.
- **Error Simulation**: Examples of catching and logging specific exceptions (e.g., Network timeouts, Parsing errors) with stack traces.
- **Log Viewer**: Using the built-in UI to inspect, filter, and search logs.
- **Log Management**: Exporting logs to a file and clearing logs.
- **Archiving**: Configuration for automatic archiving of old logs (enabled in `main.dart`).

## Getting Started

1. **Navigate to the example directory**:
   ```bash
   cd example
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on your device**:
   ```bash
   flutter run
   ```

   *Note: The Android application ID is set to `com.mylogbook.example` for easy identification and testing.*

## Code Highlights

### Initialization
In `main.dart`, the logbook is initialized with specific retention settings:
```dart
await MyLogbook().init(
  retention: LogRetention.daily, // Keep logs for 1 day in active storage
  archiveLogs: true, // Move older logs to archive instead of deleting
);
```

### Categorized Logging
Logging with specific categories helps in filtering and debugging:
```dart
_logger.info(
  'Starting data fetch...',
  category: LogCategory.network,
);

_logger.error(
  'Failed to fetch data',
  category: LogCategory.network,
  error: 'TimeoutException: 404 Not Found',
);
```

### Viewing Logs
The package provides a built-in viewer that can be opened from any context:
```dart
_logger.openLogViewer(context);
```
