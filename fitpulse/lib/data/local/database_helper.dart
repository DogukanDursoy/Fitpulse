import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_station.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. KİLO VE GELİŞİM GEÇMİŞİ (Yeni eklediğimiz takip tablosu)
    await db.execute('''
      CREATE TABLE WeightHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // 2. Egzersizler (SVG için Primary/Secondary kas grubu çok kritik!)
    await db.execute('''
      CREATE TABLE Exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        primary_muscle TEXT,
        secondary_muscle TEXT
      )
    ''');

    // 3. Antrenman Programları (Push, Pull vb.)
    await db.execute('''
      CREATE TABLE WorkoutPrograms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        tag TEXT,
        duration TEXT,
        intensity TEXT,
        image_url TEXT,
        placeholder_color INTEGER,
        is_draft INTEGER DEFAULT 0 
      )
    ''');

    // 4. Antrenman Kayıtları (Hibrit zorluk puanı burada)
    await db.execute('''
      CREATE TABLE WorkoutSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER,
        date TEXT,
        duration INTEGER, 
        total_volume REAL,
        rpe_score INTEGER,
        hybrid_difficulty_score REAL,
        FOREIGN KEY (program_id) REFERENCES WorkoutPrograms (id) ON DELETE SET NULL
      )
    ''');

    // 5. Setler (Hacim hesaplamalarının kaynağı)
    await db.execute('''
      CREATE TABLE WorkoutSets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        exercise_id INTEGER,
        set_number INTEGER,
        reps INTEGER,
        weight REAL,
        FOREIGN KEY (session_id) REFERENCES WorkoutSessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES Exercises (id) ON DELETE CASCADE
      )
    ''');

    // 6. Programın İçindeki Hareketler
    await db.execute('''
      CREATE TABLE ProgramExercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER,
        exercise_name TEXT,
        sets TEXT,
        reps TEXT,
        FOREIGN KEY (program_id) REFERENCES WorkoutPrograms (id) ON DELETE CASCADE
      )
    ''');
  }
}
