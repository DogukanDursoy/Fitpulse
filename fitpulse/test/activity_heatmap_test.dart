import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Profildeki aylık aktivite haritasının veri kaynağı.
///
/// Harita daha önce tamamen sahteydi: renk hücrenin sırasından hesaplanıyordu
/// (`(index * 7 + 3) % 4`), yani herkeste aynı desen çıkıyor ve hiç antrenman
/// yapmamış biri bile dolu bir takvim görüyordu.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const dbName = 'activity_heatmap_test.db';

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

  Future<void> logLift(WorkoutDao dao, DateTime date, double weight) {
    return dao.saveWorkoutSession(
      date: date,
      duration: 45,
      exercises: [
        WorkoutExerciseState(
          name: 'Bench Press',
          sets: [WorkoutSetState(reps: 10, weight: weight, difficulty: 8)],
        ),
      ],
    );
  }

  final windowStart = DateTime(2026, 7, 20);
  final windowEnd = DateTime(2026, 8, 17);

  test('antrenman yokken harita boş', () async {
    final dao = await seededDao();
    expect(await dao.getDailyVolumes(windowStart, windowEnd), isEmpty);
  });

  test('antrenman yapılan gün tonajıyla birlikte döner', () async {
    final dao = await seededDao();
    await logLift(dao, DateTime(2026, 8, 3, 18, 30), 80);

    final volumes = await dao.getDailyVolumes(windowStart, windowEnd);
    expect(volumes.keys, [DateTime(2026, 8, 3)],
        reason: 'saat bilgisi düşürülüp güne yuvarlanmalı');
    expect(volumes[DateTime(2026, 8, 3)], 800.0);
  });

  test('aynı güne iki antrenman girilirse tonaj toplanır', () async {
    final dao = await seededDao();
    await logLift(dao, DateTime(2026, 8, 3, 9), 80);
    await logLift(dao, DateTime(2026, 8, 3, 19), 60);

    final volumes = await dao.getDailyVolumes(windowStart, windowEnd);
    expect(volumes, hasLength(1));
    expect(volumes[DateTime(2026, 8, 3)], 1400.0);
  });

  // Haritanın can alıcı noktası. Süreyle ölçülen kardiyo hareketlerinin vücut
  // ağırlığı katsayısı yok, dolayısıyla tonajları sıfır. Anahtarın varlığı ile
  // değeri ayrılmasaydı 45 dakika koşulan bir gün "antrenman yapılmamış"
  // görünürdü.
  test('kardiyo günü tonajsız da olsa haritada işaretli', () async {
    final dao = await seededDao();
    await dao.saveWorkoutSession(
      date: DateTime(2026, 8, 5),
      duration: 45,
      exercises: [
        WorkoutExerciseState(
          name: 'Treadmill Run',
          sets: [WorkoutSetState(seconds: 2700, weight: 0, difficulty: 7)],
        ),
      ],
    );

    final volumes = await dao.getDailyVolumes(windowStart, windowEnd);
    expect(volumes.containsKey(DateTime(2026, 8, 5)), isTrue,
        reason: 'kardiyo günü de antrenman günüdür');
    expect(volumes[DateTime(2026, 8, 5)], 0.0,
        reason: 'kardiyo tonaj üretmez');
  });

  test('pencere dışındaki günler gelmez', () async {
    final dao = await seededDao();
    await logLift(dao, DateTime(2026, 7, 19), 80); // başlangıçtan bir gün önce
    await logLift(dao, DateTime(2026, 7, 20), 80); // başlangıç: dahil
    await logLift(dao, DateTime(2026, 8, 16), 80); // bitişten bir gün önce
    await logLift(dao, DateTime(2026, 8, 17), 80); // bitiş: hariç

    final volumes = await dao.getDailyVolumes(windowStart, windowEnd);
    expect(volumes.keys.toSet(),
        {DateTime(2026, 7, 20), DateTime(2026, 8, 16)});
  });

  // Harita pazartesiye hizalı 4 tam hafta gösteriyor; 28 gün 7'nin katı
  // olduğu için her sütun sabit bir güne denk geliyor.
  test('28 günlük pencere pazartesiden pazara hizalı', () {
    for (final today in [
      DateTime(2026, 8, 13), // perşembe
      DateTime(2026, 8, 10), // pazartesi
      DateTime(2026, 8, 16), // pazar
    ]) {
      final start = WorkoutDao.weekStart(today)
          .subtract(const Duration(days: 21));
      expect(start.weekday, DateTime.monday, reason: '$today');
      expect(start.add(const Duration(days: 27)).weekday, DateTime.sunday,
          reason: '$today');
      expect(today.difference(start).inDays, lessThan(28),
          reason: 'bugün pencerenin içinde kalmalı');
    }
  });
}
