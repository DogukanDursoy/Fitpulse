import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../exercise_catalog.dart';
import '../../models/workout_model.dart';

class WorkoutDao {
  final dbHelper = DatabaseHelper.instance;

  // Antrenman oturumunu kaydet (Geriye ID döndürür ki setleri bu ID'ye bağlayalım)
  Future<int> insertSession(WorkoutSession session) async {
    final db = await dbHelper.database;
    return await db.insert('WorkoutSessions', session.toMap());
  }

  // Seti kaydet
  Future<int> insertSet(WorkoutSet setItem) async {
    final db = await dbHelper.database;
    return await db.insert('WorkoutSets', setItem.toMap());
  }

  // ANTRENMANI KAYDET (Oturum + Setler tek işlemde)
  // Önce WorkoutSessions'a ana bilgileri yazar, dönen session_id ile
  // ekrandaki tüm setleri WorkoutSets tablosuna bağlar.
  // Geriye oluşan session_id döner.
  Future<int> saveWorkoutSession({
    required DateTime date,
    required int duration,
    required List<WorkoutExerciseState> exercises,
    int? programId,
  }) async {
    final db = await dbHelper.database;

    // Boş setleri (değer girilmemiş satırları) kayda dahil etmiyoruz
    final validExercises = exercises
        .map((e) => MapEntry(e, e.filledSets))
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (validExercises.isEmpty) {
      throw Exception('Kaydedilecek geçerli bir set bulunamadı.');
    }

    // Özet metrikler: toplam tonaj ve ortalama RPE
    double totalVolume = 0;
    int rpeSum = 0;
    int setCount = 0;
    for (final entry in validExercises) {
      final isStatic = entry.key.isStatic;
      for (final set in entry.value) {
        totalVolume += set.volume(isStatic);
        rpeSum += set.difficulty;
        setCount++;
      }
    }
    final int avgRpe = (rpeSum / setCount).round();

    // Hibrit zorluk skoru = Session RPE (Foster) → ortalama RPE * süre (dk)
    final double hybridDifficultyScore = avgRpe * duration.toDouble();

    // Yarım kalmış kayıt oluşmaması için her şey tek transaction içinde
    return await db.transaction<int>((txn) async {
      final sessionId = await txn.insert('WorkoutSessions', {
        'program_id': programId,
        'date': date.toIso8601String(),
        'duration': duration,
        'total_volume': totalVolume,
        'rpe_score': avgRpe,
        'hybrid_difficulty_score': hybridDifficultyScore,
      });

      for (final entry in validExercises) {
        // Set'i kas haritasına bağlayabilmek için hareketin ID'sine ihtiyacımız var
        final exerciseId = await _resolveExerciseId(txn, entry.key.name);

        final isStatic = entry.key.isStatic;
        for (var i = 0; i < entry.value.length; i++) {
          final set = entry.value[i];
          await txn.insert('WorkoutSets', {
            'session_id': sessionId,
            'exercise_id': exerciseId,
            'set_number': i + 1,
            // Statik duruşta tekrar yok, süre var
            'reps': isStatic ? null : set.reps,
            'duration_seconds': isStatic ? set.seconds : null,
            'weight': set.weight,
            'difficulty': set.difficulty,
          });
        }
      }

      return sessionId;
    });
  }

