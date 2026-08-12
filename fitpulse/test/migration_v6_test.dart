import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

/// v5 -> v6 geçişi: favorileme artık programın kopyasını çıkarmıyor.
///
/// Cihazlarda eski modelle üretilmiş kopya satırlar duruyor. Bu testler
/// geçişin o kopyaları temizlediğini, kullanıcının antrenman geçmişini
/// kaybetmediğini ve foreign key denetimi açıldıktan sonra veritabanının
/// tutarlı kaldığını doğruluyor.
void main() {
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Test dosyaları paralel koştuğu için kendi veritabanı dosyamızı kullanıyoruz
  const dbName = 'migration_v6_test.db';

  setUp(() async {
    await DatabaseHelper.resetForTesting(databaseName: dbName);
    dbPath = join(await getDatabasesPath(), dbName);
    await deleteDatabase(dbPath);
  });

  tearDownAll(() async {
    await DatabaseHelper.resetForTesting();
  });

  // v6 öncesi şemayı ve eski favorileme modelinin ürettiği veriyi kurar
  Future<void> buildLegacyV5Database() async {
    final db = await openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE WeightHistory (id INTEGER PRIMARY KEY AUTOINCREMENT, weight REAL NOT NULL, date TEXT NOT NULL)');
        await db.execute(
            'CREATE TABLE Exercises (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, primary_muscle TEXT, secondary_muscle TEXT, bodyweight_factor REAL DEFAULT 0, is_compound INTEGER DEFAULT 0, is_static INTEGER DEFAULT 0)');
        await db.execute(
            'CREATE TABLE WorkoutPrograms (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, tag TEXT, duration TEXT, intensity TEXT, image_url TEXT, placeholder_color INTEGER, is_draft INTEGER DEFAULT 0)');
        await db.execute(
            'CREATE TABLE WorkoutSessions (id INTEGER PRIMARY KEY AUTOINCREMENT, program_id INTEGER, date TEXT, duration INTEGER, total_volume REAL, rpe_score INTEGER, hybrid_difficulty_score REAL, FOREIGN KEY (program_id) REFERENCES WorkoutPrograms (id) ON DELETE SET NULL)');
        await db.execute(
            'CREATE TABLE WorkoutSets (id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER, exercise_id INTEGER, set_number INTEGER, reps INTEGER, weight REAL, difficulty INTEGER, duration_seconds INTEGER, FOREIGN KEY (session_id) REFERENCES WorkoutSessions (id) ON DELETE CASCADE, FOREIGN KEY (exercise_id) REFERENCES Exercises (id) ON DELETE CASCADE)');
        await db.execute(
            'CREATE TABLE ProgramExercises (id INTEGER PRIMARY KEY AUTOINCREMENT, program_id INTEGER, exercise_name TEXT, sets TEXT, reps TEXT, FOREIGN KEY (program_id) REFERENCES WorkoutPrograms (id) ON DELETE CASCADE)');
      },
    );

    // Katalog satırı (id 1)
    await db.insert('WorkoutPrograms', {
      'title': 'Power Hypertrophy',
      'tag': 'STRENGTH',
      'duration': '45 mins',
      'intensity': 'Advanced',
      'image_url': 'http://example.com/a.jpg',
      'placeholder_color': 0xFF16181A,
      'is_draft': 0,
    });
    await db.insert('ProgramExercises', {
      'program_id': 1,
      'exercise_name': 'Bench Press',
      'sets': '4',
      'reps': '5-8',
    });

    // Eski favorileme modelinin ürettiği kopya (id 2) — Antrenman sekmesinde
    // şablonun ikinci kez görünmesine yol açan satır
    await db.insert('WorkoutPrograms', {
      'title': 'Power Hypertrophy',
      'tag': 'STRENGTH',
      'duration': '45 mins',
      'intensity': 'Advanced',
      'image_url': 'http://example.com/a.jpg',
      'placeholder_color': 0xFF16181A,
      'is_draft': 1,
    });
    await db.insert('ProgramExercises', {
      'program_id': 2,
      'exercise_name': 'Bench Press',
      'sets': '4',
      'reps': '5-8',
    });

    // Kullanıcı kopya üzerinden antrenman yapmış
    await db.insert('Exercises', {
      'name': 'Bench Press',
      'primary_muscle': 'chest',
      'secondary_muscle': 'triceps',
    });
    await db.insert('WorkoutSessions', {
      'program_id': 2,
      'date': DateTime(2026, 8, 1).toIso8601String(),
      'duration': 45,
      'total_volume': 800.0,
      'rpe_score': 8,
      'hybrid_difficulty_score': 360.0,
    });
    await db.insert('WorkoutSets', {
      'session_id': 1,
      'exercise_id': 1,
      'set_number': 1,
      'reps': 10,
      'weight': 80.0,
      'difficulty': 8,
    });

    // Foreign key'ler kapalıyken favoriden çıkarılmış bir programa asılı
    // kalmış öksüz oturum
    await db.insert('WorkoutSessions', {
      'program_id': 999,
      'date': DateTime(2026, 8, 2).toIso8601String(),
      'duration': 30,
      'total_volume': 400.0,
      'rpe_score': 7,
      'hybrid_difficulty_score': 210.0,
    });

    await db.close();
  }

  test('geçiş kopyayı temizler, şablon listede tek kalır', () async {
    await buildLegacyV5Database();

    final dao = WorkoutDao();
    final programs = await dao.getAllPrograms();

    expect(programs.length, 1, reason: 'kopya satır silinmiş olmalı');
    expect(programs.first.title, 'Power Hypertrophy');
    expect(programs.first.isSaved, isTrue,
        reason: 'kopyası olan program favori olarak işaretlenmeli');
  });

  test('favori durumu Taslaklarım listesinde korunur', () async {
    await buildLegacyV5Database();

    final saved = await WorkoutDao().getSavedPrograms();
    expect(saved.length, 1);
    expect(saved.first.title, 'Power Hypertrophy');
  });

  test('kopyayla yapılmış antrenman kaybolmaz, orijinale bağlanır', () async {
    await buildLegacyV5Database();

    final db = await DatabaseHelper.instance.database;
    final sessions = await db.query('WorkoutSessions', orderBy: 'id ASC');

    expect(sessions.length, 2, reason: 'hiçbir antrenman silinmemeli');
    expect(sessions.first['program_id'], 1,
        reason: 'kopyaya bağlı oturum orijinal programa taşınmalı');
  });

  test('öksüz oturumun bağlantısı temizlenir', () async {
    await buildLegacyV5Database();

    final db = await DatabaseHelper.instance.database;
    final sessions = await db.query('WorkoutSessions', orderBy: 'id ASC');

    expect(sessions.last['program_id'], isNull);
    expect(sessions.last['total_volume'], 400.0,
        reason: 'oturumun kendisi korunmalı');
  });

  test('geçiş sonrası setler ve kas haritası bozulmaz', () async {
    await buildLegacyV5Database();

    final db = await DatabaseHelper.instance.database;
    expect(
        Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM WorkoutSets')),
        1);

    final volumes = await WorkoutDao().getMuscleVolumes(
      DateTime(2026, 7, 25),
      DateTime(2026, 8, 10),
    );
    expect(volumes['chest'], 800.0);
  });

  test('geçiş sonrası veritabanı foreign key denetiminden temiz geçer',
      () async {
    await buildLegacyV5Database();

    final db = await DatabaseHelper.instance.database;
    expect((await db.rawQuery('PRAGMA foreign_keys')).first.values.first, 1);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty,
        reason: 'geçişten sonra tutarsız satır kalmamalı');
  });

  test('kopyanın hareketleri silinir, orijinalinkiler durur', () async {
    await buildLegacyV5Database();

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('ProgramExercises');

    expect(rows.length, 1);
    expect(rows.first['program_id'], 1);
  });
}
