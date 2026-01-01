import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'log_entry.dart';

/// Helper class for managing SQLite database connections and operations.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Returns the path to the database file.
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'logbook.db');
  }

  /// Compresses the database file into a .zip archive.
  /// Returns the path to the created zip file.
  Future<String> createZipArchive() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found at $dbPath');
    }

    final encoder = ZipFileEncoder();
    final zipPath = '${dbPath}_${DateTime.now().millisecondsSinceEpoch}.zip';

    encoder.create(zipPath);
    encoder.addFile(dbFile);
    encoder.close();

    return zipPath;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        level TEXT NOT NULL,
        category TEXT NOT NULL,
        message TEXT NOT NULL,
        error TEXT,
        stack_trace TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE logs ADD COLUMN category TEXT DEFAULT "other"',
      );
    }
  }

  /// Inserts a log entry into the database.
  Future<void> insertLog(LogEntry entry) async {
    final db = await database;
    await db.insert(
      'logs',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves logs from the database with optional filters.
  Future<List<LogEntry>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
    LogLevel? level,
    LogCategory? category,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '1=1'; // Always true, makes appending simpler
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (level != null) {
      whereClause += ' AND level = ?';
      whereArgs.add(level.toString().split('.').last);
    }

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category.toString().split('.').last);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND (message LIKE ? OR error LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return LogEntry.fromMap(maps[i]);
    });
  }

  /// Deletes all logs from the database.
  Future<void> clearLogs() async {
    final db = await database;
    await db.delete('logs');
  }

  /// Deletes logs older than the specified [timestamp].
  Future<int> deleteLogsOlderThan(DateTime timestamp) async {
    final db = await database;
    return await db.delete(
      'logs',
      where: 'timestamp < ?',
      whereArgs: [timestamp.toIso8601String()],
    );
  }

  /// Archives logs older than the specified [timestamp] into [archiveTableName].
  Future<int> archiveLogsOlderThan(
    DateTime timestamp,
    String archiveTableName,
  ) async {
    final db = await database;
    final timestampStr = timestamp.toIso8601String();

    return await db.transaction((txn) async {
      // 1. Create archive table if it doesn't exist
      // We replicate the schema of the main 'logs' table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS $archiveTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          level TEXT NOT NULL,
          category TEXT NOT NULL,
          message TEXT NOT NULL,
          error TEXT,
          stack_trace TEXT
        )
      ''');

      // 2. Copy data to archive table
      // We explicitly list columns to match the schema
      await txn.execute(
        '''
        INSERT INTO $archiveTableName (timestamp, level, category, message, error, stack_trace)
        SELECT timestamp, level, category, message, error, stack_trace
        FROM logs
        WHERE timestamp < ?
      ''',
        [timestampStr],
      );

      // 3. Delete from original table
      final deletedCount = await txn.delete(
        'logs',
        where: 'timestamp < ?',
        whereArgs: [timestampStr],
      );

      return deletedCount;
    });
  }
}
