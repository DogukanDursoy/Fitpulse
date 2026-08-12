import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const _defaultDatabaseName = 'workout_station.db';
  static String _databaseName = _defaultDatabaseName;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  /// Testler her senaryoyu temiz bir veritabanıyla başlatabilsin diye.
  ///
  /// [databaseName] paralel koşan test dosyalarının aynı dosyayı kilitlememesi
  /// için verilir; her dosya kendi adını kullanmalı.
  @visibleForTesting
  static Future<void> resetForTesting({String? databaseName}) async {
    await _database?.close();
    _database = null;
    _databaseName = databaseName ?? _defaultDatabaseName;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onConfigure: _configureDB,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // SQLite'ta foreign key denetimi bağlantı başına KAPALI gelir; açılmazsa
  // şemadaki ON DELETE CASCADE / SET NULL ifadeleri hiç çalışmaz.
  //
  // onConfigure, onCreate/onUpgrade'den önce ve transaction DIŞINDA koşar;
  // PRAGMA foreign_keys transaction içinde sessizce yok sayıldığı için
  // doğru yeri burasıdır.
  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
    if (oldVersion < 6) {
      // v6: Favorileme artık programın kopyasını çıkarmıyor, bayrak çeviriyor.
      // Eski model her favorilemede is_draft=1 olan bir kopya satırı üretiyordu;
      // bu kopyalar Antrenman sekmesinde şablonun iki kez görünmesine yol açıyor,
      // favoriden çıkarıldıklarında da kendilerine bağlı oturumları öksüz bırakıyordu.
      await db.execute(
          'ALTER TABLE WorkoutPrograms ADD COLUMN is_favorite INTEGER DEFAULT 0');
      await _migrateDraftCopiesToFavorites(db);
    }
  }

  // v6 veri taşıması: mevcut cihazlardaki kopya satırları temizler.
  //
  // Kopya = başlığı bir katalog satırıyla aynı olan is_draft=1 satırı.
  // Kullanıcının kendi oluşturduğu (katalogda karşılığı olmayan) taslaklar
  // varsa onlara dokunulmaz.
  Future _migrateDraftCopiesToFavorites(Database db) async {
    const String copies = '''
      SELECT c.id FROM WorkoutPrograms c
      WHERE c.is_draft = 1
        AND EXISTS (SELECT 1 FROM WorkoutPrograms o
                    WHERE o.is_draft = 0 AND o.title = c.title)
    ''';

    // 1. Kopyası olan katalog satırlarını favori işaretle
    await db.execute('''
      UPDATE WorkoutPrograms SET is_favorite = 1
      WHERE is_draft = 0
        AND EXISTS (SELECT 1 FROM WorkoutPrograms c
                    WHERE c.is_draft = 1 AND c.title = WorkoutPrograms.title)
    ''');

    // 2. Kopyayla yapılmış antrenmanları orijinal programa bağla
    await db.execute('''
      UPDATE WorkoutSessions SET program_id = (
        SELECT o.id FROM WorkoutPrograms o
        JOIN WorkoutPrograms c ON c.title = o.title
        WHERE o.is_draft = 0 AND c.is_draft = 1
          AND c.id = WorkoutSessions.program_id
      )
      WHERE program_id IN ($copies)
    ''');

    // 3. Kopyaların hareketlerini ve kendilerini sil
    await db
        .execute('DELETE FROM ProgramExercises WHERE program_id IN ($copies)');
    await db.execute('DELETE FROM WorkoutPrograms WHERE id IN ($copies)');

    // 4. Foreign key'ler bugüne kadar kapalı olduğu için birikmiş öksüz
    //    kayıtları temizliyoruz; aksi halde denetim açıldıktan sonraki ilk
    //    yazma işlemi bu eski satırlar yüzünden patlayabilir.
    await db.execute('''
      UPDATE WorkoutSessions SET program_id = NULL
      WHERE program_id IS NOT NULL
        AND program_id NOT IN (SELECT id FROM WorkoutPrograms)
    ''');
    await db.execute('''
      DELETE FROM WorkoutSets
      WHERE session_id NOT IN (SELECT id FROM WorkoutSessions)
         OR exercise_id NOT IN (SELECT id FROM Exercises)
    ''');
    await db.execute('''
      DELETE FROM ProgramExercises
      WHERE program_id NOT IN (SELECT id FROM WorkoutPrograms)
    ''');
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
        is_draft INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0
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
