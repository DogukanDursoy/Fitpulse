import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/core/utils/turkish_date.dart';
import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Profildeki "Kişisel Rekorlar" kartı daha önce elle yazılmış sahte
/// değerler gösteriyordu. Buradaki testler kartın artık gerçek setlerden
/// beslendiğini ve gösterdiği ağırlık/tekrar/tarih üçlüsünün GERÇEKTEN
/// yapılmış tek bir sete ait olduğunu doğruluyor.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const dbName = 'personal_records_test.db';

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

  PersonalRecord recordFor(List<PersonalRecord> records, String name) =>
      records.firstWhere((record) => record.exerciseName == name);

  group('getPersonalRecords', () {
    test('kayıt yokken boş liste döner', () async {
      final dao = await seededDao();
      expect(await dao.getPersonalRecords(), isEmpty);
    });

    // Kartın can alıcı noktası: MAX() ile seçilen satırın ağırlığı, tekrarı ve
    // tarihi birbirinden kopmamalı. Kopsaydı kullanıcıya hiç yapmadığı bir set
    // gösterilirdi — düzeltmeye çalıştığımız sorunun ta kendisi.
    test('gösterilen ağırlık, tekrar ve tarih aynı sete ait', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 40,
        exercises: [
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [
              WorkoutSetState(reps: 8, weight: 80, difficulty: 8),
              // e1RM'i en yüksek set bu: 100 * (1 + (6+2)/30) = 126.7
              WorkoutSetState(reps: 6, weight: 100, difficulty: 8),
              WorkoutSetState(reps: 10, weight: 70, difficulty: 9),
            ],
          ),
        ],
      );

      final record = recordFor(await dao.getPersonalRecords(), 'Bench Press');
      expect(record.weight, 100);
      expect(record.reps, 6);
      expect(record.date, DateTime(2026, 3, 4));
    });

    // Rekor "en ağır set" değil: tek tekrarlık bir zorlama, çok daha üretken
    // bir setin önüne geçmemeli.
    test('daha ağır ama tek tekrarlık set rekoru kapmaz', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 40,
        exercises: [
          WorkoutExerciseState(
            name: 'Squat',
            sets: [
              // 120 * (1 + 3/30) = 132
              WorkoutSetState(reps: 1, weight: 120, difficulty: 10),
              // 100 * (1 + 10/30) = 133.3
              WorkoutSetState(reps: 8, weight: 100, difficulty: 8),
            ],
          ),
        ],
      );

      final record = recordFor(await dao.getPersonalRecords(), 'Squat');
      expect(record.weight, 100);
      expect(record.reps, 8);
    });

    test('rekor tüm antrenman geçmişinden seçilir', () async {
      final dao = await seededDao();

      for (final (date, weight) in [
        (DateTime(2025, 1, 10), 90.0),
        (DateTime(2026, 2, 10), 110.0), // rekor
        (DateTime(2026, 8, 10), 95.0),
      ]) {
        await dao.saveWorkoutSession(
          date: date,
          duration: 40,
          exercises: [
            WorkoutExerciseState(
              name: 'Deadlift',
              sets: [WorkoutSetState(reps: 5, weight: weight, difficulty: 8)],
            ),
          ],
        );
      }

      final record = recordFor(await dao.getPersonalRecords(), 'Deadlift');
      expect(record.weight, 110);
      expect(record.date, DateTime(2026, 2, 10));
    });

    test('her hareketten en fazla bir satır, e1RM sırasıyla', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 60,
        exercises: [
          WorkoutExerciseState(
            name: 'Deadlift',
            sets: [
              WorkoutSetState(reps: 5, weight: 140, difficulty: 8),
              WorkoutSetState(reps: 5, weight: 130, difficulty: 8),
            ],
          ),
          WorkoutExerciseState(
            name: 'Squat',
            sets: [WorkoutSetState(reps: 5, weight: 110, difficulty: 8)],
          ),
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 5, weight: 80, difficulty: 8)],
          ),
        ],
      );

      final records = await dao.getPersonalRecords();
      expect(records.map((r) => r.exerciseName).toList(),
          ['Deadlift', 'Squat', 'Bench Press']);
      expect(records.first.weight, 140);
    });

    test('limit en iyi rekorları kırpar', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 60,
        exercises: [
          for (final (name, weight) in [
            ('Deadlift', 140.0),
            ('Squat', 110.0),
            ('Bench Press', 80.0),
            ('Barbell Curl', 30.0),
          ])
            WorkoutExerciseState(
              name: name,
              sets: [WorkoutSetState(reps: 5, weight: weight, difficulty: 8)],
            ),
        ],
      );

      final records = await dao.getPersonalRecords(limit: 2);
      expect(records.map((r) => r.exerciseName).toList(),
          ['Deadlift', 'Squat']);
    });

    // İzolasyon hareketleri gelişim oranı hesabından bilinçli olarak dışarıda;
    // ama kullanıcının kendi rekoru olarak görünmemeleri için bir sebep yok.
    test('izolasyon hareketleri de rekor üretir', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 30,
        exercises: [
          WorkoutExerciseState(
            name: 'Barbell Curl',
            sets: [WorkoutSetState(reps: 8, weight: 40, difficulty: 8)],
          ),
        ],
      );

      final record = recordFor(await dao.getPersonalRecords(), 'Barbell Curl');
      expect(record.weight, 40);
    });

    // Plank saniyeyle kaydedilir; tekrarı NULL olduğu için aynı ölçüyle
    // kıyaslanamaz ve karta girmemeli.
    test('statik duruşlar rekor listesine girmez', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 20,
        exercises: [
          WorkoutExerciseState(
            name: 'Plank',
            sets: [WorkoutSetState(seconds: 90, weight: 20, difficulty: 8)],
          ),
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 5, weight: 80, difficulty: 8)],
          ),
        ],
      );

      final records = await dao.getPersonalRecords();
      expect(records.map((r) => r.exerciseName), isNot(contains('Plank')));
      expect(records, hasLength(1));
    });

    test('ek yük girilmemiş barfiks vücut ağırlığıyla rekor sayılır', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 20,
        exercises: [
          WorkoutExerciseState(
            name: 'Pull-Up',
            sets: [WorkoutSetState(reps: 12, weight: 0, difficulty: 9)],
          ),
        ],
      );

      final records = await dao.getPersonalRecords(bodyWeight: 80);
      final record = recordFor(records, 'Pull-Up');
      expect(record.weight, 0);
      expect(record.reps, 12);
      expect(record.isBodyweightOnly, isTrue);
    });

    // Kilo geçmişi boşsa barfiksin yükü 0 çıkar; "0 kg rekor" göstermektense
    // satırı hiç göstermemek doğru. Kartın geri kalanı dolu kalmalı.
    test('kilo bilinmiyorken yüksüz hareket elenir, diğerleri kalır', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 40,
        exercises: [
          WorkoutExerciseState(
            name: 'Pull-Up',
            sets: [WorkoutSetState(reps: 10, weight: 0, difficulty: 9)],
          ),
          WorkoutExerciseState(
            name: 'Bench Press',
            sets: [WorkoutSetState(reps: 5, weight: 80, difficulty: 8)],
          ),
        ],
      );

      final records = await dao.getPersonalRecords(bodyWeight: 0);
      expect(records.map((r) => r.exerciseName).toList(), ['Bench Press']);
    });

    // Etkili tekrar 15'te sınırlı olduğu için 30 tekrarlık hafif bir set
    // ağır bir setin önüne geçemez.
    test('çok yüksek tekrarlı set şişkin rekor üretmez', () async {
      final dao = await seededDao();

      await dao.saveWorkoutSession(
        date: DateTime(2026, 3, 4),
        duration: 40,
        exercises: [
          WorkoutExerciseState(
            name: 'Squat',
            sets: [
              // 60 * (1 + 15/30) = 90  (etkili tekrar 32 değil, 15)
              WorkoutSetState(reps: 30, weight: 60, difficulty: 8),
              // 100 * (1 + 7/30) = 123.3
              WorkoutSetState(reps: 5, weight: 100, difficulty: 8),
            ],
          ),
        ],
      );

      final record = recordFor(await dao.getPersonalRecords(), 'Squat');
      expect(record.weight, 100);
      expect(record.reps, 5);
    });
  });

  group('formatShortDate', () {
    test('bu yılın tarihinde yıl yazılmaz', () {
      expect(
        formatShortDate(DateTime(2026, 10, 12), now: DateTime(2026, 8, 13)),
        '12 Eki',
      );
    });

    test('geçen yılın tarihinde yıl yazılır', () {
      expect(
        formatShortDate(DateTime(2025, 1, 3), now: DateTime(2026, 8, 13)),
        '3 Oca 2025',
      );
    });
  });
}
