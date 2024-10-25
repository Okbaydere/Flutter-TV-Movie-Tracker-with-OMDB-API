import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:media_tracker/models/media_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  bool get isDatabaseInitialized => _database != null;

  DatabaseHelper._init();

  static const _databaseName = 'media_tracker.db';
  static const _databaseVersion = 5;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE media_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        originalType TEXT,
        year INTEGER NOT NULL,
        rating REAL,
        notes TEXT,
        posterUrl TEXT,
        plot TEXT,
        runtime TEXT,
        director TEXT,
        awards TEXT,
        boxOffice TEXT,
        imdbID TEXT,
        imdbRating TEXT,
        metascore TEXT,
        rottenTomatoesRating TEXT,
        userRating REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Add originalType column for watchlist items
      await db.execute('ALTER TABLE media_items ADD COLUMN originalType TEXT');
    }
  }

  Future<int> insertMediaItem(MediaItem item) async {
    final db = await instance.database;
    return await db.insert(
      'media_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MediaItem>> getMediaItems(String type) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) => MediaItem.fromMap(maps[i]));
  }

  Future<int> updateMediaItem(MediaItem item) async {
    final db = await instance.database;
    if (item.id == null) {
      throw Exception('Cannot update item without id');
    }
    return await db.update(
      'media_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteMediaItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'media_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}