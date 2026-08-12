import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

/// Gerçek şema ve gerçek DAO'larla çalışan bütünlük testleri.
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

    // Eski modelde favoriden çıkarmak satırı siliyordu; kopyanın hareketleri
    // de onunla gidiyordu. Artık sadece bayrak çevriliyor.
    test('favoriden çıkarmak programın hareketlerini silmez', () async {
      final dao = await seededDao();
      final program = (await dao.getAllPrograms())
          .firstWhere((p) => p.title == 'Power Hypertrophy');

      await dao.toggleFavorite(program.id!);
      await dao.toggleFavorite(program.id!);

      expect(await dao.getExercisesForProgram(program.id!), hasLength(3));
    });
  });

  group('tohumlama', () {
    test('hazır şablonlar bir kez yüklenir', () async {
      final dao = await seededDao();
      expect((await dao.getAllPrograms()).length, 5);

      await dao.seedWorkoutPrograms();
      await dao.seedProgramExercises();
      expect((await dao.getAllPrograms()).length, 5);
    });
  });
}
