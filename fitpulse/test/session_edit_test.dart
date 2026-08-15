import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Kaydedilmiş antrenmanı geri okuma, düzenleme ve silme.
///
/// Kaydetme akışı bugüne kadar yalnızca INSERT yapıyordu ve hiçbir silme
/// fonksiyonu yoktu: yanlış girilen bir set kalıcıydı. Buradaki testler
/// düzenlemenin özet sütunlarını yeniden hesapladığını, set numaralarının
/// yeniden sıralandığını ve türetilmiş her şeyin (rekorlar, ısı haritası,
/// rozetler) kendiliğinden düzeldiğini doğruluyor.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const dbName = 'session_edit_test.db';

  setUp(() async {
    await DatabaseHelper.resetForTesting(databaseName: dbName);
    await deleteDatabase(join(await getDatabasesPath(), dbName));
  });

  tearDownAll(() async {
    await DatabaseHelper.resetForTesting();
  });

  Future<WorkoutDao> seededDao() async {
    final dao = WorkoutDao();
    await dao.seedWorkoutPrograms();
    await dao.seedProgramExercises();
    await ExerciseDao().seedExerciseCatalog();
    return dao;
  }

  WorkoutExerciseState exercise(String name, List<WorkoutSetState> sets) =>
      WorkoutExerciseState(name: name, sets: sets);

  WorkoutSetState set(double weight, int reps, [int rpe = 8]) =>
      WorkoutSetState(weight: weight, reps: reps, difficulty: rpe);

  group('geri okuma', () {
    test('kaydedilen antrenman aynı hareket ve setlerle geri gelir', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8), set(85, 6)]),
          exercise('Squat', [set(100, 5)]),
        ],
      );

      final detail = await dao.getSessionDetail(id);
      expect(detail, isNotNull);
      expect(detail!.date, DateTime(2026, 8, 10));
      expect(detail.duration, 50);
      expect(detail.exercises.map((e) => e.name), ['Bench Press', 'Squat']);
      expect(detail.exercises.first.sets.map((s) => s.weight), [80, 85]);
      expect(detail.exercises.first.sets.map((s) => s.reps), [8, 6]);
    });

    test('statik hareket süresiyle geri gelir, tekrarla değil', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 20,
        exercises: [
          exercise('Plank', [WorkoutSetState(seconds: 60, weight: 0)]),
        ],
      );

      final detail = await dao.getSessionDetail(id);
      expect(detail!.exercises.first.sets.first.seconds, 60);
      expect(detail.exercises.first.sets.first.reps, 0);
    });

    test('olmayan antrenman null döner', () async {
      final dao = await seededDao();
      expect(await dao.getSessionDetail(9999), isNull);
    });
  });

  group('düzenleme', () {
    test('setler değişince tonaj ve RPE yeniden hesaplanır', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(800, 10, 10)]), // yanlış girilmiş
        ],
      );

      var sessions = await dao.getLastNSessions(1);
      expect(sessions.first.totalVolume, 8000);

      await dao.updateWorkoutSession(
        sessionId: id,
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 10, 8)]), // düzeltildi
        ],
      );

      sessions = await dao.getLastNSessions(1);
      expect(sessions, hasLength(1), reason: 'yeni kayıt açılmamalı');
      expect(sessions.first.id, id, reason: 'oturumun id\'si korunmalı');
      expect(sessions.first.totalVolume, 800);
      expect(sessions.first.rpeScore, 8);
      expect(sessions.first.hybridDifficultyScore, 400);
    });

    test('düzenleme kişisel rekoru düzeltir', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(800, 10)]),
        ],
      );

      expect((await dao.getPersonalRecords()).first.weight, 800);

      await dao.updateWorkoutSession(
        sessionId: id,
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 10)]),
        ],
      );

      expect((await dao.getPersonalRecords()).first.weight, 80);
    });

    // Ortadaki bir set silinince numaralar kaymalı; aksi halde 1 ve 3 diye
    // giden, ikincisi eksik bir dizi kalırdı.
    test('set silinince numaralar yeniden sıralanır', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8), set(85, 6), set(90, 4)]),
        ],
      );

      await dao.updateWorkoutSession(
        sessionId: id,
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8), set(90, 4)]), // ortadaki gitti
        ],
      );

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('WorkoutSets',
          where: 'session_id = ?', whereArgs: [id], orderBy: 'set_number');

      expect(rows.map((r) => r['set_number']), [1, 2]);
      expect(rows.map((r) => r['weight']), [80.0, 90.0]);
    });

    test('hareket çıkarılınca setleri de gider', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
          exercise('Squat', [set(100, 5)]),
        ],
      );

      await dao.updateWorkoutSession(
        sessionId: id,
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Squat', [set(100, 5)]),
        ],
      );

      final detail = await dao.getSessionDetail(id);
      expect(detail!.exercises.map((e) => e.name), ['Squat']);
    });

    test('tarih değişince ısı haritasındaki gün de taşınır', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
        ],
      );

      await dao.updateWorkoutSession(
        sessionId: id,
        date: DateTime(2026, 8, 12),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
        ],
      );

      final volumes = await dao.getDailyVolumes(
          DateTime(2026, 8, 1), DateTime(2026, 8, 20));
      expect(volumes.keys, [DateTime(2026, 8, 12)]);
    });

    test('boş bırakılan antrenman güncellenemez', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
        ],
      );

      expect(
        () => dao.updateWorkoutSession(
          sessionId: id,
          date: DateTime(2026, 8, 10),
          duration: 50,
          exercises: [exercise('Bench Press', [WorkoutSetState()])],
        ),
        throwsA(isA<Exception>()),
      );

      // Patlayan güncelleme eski kaydı bozmamalı
      final detail = await dao.getSessionDetail(id);
      expect(detail!.exercises.first.sets.first.weight, 80);
    });
  });

  group('silme', () {
    test('antrenman ve setleri birlikte silinir', () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
        ],
      );

      expect(await dao.deleteSession(id), isTrue);

      final db = await DatabaseHelper.instance.database;
      expect(
        Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM WorkoutSets WHERE session_id = ?', [id])),
        0,
        reason: 'öksüz set kalmamalı',
      );
      expect(await dao.getSessionDetail(id), isNull);
    });

    test('olmayan antrenmanı silmek false döner', () async {
      final dao = await seededDao();
      expect(await dao.deleteSession(9999), isFalse);
    });

    // Türetilmiş ekranların hepsi tek bir silmeyle düzelmeli: bunlardan biri
    // veritabanında saklansaydı hak edilmemiş bir rekor ya da rozet kalırdı.
    test('silme rekorları, ısı haritasını ve rozetleri birlikte temizler',
        () async {
      final dao = await seededDao();
      final id = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(800, 10)]),
        ],
      );

      expect(await dao.getPersonalRecords(), isNotEmpty);

      await dao.deleteSession(id);

      expect(await dao.getPersonalRecords(), isEmpty);
      expect(
          await dao.getDailyVolumes(
              DateTime(2026, 8, 1), DateTime(2026, 8, 20)),
          isEmpty);

      final stats = await dao.getAchievementStats(weeklyGoal: 4);
      expect(stats.sessionCount, 0);
      expect(stats.totalVolume, 0);
      expect(stats.recordedCompoundLifts, 0);
      expect(stats.bestWeekMuscleGroups, 0);
    });

    test('bir antrenmanı silmek diğerlerini etkilemez', () async {
      final dao = await seededDao();
      final first = await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 10),
        duration: 50,
        exercises: [
          exercise('Bench Press', [set(80, 8)]),
        ],
      );
      await dao.saveWorkoutSession(
        date: DateTime(2026, 8, 12),
        duration: 50,
        exercises: [
          exercise('Squat', [set(100, 5)]),
        ],
      );

      await dao.deleteSession(first);

      final remaining = await dao.getLastNSessions(10);
      expect(remaining, hasLength(1));
      expect((await dao.getSessionDetail(remaining.first.id!))!
          .exercises.first.name, 'Squat');
    });
  });
}
