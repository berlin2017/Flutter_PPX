import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SearchHistoryService {
  static Database? _database;
  static const String tableName = 'search_history';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'search_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSearch(String query) async {
    final db = await database;
    final data = {
      'query': query,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await db.insert(tableName, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getSearchHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
      limit: 10,
    );
    return maps.map((item) => item['query'] as String).toList();
  }

  Future<void> deleteSearchHistory(String query) async {
    final db = await database;
    await db.delete(tableName, where: 'query = ?', whereArgs: [query]);
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete(tableName);
  }
}
