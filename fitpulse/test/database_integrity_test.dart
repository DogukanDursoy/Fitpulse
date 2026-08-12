import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Gerçek şema ve gerçek DAO'larla çalışan bütünlük testleri.
///
/// Foreign key denetimi bugüne kadar kapalıydı; açarken asıl risk silme değil
/// EKLEME tarafındaydı (var olmayan bir üst kayda insert artık patlar).
/// Buradaki testler hem denetimin çalıştığını hem de mevcut akışların
/// bozulmadığını doğruluyor.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Test dosyaları paralel koştuğu için kendi veritabanı dosyamızı kullanıyoruz
  const dbName = 'integrity_test.db';

  setUp(() async {
    await DatabaseHelper.resetForTesting(databaseName: dbName);
    await deleteDatabase(join(await getDatabasesPath(), dbName));
  });

  tearDownAll(() async {
    await DatabaseHelper.resetForTesting();
  });

  // Uygulamanın açılışta yaptığı hazırlık (main.dart ile aynı sıra)
  Future<WorkoutDao> seededDao() async {
    final dao = WorkoutDao();
    await dao.seedWorkoutPrograms();
    await dao.seedProgramExercises();
    await ExerciseDao().seedExerciseCatalog();
    return dao;
  }

  group('foreign key denetimi', () {
    test('bağlantıda foreign_keys açık', () async {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first.values.first, 1);
    });

    test('var olmayan programa ait oturum eklenemez', () async {
      final db = await DatabaseHelper.instance.database;
      expect(
        () => db.insert('WorkoutSessions', {
          'program_id': 9999,
          'date': DateTime(2026, 8, 1).toIso8601String(),
          'duration': 45,
          'total_volume': 1000.0,
          'rpe_score': 8,
          'hybrid_difficulty_score': 360.0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('oturum silinince setleri de silinir (CASCADE)', () async {
      final dao = await seededDao();
      final sessionId = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 1),
        duration: 45,
        exercises: [
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 8, weight: 80, difficulty: 8)],
          ),
        ],
      );

      final db = await DatabaseHelper.instance.database;
      expect(
          Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM WorkoutSets WHERE session_id = ?',
              [sessionId])),
          1);

      await db
          .delete('WorkoutSessions', where: 'id = ?', whereArgs: [sessionId]);

      expect(
          Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM WorkoutSets WHERE session_id = ?',
              [sessionId])),
          0,
          reason: 'öksüz set kalmamalı');
    });

    test('program silinince oturum kaybolmaz, bağlantısı düşer (SET NULL)',
        () async {
      final dao = await seededDao();
      final programs = await dao.getAllPrograms();
      final program = programs.firstWhere((p) => p.title == 'Power Hypertrophy');

      final sessionId = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 1),
        duration: 45,
        programId: program.id,
        exercises: [
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 8, weight: 80, difficulty: 8)],
          ),
        ],
      );

      final db = await DatabaseHelper.instance.database;
      await db
          .delete('WorkoutPrograms', where: 'id = ?', whereArgs: [program.id]);

      final rows = await db
          .query('WorkoutSessions', where: 'id = ?', whereArgs: [sessionId]);
      expect(rows.length, 1, reason: 'antrenman kaydı korunmalı');
      expect(rows.first['program_id'], isNull);

      // Programın hareketleri ise onunla birlikte gitmeli (CASCADE)
      expect(
          Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM ProgramExercises WHERE program_id = ?',
              [program.id])),
          0);
    });
  });

  group('açılış akışı foreign key ile bozulmuyor', () {
    test('tohumlama hatasız tamamlanır ve hareketler doğru programa bağlanır',
        () async {
      final dao = await seededDao();

      final programs = await dao.getAllPrograms();
      expect(programs.length, 5);

      final power = programs.firstWhere((p) => p.title == 'Power Hypertrophy');
      final exercises = await dao.getExercisesForProgram(power.id!);
      expect(exercises.map((e) => e.exerciseName),
          containsAll(['Bench Press', 'Incline Dumbbell Press']));

      final barbell = programs.firstWhere((p) => p.title == '5x5 Heavy Barbell');
      final barbellExercises = await dao.getExercisesForProgram(barbell.id!);
      expect(barbellExercises.map((e) => e.exerciseName),
          containsAll(['Squat', 'Deadlift']));
    });

    test('tekrar tohumlama kopya üretmez', () async {
      final dao = await seededDao();
      await dao.seedWorkoutPrograms();
      await dao.seedProgramExercises();

      expect((await dao.getAllPrograms()).length, 5);
    });
  });

  group('antrenman kaydı', () {
    test('silinmiş programla kaydedilen antrenman kaybolmaz', () async {
      final dao = await seededDao();
      final programs = await dao.getAllPrograms();
      final program = programs.first;

      final db = await DatabaseHelper.instance.database;
      await db
          .delete('WorkoutPrograms', where: 'id = ?', whereArgs: [program.id]);

      // Kullanıcı şablonu açıkken program silinmiş olabilir; kaydı düşürmek
      // yerine bağlantıyı düşürüyoruz
      final sessionId = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 1),
        duration: 45,
        programId: program.id,
        exercises: [
          WorkoutExerciseState(
            name: 'Squat',
            sets: [WorkoutSetState(reps: 5, weight: 100, difficulty: 9)],
          ),
        ],
      );

      final rows = await db
          .query('WorkoutSessions', where: 'id = ?', whereArgs: [sessionId]);
      expect(rows.length, 1);
      expect(rows.first['program_id'], isNull);
    });

    test('kaydedilen setler kas haritasına ulaşır', () async {
      final dao = await seededDao();
      await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 3),
        duration: 50,
        exercises: [
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 10, weight: 60, difficulty: 8)],
          ),
        ],
      );

      final volumes = await dao.getMuscleVolumes(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 10),
      );
      expect(volumes, isNotEmpty, reason: 'setler JOIN sorgusunda kaybolmamalı');
    });
  });

  group('favorileme', () {
    test('favorileme programı listede ikiye katlamaz', () async {
      final dao = await seededDao();
      final before = await dao.getAllPrograms();
      final program = before.firstWhere((p) => p.title == 'Power Hypertrophy');

      expect(await dao.toggleFavorite(program.id!), isTrue);

      final after = await dao.getAllPrograms();
      expect(after.length, before.length, reason: 'kopya satır oluşmamalı');
      expect(after.where((p) => p.title == 'Power Hypertrophy').length, 1);
      expect(after.firstWhere((p) => p.id == program.id).isSaved, isTrue);
    });

    test('favorilenen program Taslaklarım listesine girer ve çıkar', () async {
      final dao = await seededDao();
      final program = (await dao.getAllPrograms())
          .firstWhere((p) => p.title == 'Power Hypertrophy');

      expect(await dao.getSavedPrograms(), isEmpty);

      await dao.toggleFavorite(program.id!);
      final saved = await dao.getSavedPrograms();
      expect(saved.length, 1);
      expect(saved.first.title, 'Power Hypertrophy');

      expect(await dao.toggleFavorite(program.id!), isFalse);
      expect(await dao.getSavedPrograms(), isEmpty);
    });

    test('favoriden çıkarmak programın hareketlerini silmez', () async {
      final dao = await seededDao();
      final program = (await dao.getAllPrograms())
          .firstWhere((p) => p.title == 'Power Hypertrophy');

      await dao.toggleFavorite(program.id!);
      await dao.toggleFavorite(program.id!);

      expect(await dao.getExercisesForProgram(program.id!), hasLength(3));
    });
  });
}
