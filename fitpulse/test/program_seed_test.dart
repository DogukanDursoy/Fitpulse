import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/local/exercise_catalog.dart';

/// Hazır şablonların içeriğini koruyan testler.
///
/// İki kart ("Deep Core Recovery", "Sprint Intervals") uzun süre BOŞ kaldı:
/// karta basınca hiç hareketi olmayan bir antrenman açılıyordu. Sebebi
/// tohumlamanın "ProgramExercises tablosunda tek satır varsa hiçbir şey yapma"
/// mantığıydı. Buradaki testler hem o sınıf hatayı, hem de hareket adlarının
/// katalogdan kaymasını yakalıyor.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const dbName = 'program_seed_test.db';

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

  // Setler hareket ADIYLA Exercises tablosuna bağlanıyor (_resolveExerciseId).
  // Şablondaki bir yazım hatası, katalogda karşılığı olmayan yeni bir satır
  // açar; o hareket kas grubu taşımadığı için haritada ve rekorlarda kaybolur.
  test('şablonlardaki her hareket adı katalogda birebir var', () async {
    final dao = await seededDao();
    final catalog = ExerciseCatalog.all.map((e) => e.name).toSet();

    for (final program in await dao.getAllPrograms()) {
      final exercises = await dao.getExercisesForProgram(program.id!);
      for (final exercise in exercises) {
        expect(catalog, contains(exercise.exerciseName),
            reason: '"${program.title}" -> "${exercise.exerciseName}"');
      }
    }
  });

  test('hiçbir hazır şablon boş değil', () async {
    final dao = await seededDao();
    final programs = await dao.getAllPrograms();

    expect(programs, isNotEmpty);
    for (final program in programs) {
      final exercises = await dao.getExercisesForProgram(program.id!);
      expect(exercises, isNotEmpty,
          reason: '"${program.title}" kartının içi boş');
    }
  });

  test('şablonlar bölgesel, tüm vücut ve kardiyo çeşidini kapsıyor', () async {
    final dao = await seededDao();
    final titles = (await dao.getAllPrograms()).map((p) => p.title).toSet();

    for (final expected in [
      'İtiş Günü',
      'Çekiş Günü',
      'Bacak Günü',
      'Üst Vücut',
      'Alt Vücut',
      'Tüm Vücut Başlangıç',
      'Ev Antrenmanı',
      'Dayanıklılık Koşusu',
      'Metabolik Devre',
    ]) {
      expect(titles, contains(expected));
    }
  });

  test('her etiketten en az bir şablon var', () async {
    final dao = await seededDao();
    final tags = (await dao.getAllPrograms()).map((p) => p.tag).toSet();
    expect(tags, containsAll(['STRENGTH', 'CARDIO', 'FLEXIBILITY']));
  });

  // Tohumlama her açılışta koşuyor; ikinci kez çalışması kartları veya
  // hareketleri ikiye katlamamalı.
  test('tekrar tohumlama program ve hareketleri çoğaltmaz', () async {
    final dao = await seededDao();
    final before = await dao.getAllPrograms();
    final beforeCounts = {
      for (final program in before)
        program.title: (await dao.getExercisesForProgram(program.id!)).length,
    };

    await dao.seedWorkoutPrograms();
    await dao.seedProgramExercises();

    final after = await dao.getAllPrograms();
    expect(after.length, before.length);
    for (final program in after) {
      expect((await dao.getExercisesForProgram(program.id!)).length,
          beforeCounts[program.title],
          reason: program.title);
    }
  });

  // Asıl düzeltilen hata: yeni bir program eklendiğinde, ProgramExercises
  // tablosu zaten dolu olduğu için hareketleri hiç yazılmıyordu.
  test('hareketi olmayan program sonraki tohumlamada dolar', () async {
    final dao = await seededDao();
    final db = await DatabaseHelper.instance.database;

    final program = (await dao.getAllPrograms())
        .firstWhere((p) => p.title == 'Bacak Günü');
    await db.delete('ProgramExercises',
        where: 'program_id = ?', whereArgs: [program.id]);
    expect(await dao.getExercisesForProgram(program.id!), isEmpty);

    await dao.seedProgramExercises();

    expect(await dao.getExercisesForProgram(program.id!), isNotEmpty);
  });

  // Şablon metni koddan yönetiliyor: kodda değişen süre/şiddet cihaza ulaşmalı,
  // ama kullanıcının favori işareti bu güncellemede silinmemeli.
  test('metin güncellenirken favori işareti korunur', () async {
    final dao = await seededDao();
    final program =
        (await dao.getAllPrograms()).firstWhere((p) => p.title == 'Üst Vücut');

    expect(await dao.toggleFavorite(program.id!), isTrue);
    await dao.seedWorkoutPrograms();

    final saved = await dao.getSavedPrograms();
    expect(saved.map((p) => p.title), contains('Üst Vücut'));
  });

  // Kullanıcı şablonu, katalog şablonuyla aynı adı taşısa bile tohumlama
  // onun hareketlerine dokunmamalı.
  test('aynı adlı kullanıcı şablonu tohumlamadan etkilenmez', () async {
    final dao = await seededDao();
    final db = await DatabaseHelper.instance.database;

    final draftId = await db.insert('WorkoutPrograms', {
      'title': 'Bacak Günü',
      'tag': 'BACAK',
      'duration': '20 dk',
      'intensity': 'Hafif',
      'image_url': '',
      'placeholder_color': 0xFF16181A,
      'is_draft': 1,
      'is_favorite': 0,
    });

    await dao.seedWorkoutPrograms();
    await dao.seedProgramExercises();

    expect(await dao.getExercisesForProgram(draftId), isEmpty);
    final draft = (await dao.getSavedPrograms())
        .firstWhere((p) => p.id == draftId);
    expect(draft.duration, '20 dk');
  });

  group('katalog', () {
    // Kardiyo kartları uzun süre yazılamıyordu çünkü katalogda yalnızca iki
    // kardiyo hareketi vardı (Burpees, Jump Rope).
    test('süreyle ölçülen kardiyo hareketleri katalogda', () {
      final names = ExerciseCatalog.all.map((e) => e.name).toSet();
      for (final exercise in ExerciseCatalog.timedCardio) {
        expect(names, contains(exercise), reason: '"$exercise" katalogda yok');
      }
    });

    // Süreyle ölçülen hareketlerde saniye, eşdeğer tekrara çevrilip vücut
    // ağırlığıyla çarpılıyor. 30 dakikalık bir koşu 600 eşdeğer tekrar eder;
    // katsayı sıfırdan büyük olsaydı kas haritasını tek başına ele geçirirdi.
    test('kardiyo hareketleri kas haritasına hacim yazmaz', () {
      for (final exercise in ExerciseCatalog.all) {
        if (!ExerciseCatalog.timedCardio.contains(exercise.name)) continue;
        expect(exercise.bodyweightFactor, 0, reason: exercise.name);
      }
    });

    test('süreyle ölçülen her hareket statik işaretli', () {
      for (final exercise in ExerciseCatalog.durationBased) {
        expect(ExerciseCatalog.isStatic(exercise), isTrue, reason: exercise);
      }
    });
  });
}
