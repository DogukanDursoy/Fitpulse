import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/local/exercise_catalog.dart';
import 'package:fitpulse/data/models/achievement_model.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Profildeki rozetler.
///
/// Önceden üç sabit rozet vardı ("Streak Master", "Iron Will", "Early Bird");
/// kimse kazanmıyor, kimse kaybetmiyordu. Artık hepsi kayıtlardan türetiliyor
/// ve veritabanında SAKLANMIYOR — bir antrenman silinirse rozet de geri alınır.
void main() {
  group('kademe mantığı (saf)', () {
    Achievement badge(List<Achievement> all, String title) =>
        all.firstWhere((a) => a.title == title);

    test('veri yokken hiçbir rozet kazanılmamış ama hepsi listeleniyor', () {
      final all = buildAchievements(const AchievementStats());

      expect(all, hasLength(5));
      expect(all.every((a) => !a.isEarned), isTrue);
      expect(all.map((a) => a.title),
          containsAll(['Seri', 'Tonaj', 'Sadakat', 'Denge', 'Güç']));
    });

    test('eşiğe ulaşınca kademe artar', () {
      for (final (sessions, expectedTier) in [
        (0, 0),
        (9, 0),
        (10, 1),
        (49, 1),
        (50, 2),
        (100, 3),
        (250, 3), // en üst kademede kalır
      ]) {
        final loyalty = badge(
          buildAchievements(AchievementStats(sessionCount: sessions)),
          'Sadakat',
        );
        expect(loyalty.tier, expectedTier, reason: '$sessions antrenman');
      }
    });

    test('kazanılmamış rozet bir sonraki hedefi gösterir', () {
      final loyalty = badge(
        buildAchievements(const AchievementStats(sessionCount: 3)),
        'Sadakat',
      );
      expect(loyalty.label, '3 antrenman / 10 antrenman');
      expect(loyalty.isEarned, isFalse);
    });

    test('en üst kademede hedef değil ulaşılan değer yazar', () {
      final loyalty = badge(
        buildAchievements(const AchievementStats(sessionCount: 120)),
        'Sadakat',
      );
      expect(loyalty.label, '120 antrenman');
      expect(loyalty.isMaxed, isTrue);
    });

    test('tonaj bine ulaşınca kg yerine ton yazılır', () {
      String tonnageLabel(double volume) => badge(
            buildAchievements(AchievementStats(totalVolume: volume)),
            'Tonaj',
          ).label;

      expect(tonnageLabel(800), startsWith('800 kg'));
      expect(tonnageLabel(12400), startsWith('12.4 ton'));
      expect(tonnageLabel(120000), '120 ton');
    });

    test('kazanılan rozetler listenin başına geçer', () {
      final all = buildAchievements(
          const AchievementStats(sessionCount: 120, weeklyGoalStreak: 3));

      final tiers = all.map((a) => a.tier).toList();
      expect(tiers, orderedEquals([...tiers]..sort((a, b) => b.compareTo(a))));
      expect(all.first.title, 'Sadakat', reason: 'en yüksek kademe önde');
    });

    // "Denge" rozetinin en üst kademesi "tüm kas gruplarına dokun" demek.
    // Kategori listesine yeni bir grup eklenirse eşik de büyümeli, yoksa
    // rozet sessizce olduğundan kolay kazanılır hale gelir.
    test('Denge rozetinin üst eşiği kas grubu sayısıyla aynı', () {
      expect(balanceBadgeTopThreshold, MuscleGroups.mainCategories.length);
    });
  });

  group('veritabanından gelen sayılar', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    const dbName = 'achievements_test.db';

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

    Future<int> log(WorkoutDao dao, DateTime date, List<String> names) {
      return dao.saveWorkoutSession(
        date: date,
        duration: 45,
        exercises: [
          for (final name in names)
            WorkoutExerciseState(
              name: name,
              sets: [WorkoutSetState(reps: 10, weight: 50, difficulty: 8)],
            ),
        ],
      );
    }

    test('kayıt yokken bütün sayılar sıfır', () async {
      final dao = await seededDao();
      final stats = await dao.getAchievementStats(weeklyGoal: 4);

      expect(stats.sessionCount, 0);
      expect(stats.totalVolume, 0);
      expect(stats.bestWeekMuscleGroups, 0);
      expect(stats.recordedCompoundLifts, 0);
    });

    test('antrenman sayısı ve tonaj toplanır', () async {
      final dao = await seededDao();
      await log(dao, DateTime(2026, 8, 3), ['Bench Press']);
      await log(dao, DateTime(2026, 8, 5), ['Squat']);

      final stats = await dao.getAchievementStats(weeklyGoal: 4);
      expect(stats.sessionCount, 2);
      expect(stats.totalVolume, 1000.0); // 2 x (10 tekrar x 50 kg)
    });

    test('rekoru olan compound hareketler sayılır, izolasyon sayılmaz',
        () async {
      final dao = await seededDao();
      await log(dao, DateTime(2026, 8, 3),
          ['Bench Press', 'Squat', 'Barbell Curl', 'Lateral Raise']);

      final stats = await dao.getAchievementStats(weeklyGoal: 4);
      expect(stats.recordedCompoundLifts, 2,
          reason: 'Barbell Curl ve Lateral Raise compound değil');
    });

    // Denge geçmişin tamamına bakıyor: bir başarı rozeti, bu haftanın durum
    // raporu değil. İyi bir hafta geçirip sonra bırakınca rozet kaybolmamalı.
    test('Denge en iyi haftayı hatırlar, sonraki kötü hafta düşürmez',
        () async {
      final dao = await seededDao();

      // 3-9 Ağustos 2026 haftası: dört farklı kas grubu
      await log(dao, DateTime(2026, 8, 3), ['Bench Press']); // Göğüs
      await log(dao, DateTime(2026, 8, 4), ['Barbell Row']); // Sırt
      await log(dao, DateTime(2026, 8, 5), ['Squat']); // Bacak
      // Plank değil: statik duruşlar saniyeyle kaydediliyor, tekrar kabul etmiyor
      await log(dao, DateTime(2026, 8, 6), ['Hanging Leg Raise']); // Core

      expect((await dao.getAchievementStats(weeklyGoal: 4)).bestWeekMuscleGroups,
          4);

      // Ertesi hafta yalnızca bir grup
      await log(dao, DateTime(2026, 8, 11), ['Bench Press']);

      expect((await dao.getAchievementStats(weeklyGoal: 4)).bestWeekMuscleGroups,
          4, reason: 'en iyi hafta geçmişte kalsa da sayılır');
    });

    test('aynı kas grubunu iki kez çalışmak Denge sayısını artırmaz', () async {
      final dao = await seededDao();
      await log(dao, DateTime(2026, 8, 3), ['Bench Press']);
      await log(dao, DateTime(2026, 8, 5), ['Incline Dumbbell Press']);

      expect((await dao.getAchievementStats(weeklyGoal: 4)).bestWeekMuscleGroups,
          1, reason: 'ikisi de Göğüs');
    });

    // Rozet durumu saklanmadığı için kayıt silinince rozet de geri alınmalı.
    test('antrenman silinince sayılar geri düşer', () async {
      final dao = await seededDao();
      final sessionId = await log(dao, DateTime(2026, 8, 3), ['Bench Press']);

      expect((await dao.getAchievementStats(weeklyGoal: 4)).sessionCount, 1);

      final db = await DatabaseHelper.instance.database;
      await db.delete('WorkoutSessions', where: 'id = ?', whereArgs: [sessionId]);

      final stats = await dao.getAchievementStats(weeklyGoal: 4);
      expect(stats.sessionCount, 0);
      expect(stats.recordedCompoundLifts, 0);
      expect(stats.bestWeekMuscleGroups, 0);
    });
  });
}
