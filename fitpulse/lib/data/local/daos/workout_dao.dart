import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../exercise_catalog.dart';
import '../../models/workout_model.dart';

class WorkoutDao {
  final dbHelper = DatabaseHelper.instance;

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
      // Program bu arada silinmişse oturumu programsız kaydediyoruz.
      // Foreign key denetimi açık olduğu için var olmayan bir program_id
      // insert'i patlatır ve kullanıcı BÜTÜN antrenmanını kaybederdi;
      // bağlantıyı düşürmek, kaydı düşürmekten iyidir.
      final safeProgramId =
          await _programExists(txn, programId) ? programId : null;

      final sessionId = await txn.insert('WorkoutSessions', {
        'program_id': safeProgramId,
        'date': date.toIso8601String(),
        'duration': duration,
        'total_volume': totalVolume,
        'rpe_score': avgRpe,
        'hybrid_difficulty_score': hybridDifficultyScore,
      });

      // Set numarası hareket bazında ilerler. Aynı seansta aynı hareket iki kez
      // eklenebiliyor (drop set, programın farklı bölümlerinde tekrar); numarayı
      // her grupta 1'den başlatmak aynı exercise_id için iki tane "set 1"
      // üretiyordu. Sayacı exercise_id'ye bağlayınca numaralar seans içinde
      // benzersiz kalıyor.
      final setNumbers = <int, int>{};

