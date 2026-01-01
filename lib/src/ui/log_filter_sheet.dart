import 'package:flutter/material.dart';
import '../../logbook.dart';

class LogFilterSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final LogLevel? initialLevel;
  final LogCategory? initialCategory;
  final String? initialSearchQuery;
  final Function({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    LogCategory? category,
    String? searchQuery,
  })
  onApply;

  const LogFilterSheet({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialLevel,
    this.initialCategory,
    this.initialSearchQuery,
    required this.onApply,
  });

  @override
  State<LogFilterSheet> createState() => _LogFilterSheetState();
}

class _LogFilterSheetState extends State<LogFilterSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  LogLevel? _level;
  LogCategory? _category;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _level = widget.initialLevel;
    _category = widget.initialCategory;
    _searchController = TextEditingController(text: widget.initialSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _level = null;
      _category = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Logs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Query',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<LogLevel>(
                  value: _level,
                  items: LogLevel.values,
                  label: 'Level',
                  onChanged: (val) => setState(() => _level = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown<LogCategory>(
                  value: _category,
                  items: LogCategory.values,
                  label: 'Category',
                  onChanged: (val) => setState(() => _category = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate == null
                        ? 'Start Date'
                        : _startDate!.toIso8601String().split('T')[0],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _endDate == null
                        ? 'End Date'
                        : _endDate!.toIso8601String().split('T')[0],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onApply(
                startDate: _startDate,
                endDate: _endDate,
                level: _level,
                category: _category,
                searchQuery: _searchController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String label,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text('All'),
          items: [
            DropdownMenuItem<T>(value: null, child: Text('All')),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString().split('.').last.toUpperCase()),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
