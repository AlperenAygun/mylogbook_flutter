import 'package:flutter/material.dart';
import '../../mylogbook.dart';
import 'log_filter_sheet.dart';

class LogbookLogView extends StatefulWidget {
  const LogbookLogView({super.key});

  @override
  State<LogbookLogView> createState() => _LogbookLogViewState();
}

class _LogbookLogViewState extends State<LogbookLogView> {
  final _logbook = MyLogbook();
  List<LogEntry> _logs = [];
  bool _isLoading = true;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  LogLevel? _level;
  LogCategory? _category;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _logbook.getLogs(
      startDate: _startDate,
      endDate: _endDate,
      level: _level,
      category: _category,
      searchQuery: _searchQuery,
    );
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LogFilterSheet(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialLevel: _level,
        initialCategory: _category,
        initialSearchQuery: _searchQuery,
        onApply: ({startDate, endDate, level, category, searchQuery}) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _level = level;
            _category = category;
            _searchQuery = searchQuery;
          });
          _loadLogs();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyLogbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _logbook.exportAndShareLogs(),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No logs found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _level = null;
                          _category = null;
                          _searchQuery = null;
                        });
                        _loadLogs();
                      },
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _LogListTile(log: log);
                },
              ),
            ),
    );
  }

  bool get _hasActiveFilters =>
      _startDate != null ||
      _endDate != null ||
      _level != null ||
      _category != null ||
      (_searchQuery != null && _searchQuery!.isNotEmpty);
}

class _LogListTile extends StatelessWidget {
  final LogEntry log;

  const _LogListTile({required this.log});

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    if (log.level == LogLevel.error) {
      levelColor = Colors.red;
    } else if (log.level == LogLevel.warning) {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.blue;
    }

    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: levelColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getIconForLevel(log.level), color: levelColor, size: 20),
      ),
      title: Text(
        log.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.category.name.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            log.timestamp
                .toIso8601String()
                .split('T')
                .join(' ')
                .split('.')
                .first,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText('Time: ${log.timestamp}'),
              const SizedBox(height: 8),
              SelectableText('Level: ${log.level}, Category: ${log.category}'),
              const SizedBox(height: 8),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(log.message),
              if (log.error != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SelectableText(log.error.toString()),
              ],
              if (log.stackTrace != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(log.stackTrace.toString()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }
}
