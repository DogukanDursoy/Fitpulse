import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
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

  // İSTATİSTİK EKRANI (SVG HARİTASI): Belirli tarihler arası kas hacmi hesaplama
  Future<List<Map<String, dynamic>>> getMuscleVolumes(
      String startDate, String endDate) async {
    final db = await dbHelper.database;

    // SQLite gücü: Setleri, Oturumları ve Egzersizleri birleştirip
    // ağırlık * tekrar formülüyle kaslara binen yükü (tonajı) tek sorguda hesaplıyoruz.
    final String query = '''
      SELECT e.primary_muscle, SUM(ws.reps * ws.weight) as total_volume
      FROM WorkoutSets ws
      JOIN WorkoutSessions s ON ws.session_id = s.id
      JOIN Exercises e ON ws.exercise_id = e.id
      WHERE s.date BETWEEN ? AND ?
      GROUP BY e.primary_muscle
      ORDER BY total_volume DESC
    ''';

    return await db.rawQuery(query, [startDate, endDate]);
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
        ProgramExercise(
                programId: 1,
                exerciseName: 'Barbell Bench Press',
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
  
}
