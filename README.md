# MyLogbook Flutter (Still under development)

A comprehensive logging package for Flutter applications, powered by SQLite.

## Features

- 📝 **Structured Logging**: Log messages with levels (Info, Warning, Error), categories, and timestamps.
- 💾 **SQLite Storage**: Logs are persisted in a local SQLite database.
- 🧹 **Retention Policies**: Automatically clean up old logs based on daily, weekly, or monthly retention.
- 📦 **Archiving**: Option to archive old logs to a separate table instead of deleting them.
- 📤 **Export & Share**: Compress the database into a `.zip` file and share it native capabilities.
- 📱 **Built-in UI**: A ready-to-use Log Viewer screen with filtering capabilities.

## Getting Started

Add `mylogbook_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  mylogbook_flutter: ^0.0.2
```

## Usage

### Initialization

Initialize the `Logbook` in your `main()` function before running the app.

```dart
import 'package:mylogbook_flutter/mylogbook.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with optional retention policy (default is daily)
  // set enableArchiving: true to archive logs instead of deleting them
  await MyLogbook().init(
    retention: LogRetention.daily, 
    enableArchiving: false, 
  );
  
  runApp(const MyApp());
}
```

### Logging

Use the singleton instance to log messages.

```dart
final logger = MyLogbook();

// Info log
logger.info('User logged in');

// Warning log with category
logger.warning(
  'Weak logs password', 
  category: LogCategory.network,
);

// Error log with exception and stack trace
try {
  throw Exception('Something went wrong');
} catch (e, stack) {
  logger.error(
    'Failed to load data',
    category: LogCategory.error,
    error: e,
    stackTrace: stack,
  );
}
```

### Log Categories

Organize your logs using `LogCategory`:
- `LogCategory.other` (default)
- `LogCategory.network`
- `LogCategory.database`
- `LogCategory.ui`
- `LogCategory.error`

### HTTP Logging

You can easily log HTTP requests and responses using `LogbookHttpClient`.

```dart
import 'package:http/http.dart' as http;
import 'package:mylogbook_flutter/mylogbook.dart';

final client = LogbookHttpClient(inner: http.Client());

try {
  // Requests are automatically logged
  final response = await client.get(Uri.parse('https://api.example.com/data'));
  
  // 4xx and 5xx responses are logged as info/warning by default in the current implementation,
  // but exceptions during request are logged as errors.
} catch (e) {
  // Network errors are logged automatically by LogbookHttpClient
}
```

### Built-in Log Viewer

Logbook comes with a built-in UI to view and filter logs.

```dart
import 'package:mylogbook_flutter/mylogbook.dart';

// Navigate to the Log Viewer
MyLogbook().openLogViewer(context);
```

The Log Viewer supports filtering by:
- Date Range
- Log Level
- Category
- Search Query

### Export & Share

You can export the entire database as a zip file and share it (e.g., via Email, Slack, AirDrop).

```dart
await MyLogbook().exportAndShareLogs();
```
