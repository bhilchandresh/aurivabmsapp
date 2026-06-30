import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aurivabms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE clients (
  _id $idType,
  remote_id $textType,
  data $textType
)
''');

    await db.execute('''
CREATE TABLE invoices (
  _id $idType,
  remote_id $textType,
  data $textType
)
''');

    await db.execute('''
CREATE TABLE inventory (
  _id $idType,
  remote_id $textType,
  data $textType
)
''');
  }

  // Generic method to insert cached data
  Future<void> cacheData(String table, String remoteId, String dataJson) async {
    final db = await instance.database;
    await db.insert(
      table,
      {'remote_id': remoteId, 'data': dataJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Generic method to get all cached data
  Future<List<Map<String, dynamic>>> getCachedData(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