  // Hareket adından Exercises tablosundaki ID'yi bulur.
  // Kayıtlı değilse (kullanıcının seçtiği yeni hareket) tabloya ekleyip ID'sini döner,
  // böylece istatistik ekranındaki JOIN sorguları hiçbir seti kaybetmez.
  Future<int> _resolveExerciseId(DatabaseExecutor txn, String name) async {
    final existing = await txn.query(
      'Exercises',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await txn.insert('Exercises', {
      'name': name,
      'primary_muscle': '',
      'secondary_muscle': '',
    });
  }

  // ANA SAYFA: Son 10 Antrenmanı Getir (5 vs 5 Sliding Window algoritman için)
  Future<List<WorkoutSession>> getLastNSessions(int limit) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutSessions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => WorkoutSession.fromMap(maps[i]));
  }

  // Tüm programları getir (All seçeneği için)
  Future<List<WorkoutProgram>> getAllPrograms() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('WorkoutPrograms');
    return List.generate(maps.length, (i) => WorkoutProgram.fromMap(maps[i]));
  }

  // Tag'e göre getir (Strength, Cardio vs. filtreleri için)
  Future<List<WorkoutProgram>> getProgramsByTag(String tag) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutPrograms',
      where: 'tag = ?',
      whereArgs: [tag],
    );
    return List.generate(maps.length, (i) => WorkoutProgram.fromMap(maps[i]));
  }

  // Senin UI verilerini SQLite'a başlangıçta gömecek tohum fonksiyonu
  Future<void> seedWorkoutPrograms() async {
    final db = await dbHelper.database;

    // Tablo doluysa tekrar ekleme
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM WorkoutPrograms'));
    if (count != null && count > 0) return;

    final List<WorkoutProgram> seedData = [
      WorkoutProgram(
          title: 'Power Hypertrophy',
          tag: 'STRENGTH',
          duration: '45 mins',
          intensity: 'Advanced',
          placeholderColor: 0xFF16181A,
          imageUrl:
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000&auto=format&fit=crop'),
      WorkoutProgram(
          title: 'Vicious HIIT Shred',
          tag: 'CARDIO',
          duration: '25 mins',
          intensity: 'High Intensity',
          placeholderColor: 0xFF1E2124,
          imageUrl:
              'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=1000&auto=format&fit=crop'),
      WorkoutProgram(
          title: 'Deep Core Recovery',
          tag: 'FLEXIBILITY',
          duration: '20 mins',
          intensity: 'Beginner',
          placeholderColor: 0xFF231B15,
          imageUrl:
              'https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=1000&auto=format&fit=crop'),
      WorkoutProgram(
          title: '5x5 Heavy Barbell',
          tag: 'STRENGTH',
          duration: '60 mins',
          intensity: 'Expert',
          placeholderColor: 0xFF1A1A1A,
          imageUrl:
              'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1000&auto=format&fit=crop'),
      WorkoutProgram(
          title: 'Sprint Intervals',
          tag: 'CARDIO',
          duration: '15 mins',
          intensity: 'Maximum',
          placeholderColor: 0xFF2A2424,
          imageUrl:
              'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1000&auto=format&fit=crop'),
      // Not: Arayüzündeki Color(0xFF...) formatı, veritabanına Integer olarak kaydedilir ve UI'da geri Color(val) olarak kullanılır.
    ];

    for (var program in seedData) {
      await db.insert('WorkoutPrograms', program.toMap());
    }
  }

  // İkincil kasın hacme katkı oranı.
  // Bench press'te göğüs kadar olmasa da triceps/ön omuz da yük alır;
  // bu katsayı olmadan harita yanıltıcı derecede boş görünüyor.
  static const double secondaryMuscleFactor = 0.5;

  // Bir tarihin ait olduğu haftanın pazartesi 00:00'ı
  static DateTime weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  // İSTATİSTİK EKRANI (SVG HARİTASI): Belirli tarihler arası kas hacmi hesaplama
  //
  // Setleri, Oturumları ve Egzersizleri birleştirip kaslara binen yükü (tonajı)
  // hesaplıyoruz:
  //   hacim = tekrar * (girilen kilo + hareketin vücut ağırlığı katsayısı * kilon)
  // Böylece barfiks gibi hareketler 0 kg girilse de yük üretir, ağırlıklı
  // yapıldığında ek yük vücut ağırlığının üstüne biner.
  // Birincil kas yükün tamamını, ikincil kas [secondaryMuscleFactor] kadarını alır.
  // [start] dahil, [end] hariçtir.
  Future<Map<String, double>> getMuscleVolumes(
    DateTime start,
    DateTime end, {
    double bodyWeight = 0,
  }) async {
    final db = await dbHelper.database;

    // Statik duruşlarda tekrar yok; süre eşdeğer tekrara çevriliyor
    const String effectiveReps = '''
      CASE WHEN COALESCE(e.is_static, 0) = 1
           THEN COALESCE(ws.duration_seconds, 0) / ?
           ELSE COALESCE(ws.reps, 0) END
    ''';

    const String query = '''
      SELECT muscle, SUM(volume) AS total_volume FROM (
        SELECT e.primary_muscle AS muscle,
               $effectiveReps * (ws.weight + COALESCE(e.bodyweight_factor, 0) * ?) AS volume
        FROM WorkoutSets ws
        JOIN WorkoutSessions s ON ws.session_id = s.id
        JOIN Exercises e ON ws.exercise_id = e.id
        WHERE s.date >= ? AND s.date < ?
          AND e.primary_muscle IS NOT NULL AND e.primary_muscle != ''
        UNION ALL
        SELECT e.secondary_muscle AS muscle,
               $effectiveReps * (ws.weight + COALESCE(e.bodyweight_factor, 0) * ?) * ? AS volume
        FROM WorkoutSets ws
        JOIN WorkoutSessions s ON ws.session_id = s.id
        JOIN Exercises e ON ws.exercise_id = e.id
        WHERE s.date >= ? AND s.date < ?
          AND e.secondary_muscle IS NOT NULL AND e.secondary_muscle != ''
      )
      GROUP BY muscle
      HAVING total_volume > 0
      ORDER BY total_volume DESC
    ''';

    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final rows = await db.rawQuery(query, [
      ExerciseCatalog.isometricSecondsPerRep,
      bodyWeight,
      startIso,
      endIso,
      ExerciseCatalog.isometricSecondsPerRep,
      bodyWeight,
      secondaryMuscleFactor,
      startIso,
      endIso,
    ]);

    return {
      for (final row in rows)
        row['muscle'] as String: (row['total_volume'] as num).toDouble(),
    };
  }

  // --- GELİŞİM ORANI (RPE DÜZELTMELİ e1RM) ---

  // Epley sabiti: her ek tekrar 1RM'in kabaca %3.3'ü kadar yük kaybettirir
  static const double _epleyDivisor = 30.0;

  // e1RM yüksek tekrarda güvenilmiyor; bu sınırların üstü hesaba girmez
  static const int maxRepsForE1rm = 12;
  static const int _maxEffectiveReps = 15;

  // Kullanıcı zorluğa dokunmadıysa varsayılan RPE
  static const int _defaultRpe = 8;

  /// Son [windowDays] gün ile ondan önceki [windowDays] günü kıyaslayarak
  /// compound hareketlerdeki güç değişimini yüzde olarak döner.
  ///
  /// Her hareketin o dönemdeki EN İYİ e1RM'i alınır (deload günleri ortalamayı
  /// aşağı çekmesin diye), sonra sadece İKİ DÖNEMDE DE yapılmış hareketlerin
  /// kendi yüzde değişimlerinin ortalaması hesaplanır. Böylece program
  /// değişikliği metriği bozmaz, yalnızca kıyas havuzunu daraltır.
  Future<StrengthProgress> getStrengthProgress({
    double bodyWeight = 0,
    int windowDays = 14,
    DateTime? now,
  }) async {
    final end = now ?? DateTime.now();
    final currentStart = end.subtract(Duration(days: windowDays));
    final previousStart = currentStart.subtract(Duration(days: windowDays));

    final current = await _bestE1rmByExercise(currentStart, end, bodyWeight);
    final previous =
        await _bestE1rmByExercise(previousStart, currentStart, bodyWeight);

    final changes = <double>[];
    current.forEach((exerciseId, currentBest) {
      final previousBest = previous[exerciseId];
      if (previousBest == null || previousBest <= 0) return;
      changes.add((currentBest - previousBest) / previousBest * 100);
    });

    if (changes.isEmpty) {
      return StrengthProgress(
        changePercent: null,
        comparedLifts: 0,
        hasCurrentData: current.isNotEmpty,
        hasPreviousData: previous.isNotEmpty,
      );
    }

    final average = changes.reduce((a, b) => a + b) / changes.length;
    return StrengthProgress(
      changePercent: average,
      comparedLifts: changes.length,
      hasCurrentData: true,
      hasPreviousData: true,
    );
  }

  // Bir dönemdeki her compound hareket için en yüksek e1RM
  //
  //   etkili tekrar = tekrar + (10 - RPE)        <- RPE'nin ta kendisi: kalan tekrar
  //   e1RM          = toplam yük * (1 + etkili tekrar / 30)
  //   toplam yük    = girilen kilo + vücut ağırlığı katsayısı * kilon
  Future<Map<int, double>> _bestE1rmByExercise(
      DateTime start, DateTime end, double bodyWeight) async {
    final db = await dbHelper.database;

    const String query = '''
      SELECT ws.exercise_id AS exercise_id,
             MAX(
               (ws.weight + COALESCE(e.bodyweight_factor, 0) * ?) *
               (1 + MIN(
                      ws.reps + (10 - COALESCE(NULLIF(ws.difficulty, 0), ?)),
                      ?
                    ) / ?)
             ) AS best_e1rm
      FROM WorkoutSets ws
      JOIN WorkoutSessions s ON ws.session_id = s.id
      JOIN Exercises e ON ws.exercise_id = e.id
      WHERE e.is_compound = 1
        AND COALESCE(e.is_static, 0) = 0
        AND ws.reps >= 1 AND ws.reps <= ?
        AND s.date >= ? AND s.date < ?
      GROUP BY ws.exercise_id
    ''';

    final rows = await db.rawQuery(query, [
      bodyWeight,
      _defaultRpe,
      _maxEffectiveReps,
      _epleyDivisor,
      maxRepsForE1rm,
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    return {
      for (final row in rows)
        if ((row['best_e1rm'] as num?) != null &&
            (row['best_e1rm'] as num) > 0)
          row['exercise_id'] as int: (row['best_e1rm'] as num).toDouble(),
    };
  }

  /// Haftalık hedefin üst üste kaç haftadır tutturulduğu.
  ///
  /// Günlük seri yerine haftalık seri sayıyoruz: dinlenme günleri programın
  /// parçası olduğu için "üst üste gün" serisi herkeste her hafta kırılırdı.
  ///
  /// İçinde bulunulan hafta henüz bitmediği için hedefi tutturmamış olması
  /// seriyi KIRMAZ; sadece seriye eklenmez.
  Future<int> getWeeklyGoalStreak(int weeklyGoal, {DateTime? now}) async {
    if (weeklyGoal <= 0) return 0;

    final currentWeek = weekStart(now ?? DateTime.now());
    const maxWeeksBack = 52;

    final days = await getSessionDays(
      currentWeek.subtract(const Duration(days: 7 * maxWeeksBack)),
      currentWeek.add(const Duration(days: 7)),
    );

    // Antrenman günlerini haftalara dağıt
    final weeklyCounts = <DateTime, int>{};
    for (final day in days) {
      final week = weekStart(day);
      weeklyCounts[week] = (weeklyCounts[week] ?? 0) + 1;
    }

    var streak = 0;
    if ((weeklyCounts[currentWeek] ?? 0) >= weeklyGoal) streak++;

    var cursor = currentWeek.subtract(const Duration(days: 7));
    for (var i = 0; i < maxWeeksBack; i++) {
      if ((weeklyCounts[cursor] ?? 0) < weeklyGoal) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }

    return streak;
  }

  // ANA SAYFA / İSTATİSTİK: Belirli aralıkta antrenman YAPILAN günler
  Future<Set<DateTime>> getSessionDays(DateTime start, DateTime end) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'WorkoutSessions',
      columns: ['date'],
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );

    return rows
        .map((row) => DateTime.parse(row['date'] as String))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
  }

  // Belirli bir antrenman programına (ID'ye) ait egzersizleri getir
  Future<List<ProgramExercise>> getExercisesForProgram(int programId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ProgramExercises',
      where: 'program_id = ?',
      whereArgs: [programId],
    );
    return List.generate(maps.length, (i) => ProgramExercise.fromMap(maps[i]));
  }

  // Test edebilmemiz için örnek hareketleri veritabanına basıyoruz
  Future<void> seedProgramExercises() async {
    final db = await dbHelper.database;

    // Tablo doluysa tekrar ekleme
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ProgramExercises'));
    if (count != null && count > 0) return;

    // ID 1: Power Hypertrophy (Strength)
    await db.insert(
        'ProgramExercises',
        // İsimler ExerciseCatalog ile birebir aynı olmalı; aksi halde kaydedilen
        // setler kas grubu olmayan yeni bir Exercises satırına bağlanır.
        ProgramExercise(
                programId: 1,
                exerciseName: 'Bench Press',
                sets: '4',
                reps: '5-8')
            .toMap());
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 1,
                exerciseName: 'Incline Dumbbell Press',
                sets: '3',
                reps: '8-10')
            .toMap());
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 1,
                exerciseName: 'Overhead Press',
                sets: '3',
                reps: '8-12')
            .toMap());

    // ID 2: Vicious HIIT Shred (Cardio)
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 2,
                exerciseName: 'Jump Rope',
                sets: '5',
                reps: '1 Min')
            .toMap());
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 2, exerciseName: 'Burpees', sets: '4', reps: '15-20')
            .toMap());

    // ID 4: 5x5 Heavy Barbell (Strength)
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 4, exerciseName: 'Squat', sets: '5', reps: '5')
            .toMap());
    await db.insert(
        'ProgramExercises',
        ProgramExercise(
                programId: 4, exerciseName: 'Deadlift', sets: '1', reps: '5')
            .toMap());
  }

  // Hazır programı kullanıcının taslaklarına kopyalar
  Future<void> saveProgramAsDraft(
      WorkoutProgram originalProgram, List<ProgramExercise> exercises) async {
    final db = await dbHelper.database;

    // 1. Programın kopyasını oluştur (is_draft = 1 olarak!)
    final newProgramId = await db.insert('WorkoutPrograms', {
      'title': originalProgram.title,
      'tag': originalProgram.tag,
      'duration': originalProgram.duration,
      'intensity': originalProgram.intensity,
      'image_url': originalProgram.imageUrl,
      'placeholder_color': originalProgram.placeholderColor,
      'is_draft': 1, // ARTIK BU BİR TASLAK
    });

    // 2. İçindeki hareketleri de bu yeni taslağın ID'si ile kopyala
    for (var exercise in exercises) {
      await db.insert('ProgramExercises', {
        'program_id': newProgramId,
        'exercise_name': exercise.exerciseName,
        'sets': exercise.sets,
        'reps': exercise.reps,
      });
    }
  }

  // Sadece taslak olan (is_draft = 1) programları getirir
  Future<List<WorkoutProgram>> getDraftWorkouts() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutPrograms',
      where: 'is_draft = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => WorkoutProgram.fromMap(maps[i]));
  }

  // Sadece kullanıcının kaydettiği veya oluşturduğu taslakları getir
  // Taslak varsa siler (false döner), yoksa ekler (true döner)
  Future<bool> toggleDraftWorkout(
      WorkoutProgram originalProgram, List<ProgramExercise> exercises) async {
    final db = await dbHelper.database;

    // Bu isimde bir taslak zaten var mı kontrol et
    final existing = await db.query(
      'WorkoutPrograms',
      where: 'title = ? AND is_draft = ?',
      whereArgs: [originalProgram.title, 1],
    );

    if (existing.isNotEmpty) {
      // Zaten varmış, o halde taslaklardan SİLİYORUZ
      final draftId = existing.first['id'] as int;
      await db.delete('WorkoutPrograms', where: 'id = ?', whereArgs: [draftId]);
      await db.delete('ProgramExercises',
          where: 'program_id = ?', whereArgs: [draftId]);
      return false; // Kaldırıldı
    } else {
      // Yokmuş, yeni kayıt olarak EKLİYORUZ
      final newProgramId = await db.insert('WorkoutPrograms', {
        'title': originalProgram.title,
        'tag': originalProgram.tag,
        'duration': originalProgram.duration,
        'intensity': originalProgram.intensity,
        'image_url': originalProgram.imageUrl,
        'placeholder_color': originalProgram.placeholderColor,
        'is_draft': 1,
      });

      for (var exercise in exercises) {
        await db.insert('ProgramExercises', {
          'program_id': newProgramId,
          'exercise_name': exercise.exerciseName,
          'sets': exercise.sets,
          'reps': exercise.reps,
        });
      }
      return true; // Eklendi
    }
  }

  // --- KİLO GEÇMİŞİ (METRİK) YÖNETİMİ ---

  // Yeni kilo kaydını tarihle birlikte atar
  Future<void> insertWeightRecord(double weight) async {
    final db = await dbHelper.database;
    await db.insert('WeightHistory', {
      'weight': weight,
      'date': DateTime.now().toIso8601String(), // Anlık tarihi kaydeder
    });
  }

  // Geçmiş kiloları tarihe göre sıralı getirir (İleride grafik çizmek için kullanacağız)
  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    final db = await dbHelper.database;
    return await db.query('WeightHistory', orderBy: 'date ASC');
  }

  // Uygulamaya ilk girilen kilo ("%x daha fitsin" kartının referans noktası)
  Future<double?> getFirstWeight() => _singleWeight('date ASC');

  // En güncel kilo (hacim hesabındaki vücut ağırlığı buradan gelir)
  Future<double?> getLatestWeight() => _singleWeight('date DESC');

  Future<double?> _singleWeight(String orderBy) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'WeightHistory',
      columns: ['weight'],
      orderBy: orderBy,
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['weight'] as num).toDouble();
  }

  // Onboarding'i çoktan geçmiş kullanıcıların kilo geçmişi boş kalmasın diye
  // profildeki mevcut kiloyu tek seferlik başlangıç kaydı olarak düşer.
  Future<void> ensureInitialWeightRecord(double weight) async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM WeightHistory'));
    if (count != null && count > 0) return;
    await insertWeightRecord(weight);
  }
}
