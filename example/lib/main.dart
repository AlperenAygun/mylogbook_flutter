import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mylogbook_flutter/mylogbook_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Logbook
  // We enable archiving to show how logs can be moved to archive instead of deleted
  await MyLogbook().init(
    retention: LogRetention.daily, // Keep logs in main storage for 1 day
    enableArchiving: true, // Move older logs to archive
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const LogbookDemoPage(),
    );
  }
}

class LogbookDemoPage extends StatefulWidget {
  const LogbookDemoPage({super.key});

  @override
  State<LogbookDemoPage> createState() => _LogbookDemoPageState();
}

class _LogbookDemoPageState extends State<LogbookDemoPage> {
  final _logger = MyLogbook();
  String _lastActionStatus = 'Ready';

  void _setStatus(String status) {
    if (mounted) {
      setState(() => _lastActionStatus = status);
    }
  }

  Future<void> _simulateNetworkRequest() async {
    _setStatus('Simulating Network Request...');
    _logger.info('Starting data fetch...', category: LogCategory.network);

    await Future.delayed(const Duration(seconds: 1));

    if (Random().nextBool()) {
      _logger.info('Data fetched successfully', category: LogCategory.network);
      _setStatus('Network Request Success');
    } else {
      _logger.error(
        'Failed to fetch data',
        category: LogCategory.network,
        error: 'TimeoutException: 404 Not Found',
      );
      _setStatus('Network Request Failed');
    }
  }

  void _simulateDatabaseOp() {
    _setStatus('Simulating DB Operation...');
    _logger.warning(
      'Database needs optimization',
      category: LogCategory.database,
    );
    _setStatus('DB Warning Logged');
  }

  void _simulateUIError() {
    try {
      throw FormatException('Invalid number format');
    } catch (e, stack) {
      _logger.error(
        'UI Parsing Error',
        category: LogCategory.ui,
        error: e,
        stackTrace: stack,
      );
      _setStatus('UI Error Logged');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook Demo'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logger.openLogViewer(context),
        icon: const Icon(Icons.history),
        label: const Text('View Logs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Status Card
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Last Action Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastActionStatus,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Log Categories'),
          const SizedBox(height: 12),
          _buildActionGrid(),

          const SizedBox(height: 24),
          _buildSectionHeader('Management'),
          const SizedBox(height: 12),
          _buildManagementList(context),

          const SizedBox(height: 24),
          const Text(
            'Check the "View Logs" button to see the results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(
          Icons.label_important,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionButton(
          icon: Icons.wifi,
          label: 'Network Log',
          color: Colors.blue.shade100,
          onTap: _simulateNetworkRequest,
        ),
        _buildActionButton(
          icon: Icons.storage,
          label: 'Database Log',
          color: Colors.orange.shade100,
          onTap: _simulateDatabaseOp,
        ),
        _buildActionButton(
          icon: Icons.bug_report,
          label: 'UI Error',
          color: Colors.red.shade100,
          onTap: _simulateUIError,
        ),
        _buildActionButton(
          icon: Icons.info_outline,
          label: 'General Info',
          color: Colors.green.shade100,
          onTap: () {
            _logger.info(
              'User opened the settings page',
              category: LogCategory.ui,
            );
            _setStatus('Info Logged');
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementList(BuildContext context) {
    return Column(
      children: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.grey.shade100,
          leading: const Icon(Icons.share),
          title: const Text('Export & Share logs'),
          subtitle: const Text('Share all current logs as a .txt file'),
          onTap: () async {
            _setStatus('Exporting...');
            await _logger.exportAndShareLogs();
            _setStatus('Export dialog closed');
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.grey.shade100,
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Clear All Logs'),
          onTap: () async {
            await _logger.clearLogs();
            _setStatus('All logs cleared');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs Cleared')));
            }
          },
        ),
      ],
    );
  }
}
