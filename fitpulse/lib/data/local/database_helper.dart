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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Şema güncellemeleri (Cihazda eski veritabanı varsa veri kaybı olmadan geçiş)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: Set bazlı RPE (zorluk) puanı
      await db.execute('ALTER TABLE WorkoutSets ADD COLUMN difficulty INTEGER');
    }
    if (oldVersion < 3) {
      // v3: Vücut ağırlıklı hareketlerin hacim katsayısı
      await db.execute(
          'ALTER TABLE Exercises ADD COLUMN bodyweight_factor REAL DEFAULT 0');
    }
    if (oldVersion < 4) {
      // v4: Gelişim oranı hesabına giren compound hareket işareti
      await db.execute(
          'ALTER TABLE Exercises ADD COLUMN is_compound INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      // v5: Statik (izometrik) hareketler tekrar yerine süreyle kaydedilir
      await db.execute(
          'ALTER TABLE Exercises ADD COLUMN is_static INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE WorkoutSets ADD COLUMN duration_seconds INTEGER');
    }
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
        secondary_muscle TEXT,
        bodyweight_factor REAL DEFAULT 0,
        is_compound INTEGER DEFAULT 0,
        is_static INTEGER DEFAULT 0
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
        difficulty INTEGER,
        duration_seconds INTEGER,
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
