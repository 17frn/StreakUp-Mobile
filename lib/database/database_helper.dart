import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'habit_tracker.db');
    return await openDatabase(
      path,
      version: 2, // UPGRADED VERSION untuk migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables (untuk database baru)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL,
        completedDates TEXT,
        startTime TEXT,
        endTime TEXT,
        notificationEnabled INTEGER DEFAULT 0,
        reminderMinutes INTEGER DEFAULT 15,
        notes TEXT
      )
    ''');
  }

  // Migration untuk database yang sudah ada
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah kolom notes jika belum ada
      await db.execute('ALTER TABLE habits ADD COLUMN notes TEXT');
    }
  }

  // Insert new habit
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all habits
  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Habit.fromMap(maps[i]);
    });
  }

  // Get single habit by id
  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  // Update habit
  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  // Delete habit
  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all habits
  Future<int> deleteAllHabits() async {
    final db = await database;
    return await db.delete('habits');
  }

  // Get habits count
  Future<int> getHabitsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM habits');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Search habits by name
  Future<List<Habit>> searchHabits(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Habit.fromMap(maps[i]);
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}