      for (final entry in validExercises) {
        // Set'i kas haritasına bağlayabilmek için hareketin ID'sine ihtiyacımız var
        final exerciseId = await _resolveExerciseId(txn, entry.key.name);

        final isStatic = entry.key.isStatic;
        for (final set in entry.value) {
          final setNumber = (setNumbers[exerciseId] ?? 0) + 1;
          setNumbers[exerciseId] = setNumber;

          await txn.insert('WorkoutSets', {
            'session_id': sessionId,
            'exercise_id': exerciseId,
            'set_number': setNumber,
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

  Future<bool> _programExists(DatabaseExecutor txn, int? programId) async {
    if (programId == null) return false;
    final rows = await txn.query(
      'WorkoutPrograms',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [programId],
      limit: 1,
    );
    return rows.isNotEmpty;
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

  // Antrenman sekmesindeki hazır şablonlar.
  // Kullanıcının kendi programları (is_draft = 1) buraya karışmaz;
  // onların yeri "Taslaklarım".
  Future<List<WorkoutProgram>> getAllPrograms() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutPrograms',
      where: 'is_draft = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => WorkoutProgram.fromMap(maps[i]));
  }

  /// Uygulamayla birlikte gelen hazır şablonlar.
  ///
  /// Kart görselleri ProgramVisuals ile koddan çiziliyor; fotoğrafı olmayan
  /// programlar etiketlerinden türeyen bir gradyan alıyor, image_url boş
  /// kalıyor ve şemada geriye dönük uyumluluk için duruyor.
  static final List<WorkoutProgram> _programSeed = [
    // --- BÖLGESEL BÖLÜNMELER ---
    WorkoutProgram(
        title: 'İtiş Günü',
        tag: 'STRENGTH',
        duration: '55 dk',
        intensity: 'Orta',
        placeholderColor: 0xFF1B2130),
    WorkoutProgram(
        title: 'Çekiş Günü',
        tag: 'STRENGTH',
        duration: '55 dk',
        intensity: 'Orta',
        placeholderColor: 0xFF14262E),
    WorkoutProgram(
        title: 'Bacak Günü',
        tag: 'STRENGTH',
        duration: '55 dk',
        intensity: 'Zorlu',
        placeholderColor: 0xFF10241F),
    WorkoutProgram(
        title: 'Üst Vücut',
        tag: 'STRENGTH',
        duration: '50 dk',
        intensity: 'Orta',
        placeholderColor: 0xFF221A2C),
    WorkoutProgram(
        title: 'Alt Vücut',
        tag: 'STRENGTH',
        duration: '50 dk',
        intensity: 'Orta',
        placeholderColor: 0xFF1D2416),
    // --- TÜM VÜCUT ---
    WorkoutProgram(
        title: 'Power Hypertrophy',
        tag: 'STRENGTH',
        duration: '60 dk',
        intensity: 'İleri',
        placeholderColor: 0xFF16181A),
    WorkoutProgram(
        title: '5x5 Heavy Barbell',
        tag: 'STRENGTH',
        duration: '60 dk',
        intensity: 'İleri',
        placeholderColor: 0xFF1A1A1A),
    WorkoutProgram(
        title: 'Tüm Vücut Başlangıç',
        tag: 'STRENGTH',
        duration: '40 dk',
        intensity: 'Başlangıç',
        placeholderColor: 0xFF1C1E26),
    WorkoutProgram(
        title: 'Ev Antrenmanı',
        tag: 'STRENGTH',
        duration: '30 dk',
        intensity: 'Başlangıç',
        placeholderColor: 0xFF241E1A),
    // --- KARDİYO ---
    WorkoutProgram(
        title: 'Vicious HIIT Shred',
        tag: 'CARDIO',
        duration: '25 dk',
        intensity: 'Yüksek Tempo',
        placeholderColor: 0xFF1E2124),
    WorkoutProgram(
        title: 'Sprint Intervals',
        tag: 'CARDIO',
        duration: '20 dk',
        intensity: 'Maksimum',
        placeholderColor: 0xFF2A2424),
    WorkoutProgram(
        title: 'Dayanıklılık Koşusu',
        tag: 'CARDIO',
        duration: '45 dk',
        intensity: 'Orta',
        placeholderColor: 0xFF1A2430),
    WorkoutProgram(
        title: 'Metabolik Devre',
        tag: 'CARDIO',
        duration: '30 dk',
        intensity: 'Zorlu',
        placeholderColor: 0xFF2C1E18),
    // --- ESNEKLİK / TOPARLANMA ---
    WorkoutProgram(
        title: 'Deep Core Recovery',
        tag: 'FLEXIBILITY',
        duration: '20 dk',
        intensity: 'Başlangıç',
        placeholderColor: 0xFF231B15),
  ];

  /// Hazır şablonları veritabanına yazar.
  ///
  /// Eskiden "tablo doluysa hiçbir şey yapma" mantığıyla çalışıyordu; bu,
  /// güncellemeyle eklenen yeni bir programın mevcut kullanıcılara ASLA
  /// ulaşmaması demekti. Artık başlık başlık bakıyor: olmayanı ekliyor,
  /// olanın metnini güncelliyor.
  ///
  /// [WorkoutProgram.isFavorite] ve is_draft'a dokunulmuyor — biri kullanıcının
  /// tercihi, diğeri satırın kime ait olduğu.
  Future<void> seedWorkoutPrograms() async {
    final db = await dbHelper.database;

    for (final program in _programSeed) {
      final existing = await db.query(
        'WorkoutPrograms',
        columns: ['id'],
        where: 'title = ? AND is_draft = ?',
        whereArgs: [program.title, 0],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('WorkoutPrograms', program.toMap());
        continue;
      }

      await db.update(
        'WorkoutPrograms',
        {
          'tag': program.tag,
          'duration': program.duration,
          'intensity': program.intensity,
          'placeholder_color': program.placeholderColor,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
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

  // --- KİŞİSEL REKORLAR ---

  /// Profil ekranındaki rekor kartı: her hareketin TÜM ZAMANLARDAKİ en iyi
  /// seti, e1RM'e göre sıralanmış ilk [limit] tanesi.
  ///
  /// Neden e1RM ile sıralanıyor: en ağır seti almak "110 kg × 1"i "100 kg × 8"in
  /// önüne koyardı. Neden e1RM gösterilmiyor: o bir tahmin; kartta yazan
  /// ağırlık ve tekrar kullanıcının gerçekten yaptığı settir.
  ///
  /// [getStrengthProgress]'ten farkı bilinçli: orada amaç dönemler arası kıyas
  /// olduğu için yalnızca compound hareketler ve <= [maxRepsForE1rm] tekrarlı
  /// setler sayılır. Burada amaç kullanıcıya kendi en iyisini göstermek, o
  /// yüzden izolasyon hareketleri de girer ve yüksek tekrar elenmez — etkili
  /// tekrar zaten [_maxEffectiveReps] ile sınırlandığı için 30 tekrarlık bir
  /// set şişkin bir rekor üretemez.
  ///
  /// Statik duruşlar dışarıda: tekrarları yok, aynı ölçüyle kıyaslanamazlar.
  Future<List<PersonalRecord>> getPersonalRecords({
    double bodyWeight = 0,
    int limit = 3,
  }) async {
    final db = await dbHelper.database;

    // MAX() tek başına kullanıldığında SQLite, gruptaki diğer sütunları
    // maksimumu üreten SATIRDAN alır. Rekorun ağırlığını, tekrarını ve
    // tarihini bu sayede ikinci bir sorgu olmadan okuyoruz.
    //
    // HAVING, yükü sıfır olan hareketleri eler: ne ağırlık girilmiş ne vücut
    // ağırlığı biniyor (ya da kullanıcı kilosunu hiç kaydetmemiş). Eleme
    // LIMIT'ten önce çalışmalı, yoksa kart boş satırlar yüzünden eksik kalır.
    const String query = '''
      SELECT e.name AS exercise_name,
             ws.weight AS weight,
             ws.reps AS reps,
             e.bodyweight_factor AS bodyweight_factor,
             s.date AS date,
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
      WHERE COALESCE(e.is_static, 0) = 0
        AND ws.reps >= 1
      GROUP BY ws.exercise_id
      HAVING best_e1rm > 0
      ORDER BY best_e1rm DESC
      LIMIT ?
    ''';

    final rows = await db.rawQuery(query, [
      bodyWeight,
      _defaultRpe,
      _maxEffectiveReps,
      _epleyDivisor,
      limit,
    ]);

    return [
      for (final row in rows)
        PersonalRecord(
          exerciseName: row['exercise_name'] as String,
          weight: (row['weight'] as num?)?.toDouble() ?? 0,
          reps: (row['reps'] as num).toInt(),
          date: DateTime.parse(row['date'] as String),
          bodyweightFactor: (row['bodyweight_factor'] as num?)?.toDouble() ?? 0,
          estimatedOneRepMax: (row['best_e1rm'] as num).toDouble(),
        ),
    ];
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

  // Programların içerdiği hareketler.
  //
  // Hareket isimleri ExerciseCatalog ile birebir aynı olmalı; aksi halde
  // kaydedilen setler kas grubu olmayan yeni bir Exercises satırına bağlanır
  // ve kas haritasında görünmez.
  static const Map<String, List<(String name, String sets, String reps)>>
      _programExerciseSeed = {
    // Klasik itiş/çekiş/bacak bölünmesi. Haftada 3 gün (her biri bir kez) ya da
    // 6 gün (ikişer kez) çalışılır; ileri seviyede en yaygın bölünme budur.
    'İtiş Günü': [
      ('Bench Press', '4', '6-8'),
      ('Overhead Press', '4', '8-10'),
      ('Incline Dumbbell Press', '3', '8-12'),
      ('Lateral Raise', '4', '12-15'),
      ('Triceps Pushdown', '3', '10-12'),
      ('Overhead Triceps Extension', '3', '10-12'),
    ],
    'Çekiş Günü': [
      ('Deadlift', '3', '5'),
      ('Pull-Up', '4', '6-10'),
      ('Barbell Row', '4', '8-10'),
      ('Seated Cable Row', '3', '10-12'),
      ('Face Pull', '3', '15-20'),
      ('Barbell Curl', '3', '10-12'),
      ('Hammer Curl', '3', '10-12'),
    ],
    'Bacak Günü': [
      ('Squat', '4', '5-8'),
      ('Romanian Deadlift', '3', '8-10'),
      ('Leg Press', '3', '10-12'),
      ('Leg Curl', '3', '10-12'),
      ('Calf Raise', '4', '12-15'),
      ('Hanging Leg Raise', '3', '12-15'),
    ],
    // Üst/alt bölünmesi: haftada 4 gün antrenman yapanlar için PPL'den daha
    // uygun, çünkü her kas grubu haftada iki kez yük alır.
    'Üst Vücut': [
      ('Bench Press', '4', '6-8'),
      ('Barbell Row', '4', '6-8'),
      ('Overhead Press', '3', '8-10'),
      ('Lat Pulldown', '3', '10-12'),
      ('Lateral Raise', '3', '12-15'),
      ('Barbell Curl', '3', '10-12'),
      ('Skull Crusher', '3', '10-12'),
    ],
    'Alt Vücut': [
      ('Squat', '4', '5-8'),
      ('Romanian Deadlift', '4', '8-10'),
      ('Bulgarian Split Squat', '3', '10-12'),
      ('Leg Curl', '3', '10-12'),
      ('Hip Thrust', '3', '10-12'),
      ('Calf Raise', '4', '15-20'),
    ],
    // Hacim odaklı tek seansta üst vücudun tamamı
    'Power Hypertrophy': [
      ('Bench Press', '4', '6-8'),
      ('Barbell Row', '4', '8-10'),
      ('Incline Dumbbell Press', '3', '8-12'),
      ('Lat Pulldown', '3', '10-12'),
      ('Overhead Press', '3', '8-10'),
      ('Lateral Raise', '3', '12-15'),
      ('Barbell Curl', '3', '10-12'),
      ('Triceps Pushdown', '3', '10-12'),
    ],
    // Düşük tekrar, ağır bileşik hareket; haftada 3 gün, her seansta aynı kalıp
    '5x5 Heavy Barbell': [
      ('Squat', '5', '5'),
      ('Bench Press', '5', '5'),
      ('Barbell Row', '5', '5'),
      ('Overhead Press', '3', '5'),
      ('Deadlift', '1', '5'),
    ],
    // Yeni başlayan için: az hareket, çok tekrar, tüm vücut
    'Tüm Vücut Başlangıç': [
      ('Goblet Squat', '3', '10-12'),
      ('Dumbbell Bench Press', '3', '8-12'),
      ('Seated Cable Row', '3', '10-12'),
      ('Dumbbell Shoulder Press', '3', '10-12'),
      ('Leg Curl', '3', '12-15'),
      ('Plank', '3', '30 sn'),
    ],
    // Ekipmansız: hepsi vücut ağırlığıyla, evde yapılabilir
    'Ev Antrenmanı': [
      ('Push-Up', '4', '10-20'),
      ('Bulgarian Split Squat', '3', '10-15'),
      ('Glute Bridge', '3', '15-20'),
      ('Mountain Climber', '3', '30'),
      ('Superman', '3', '12-15'),
      ('Plank', '3', '45 sn'),
    ],
    // Yüksek tempolu devre; hareketler arası dinlenme kısa
    'Vicious HIIT Shred': [
      ('Jump Rope', '4', '1 dk'),
      ('Burpees', '4', '15-20'),
      ('Mountain Climber', '4', '30'),
      ('Kettlebell Swing', '4', '20'),
      ('Box Jump', '3', '12-15'),
    ],
    // Kısa ve maksimum şiddet: sprint aralıkları
    'Sprint Intervals': [
      ('Jump Rope', '1', '3 dk'),
      ('Treadmill Run', '10', '30 sn'),
      ('High Knees', '3', '20 sn'),
      ('Jumping Jack', '3', '45 sn'),
    ],
    // Sabit tempoda uzun kardiyo
    'Dayanıklılık Koşusu': [
      ('Jump Rope', '1', '5 dk'),
      ('Treadmill Run', '1', '30 dk'),
      ('Stationary Bike', '1', '10 dk'),
    ],
    // Kuvvet ve kardiyoyu birleştiren devre
    'Metabolik Devre': [
      ('Thruster', '5', '12'),
      ('Kettlebell Swing', '5', '20'),
      ('Box Jump', '5', '15'),
      ('Burpees', '5', '12'),
      ('Rowing Machine', '5', '1 dk'),
    ],
    // Toparlanma günü: core dayanıklılığı ve bel sağlığı
    'Deep Core Recovery': [
      ('Plank', '3', '45 sn'),
      ('Side Plank', '3', '30 sn'),
      ('Dead Bug', '3', '12'),
      ('Bird Dog', '3', '12'),
      ('Glute Bridge', '3', '15'),
      ('Superman', '3', '12'),
    ],
  };

  /// Hazır şablonların hareketlerini veritabanına yazar.
  ///
  /// Program ID'leri başlıktan bulunuyor. Eskiden 1/2/4 diye sabit yazılıydı;
  /// AUTOINCREMENT sayaçları kaydığı anda hareketler yanlış programa bağlanır,
  /// foreign key denetimi açıkken de var olmayan ID'ye insert patlardı.
  ///
  /// Hareketler program başına kontrol ediliyor: eskiden ProgramExercises
  /// tablosunda TEK bir satır olması bile bütün tohumlamayı atlatıyordu, bu
  /// yüzden sonradan eklenen programlar boş kalıyordu — "Deep Core Recovery" ve
  /// "Sprint Intervals" kartlarının içi tam olarak bu sebeple boştu.
  Future<void> seedProgramExercises() async {
    final db = await dbHelper.database;

    for (final entry in _programExerciseSeed.entries) {
      final rows = await db.query(
        'WorkoutPrograms',
        columns: ['id'],
        where: 'title = ? AND is_draft = ?',
        whereArgs: [entry.key, 0],
        limit: 1,
      );
      if (rows.isEmpty) continue; // Program yoksa hareketlerini de atla

      final programId = rows.first['id'] as int;

      // Kullanıcı bu programın hareketlerini değiştirmişse üzerine yazmıyoruz
      final existing = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM ProgramExercises WHERE program_id = ?',
        [programId],
      ));
      if (existing != null && existing > 0) continue;

      for (final (name, sets, reps) in entry.value) {
        await db.insert(
            'ProgramExercises',
            ProgramExercise(
                    programId: programId,
                    exerciseName: name,
                    sets: sets,
                    reps: reps)
                .toMap());
      }
    }
  }

  /// Kaydedilen bir antrenmanı kullanıcının kendi şablonuna çevirir
  /// (is_draft = 1) ve oluşan programın id'sini döner.
  ///
  /// Şablon AĞIRLIK TAŞIMAZ: plan "Bench Press, 3 set, 8 tekrar" der, o gün
  /// kaç kilo kaldıracağın antrenman anında girilir. Ağırlık yalnızca
  /// WorkoutSets'te, yani yapılmış antrenmanın kaydında tutulur.
  ///
  /// Aynı hareket seansta birden fazla grupta geçiyorsa şablonda tek satırda
  /// toplanır; plan tarafında "Bench Press 4 set" demek yeterli.
  Future<int> saveSessionAsTemplate({
    required String title,
    required List<WorkoutExerciseState> exercises,
    int durationMinutes = 0,
  }) async {
    final db = await dbHelper.database;

    // Boş satırlar plana girmesin
    final planned = <String, ({int sets, int minReps, int maxReps})>{};
    final difficulties = <int>[];

    for (final exercise in exercises) {
      final filled = exercise.filledSets;
      if (filled.isEmpty) continue;

      final current = planned[exercise.name];
      var sets = current?.sets ?? 0;
      var minReps = current?.minReps ?? 0;
      var maxReps = current?.maxReps ?? 0;

      for (final set in filled) {
        sets++;
        if (set.difficulty > 0) difficulties.add(set.difficulty);
        // Statik hareketlerde tekrar yok; aralık yalnızca girilenlerden
        if (!exercise.isStatic && set.reps > 0) {
          minReps = minReps == 0 ? set.reps : (set.reps < minReps ? set.reps : minReps);
          maxReps = set.reps > maxReps ? set.reps : maxReps;
        }
      }

      planned[exercise.name] = (sets: sets, minReps: minReps, maxReps: maxReps);
    }

    if (planned.isEmpty) {
      throw Exception('Şablona dönüştürülecek bir hareket bulunamadı.');
    }

    return await db.transaction<int>((txn) async {
      final programId = await txn.insert('WorkoutPrograms', {
        'title': title,
        'tag': _dominantCategory(planned.keys),
        'duration': durationMinutes > 0 ? '$durationMinutes dk' : '—',
        'intensity': _intensityFromRpe(difficulties),
        'image_url': '',
        'placeholder_color': 0xFF16181A,
        'is_draft': 1,
        'is_favorite': 0,
      });

      for (final entry in planned.entries) {
        final value = entry.value;
        await txn.insert('ProgramExercises', {
          'program_id': programId,
          'exercise_name': entry.key,
          'sets': value.sets.toString(),
          'reps': _repsLabel(value.minReps, value.maxReps),
        });
      }

      return programId;
    });
  }

  // Katalog şablonlarındaki "5-8" biçimiyle aynı: setler farklıysa aralık,
  // hepsi aynıysa tek sayı. Statik hareketlerde tekrar yok.
  static String _repsLabel(int minReps, int maxReps) {
    if (maxReps == 0) return '—';
    return minReps == maxReps ? '$maxReps' : '$minReps-$maxReps';
  }

  // Şablonun etiketi: en çok hareketi olan kas grubu.
  // Uydurma bir 'STRENGTH' yerine gerçekten yapılan işi anlatır.
  static String _dominantCategory(Iterable<String> exerciseNames) {
    final counts = <String, int>{};
    for (final name in exerciseNames) {
      final category = ExerciseCatalog.categoryOfExercise(name);
      if (category == null) continue;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'ANTRENMAN';

    var best = counts.entries.first;
    for (final entry in counts.entries) {
      if (entry.value > best.value) best = entry;
    }
    return best.key.toUpperCase();
  }

  // Zorluk: girilen RPE'lerin ortalaması. Katalogdaki 'Advanced'/'Beginner'
  // alanının karşılığı, ama burada gerçek veriden geliyor.
  static String _intensityFromRpe(List<int> difficulties) {
    if (difficulties.isEmpty) return 'Kendi Programım';
    final average =
        difficulties.reduce((a, b) => a + b) / difficulties.length;
    if (average <= 6) return 'Hafif';
    if (average <= 8) return 'Orta';
    return 'Zorlu';
  }

  /// Kullanıcının kendi şablonunu siler.
  ///
  /// Yalnızca is_draft = 1 satırları silinebilir; hazır katalog şablonları
  /// bu yoldan kaldırılamaz (onlar favoriden çıkarılır).
  ///
  /// Hareketleri foreign key CASCADE ile birlikte gider, o şablonla yapılmış
  /// antrenmanların program_id'si de SET NULL olur — yani antrenman geçmişi
  /// silinmez, sadece programla bağlantısı kopar.
  Future<bool> deleteUserTemplate(int programId) async {
    final db = await dbHelper.database;
    final deleted = await db.delete(
      'WorkoutPrograms',
      where: 'id = ? AND is_draft = ?',
      whereArgs: [programId, 1],
    );
    return deleted > 0;
  }

  /// Bu başlıkta bir kullanıcı şablonu var mı (aynı isimde ikinci bir
  /// taslak oluşmasın diye).
  Future<bool> templateTitleExists(String title) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'WorkoutPrograms',
      columns: ['id'],
      where: 'title = ? AND is_draft = ?',
      whereArgs: [title, 1],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // "Taslaklarım" listesi: favorilenen hazır şablonlar + kullanıcının
  // kendi oluşturduğu programlar.
  Future<List<WorkoutProgram>> getSavedPrograms() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'WorkoutPrograms',
      where: 'is_favorite = 1 OR is_draft = 1',
    );
    return List.generate(maps.length, (i) => WorkoutProgram.fromMap(maps[i]));
  }

  /// Programı "Taslaklarım"a ekler ya da çıkarır; yeni durumu döner
  /// (true = eklendi, false = kaldırıldı).
  ///
  /// Programın kopyası ÇIKARILMAZ. Eskiden favorileme aynı tabloya is_draft=1
  /// olan bir kopya satırı yazıyordu; bu hem şablonun Antrenman sekmesinde iki
  /// kez görünmesine yol açıyor, hem de favoriden çıkarıldığında satır silindiği
  /// için o programla yapılmış oturumların program_id'sini boşa düşürüyordu.
  Future<bool> toggleFavorite(int programId) async {
    final db = await dbHelper.database;

    final rows = await db.query(
      'WorkoutPrograms',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [programId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final isFavorite = (rows.first['is_favorite'] as int? ?? 0) == 1;
    await db.update(
      'WorkoutPrograms',
      {'is_favorite': isFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [programId],
    );
    return !isFavorite;
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
