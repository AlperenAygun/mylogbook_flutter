import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mylogbook_flutter/mylogbook.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Logbook
  // Initialize the Logbook with default retention (Daily)
  await MyLogbook().init(retention: LogRetention.daily);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Logbook Example')),
        body: const LogbookExample(),
      ),
    );
  }
}

class LogbookExample extends StatefulWidget {
  const LogbookExample({super.key});

  @override
  State<LogbookExample> createState() => _LogbookExampleState();
}

class _LogbookExampleState extends State<LogbookExample> {
  final _logger = MyLogbook();
  List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    final logs = await _logger.getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
      });
    }
  }

  void _addLog(void Function() logAction) {
    logAction();
    _refreshLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _logs.isEmpty
              ? const Center(child: Text('No logs found'))
              : ListView.separated(
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    Color color = Colors.black;
                    if (log.level == LogLevel.warning) color = Colors.orange;
                    if (log.level == LogLevel.error) color = Colors.red;

                    return ListTile(
                      dense: true,
                      leading: Text(
                        log.level.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(log.message),
                      subtitle: Text(
                        '[${log.category.name.toUpperCase()}] '
                        '${log.timestamp.toIso8601String()}'
                        '${log.error != null ? '\nError: ${log.error}' : ''}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
        ),
        const Divider(thickness: 2),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Controls',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _addLog(() => _logger.info('Info message')),
                      child: const Text('Info'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _addLog(() => _logger.warning('Warning message')),
                      child: const Text('Warning'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _addLog(() => _logger.error('Error message')),
                      child: const Text('Error'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                      ),
                      onPressed: () {
                        try {
                          throw Exception('Sync Exception');
                        } catch (e) {
                          // In a real app global handler catches this,
                          // here we manually simulate just to show it works if caught
                          _logger.error('Caught Sync Exception', error: e);
                          _refreshLogs();
                        }
                      },
                      child: const Text('Log Exception'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                      ),
                      onPressed: () {
                        // Throwing an exception without try-catch to test global error handling
                        throw Exception('Uncaught UI Exception');
                      },
                      child: const Text('Throw UI Error'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                      ),
                      onPressed: () async {
                        final client = LogbookHttpClient();
                        try {
                          await client.get(
                            Uri.parse(
                              'https://jsonplaceholder.typicode.com/todos/1',
                            ),
                          );
                        } finally {
                          client.close();
                          _refreshLogs();
                        }
                      },
                      child: const Text('HTTP Request'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _refreshLogs,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear'),
                      onPressed: () async {
                        await _logger.clearLogs();
                        _refreshLogs();
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Logs'),
                      onPressed: () async {
                        await _logger.exportAndShareLogs();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Open Log Viewer'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LogbookLogView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
