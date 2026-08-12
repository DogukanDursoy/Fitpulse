import '../models/exercise_model.dart';

/// Uygulamanın tek kanonik kas sözlüğü.
///
/// Buradaki isimler hem Exercises tablosundaki primary/secondary_muscle
/// sütunlarında, hem de SVG kas haritasının boyanmasında kullanılır.
/// Yeni bir kas grubu eklenecekse önce buraya, sonra [MuscleGroups.svgPaths]
/// tablosuna eklenmeli — aksi halde harita o kası boyayamaz.
abstract class Muscles {
  static const chest = 'Göğüs';
  static const frontDelt = 'Ön Omuz';
  static const rearDelt = 'Arka Omuz';
  static const traps = 'Trapez';
  static const lats = 'Kanat';
  static const upperBack = 'Üst Sırt';
  static const lowerBack = 'Bel';
  static const biceps = 'Pazı';
  static const triceps = 'Arka Kol';
  static const forearm = 'Ön Kol';
  static const abs = 'Karın';
  static const obliques = 'Yan Karın';
  static const quads = 'Ön Bacak';
  static const hamstrings = 'Arka Bacak';
  static const glutes = 'Kalça';
  static const calves = 'Kalf';
  static const adductors = 'İç Bacak';
  static const neck = 'Boyun';
}

abstract class MuscleGroups {
  /// Kas grubu -> anatomy_muscle_map_v5.svg içindeki path id'leri.
  static const Map<String, List<String>> svgPaths = {
    Muscles.chest: ['front-chest-left', 'front-chest-right'],
    Muscles.frontDelt: ['front-deltoid-left', 'front-deltoid-right'],
    Muscles.rearDelt: ['back-rear-deltoid-left', 'back-rear-deltoid-right'],
    Muscles.traps: [
      'front-trapezius-left',
      'front-trapezius-right',
      'back-trapezius-left',
      'back-trapezius-right',
    ],
    Muscles.lats: ['back-lats-left', 'back-lats-right'],
    Muscles.upperBack: ['back-upper-back-left', 'back-upper-back-right'],
    Muscles.lowerBack: ['back-lower-back-left', 'back-lower-back-right'],
    Muscles.biceps: ['front-biceps-left', 'front-biceps-right'],
    Muscles.triceps: ['back-triceps-left', 'back-triceps-right'],
    Muscles.forearm: [
      'front-forearm-left',
      'front-forearm-right',
      'back-forearm-left',
      'back-forearm-right',
    ],
    Muscles.abs: [
      'front-abs-1-left',
      'front-abs-1-right',
      'front-abs-2-left',
      'front-abs-2-right',
      'front-abs-3-left',
      'front-abs-3-right',
      'front-abs-4-left',
      'front-abs-4-right',
    ],
    Muscles.obliques: [
      'front-obliques-left',
      'front-obliques-right',
      'front-serratus-left',
      'front-serratus-right',
    ],
    Muscles.quads: [
      'front-quadriceps-left',
      'front-quadriceps-right',
      'front-vastus-medialis-left',
      'front-vastus-medialis-right',
    ],
    Muscles.hamstrings: [
      'back-hamstring-inner-left',
      'back-hamstring-inner-right',
      'back-hamstring-outer-left',
      'back-hamstring-outer-right',
    ],
    Muscles.glutes: ['back-glutes-left', 'back-glutes-right'],
    Muscles.calves: [
      'back-calves-inner-left',
      'back-calves-inner-right',
      'back-calves-outer-left',
      'back-calves-outer-right',
    ],
    Muscles.adductors: ['front-adductors-left', 'front-adductors-right'],
    Muscles.neck: ['front-neck', 'back-neck'],
  };

  /// Hareket seçici sayfadaki filtre sekmeleri
  static const List<String> categories = [
    'Tümü',
    'Göğüs',
    'Sırt',
    'Omuz',
    'Kol',
    'Bacak',
    'Core',
  ];

  static const Map<String, String> _categoryOfMuscle = {
    Muscles.chest: 'Göğüs',
    Muscles.lats: 'Sırt',
    Muscles.upperBack: 'Sırt',
    Muscles.lowerBack: 'Sırt',
    Muscles.traps: 'Sırt',
    Muscles.frontDelt: 'Omuz',
    Muscles.rearDelt: 'Omuz',
    Muscles.biceps: 'Kol',
    Muscles.triceps: 'Kol',
    Muscles.forearm: 'Kol',
    Muscles.quads: 'Bacak',
    Muscles.hamstrings: 'Bacak',
    Muscles.glutes: 'Bacak',
    Muscles.calves: 'Bacak',
    Muscles.adductors: 'Bacak',
    Muscles.abs: 'Core',
    Muscles.obliques: 'Core',
    Muscles.neck: 'Omuz',
  };

  static String categoryOf(String primaryMuscle) =>
      _categoryOfMuscle[primaryMuscle] ?? 'Diğer';
}

/// Uygulamanın hareket kataloğu.
///
/// Hem hareket seçici sayfayı besleyen, hem de Exercises tablosuna tohumlanan
/// TEK liste burasıdır. Daha önce seçici sayfadaki liste ile veritabanındaki
/// liste ayrıydı ve isimler tutmadığı için kaydedilen setler kas grubuna
/// bağlanamıyordu.
///
/// [Exercise.bodyweightFactor]: vücut ağırlığının ne kadarının kaldırıldığı.
/// Barbell/dumbbell hareketlerinde 0'dır (yükün tamamı zaten giriliyor).
/// Kalibrasyon kaba bir literatür ortalamasıdır ve veritabanı sütununda
/// tutulduğu için sonradan tek yerden ayarlanabilir.
abstract class ExerciseCatalog {
  /// Gelişim oranı (e1RM) hesabına giren hareketler.
  ///
  /// Kriter: çok eklemli, kilosu artırılabilir, teknik/denge baskın değil ve
  /// ağır tekrar aralığında çalışılıyor. İzolasyon hareketleri (2.5 kg'lık
  /// artışlar yüzde olarak çok oynak), statik/core hareketleri ve beceri
  /// baskın hareketler (Muscle-Up, Handstand Push-Up, Front Lever) dışarıda.
  static const Set<String> compoundLifts = {
    // İtiş
    'Bench Press',
    'Incline Barbell Press',
    'Incline Dumbbell Press',
    'Dumbbell Bench Press',
    'Close-Grip Bench Press',
    'Weighted Dips',
    'Overhead Press',
    'Arnold Press',
    'Push-Up',
    // Çekiş
    'Deadlift',
    'Sumo Deadlift',
    'Romanian Deadlift',
    'Good Morning',
    'Barbell Row',
    'Dumbbell Row',
    'T-Bar Row',
    'Seated Cable Row',
    'Lat Pulldown',
    'Pull-Up',
    'Pull-Up (Ağırlıklı)',
    'Chin-Up',
    // Bacak
    'Squat',
    'Front Squat',
    'Leg Press',
    'Bulgarian Split Squat',
    'Walking Lunge',
    'Hip Thrust',
  };

  static bool isCompound(String exerciseName) =>
      compoundLifts.contains(exerciseName);

  /// Statik (izometrik) duruşlar: tekrar yerine SANİYE ile kaydedilir.
  ///
  /// Dragon Flag listede değil çünkü tipik olarak kontrollü indirişlerle
  /// tekrar bazlı çalışılır.
  static const Set<String> staticHolds = {
    'Plank',
    'L-Sit',
    'Front Lever',
    'Jump Rope', // süreyle kaydedilir (şablonda da "1 Min" olarak geçiyor)
  };

  static bool isStatic(String exerciseName) =>
      staticHolds.contains(exerciseName);

  /// Hareketin katalogdaki kas grubu kategorisi ('Göğüs', 'Bacak' ...).
  /// Katalogda olmayan hareketlerde `null` döner.
  static String? categoryOfExercise(String exerciseName) {
    for (final exercise in all) {
      if (exercise.name == exerciseName) {
        return MuscleGroups.categoryOf(exercise.primaryMuscle);
      }
    }
    return null;
  }

  /// İzometrik sürenin tekrar karşılığı: kontrollü bir tekrar gerilim altında
  /// tipik olarak ~3 saniye sürer. Hacim hesabında saniye bu sabite bölünerek
  /// "eşdeğer tekrar"a çevrilir, böylece statik ve dinamik setler aynı
  /// birimde (kg) toplanabilir.
  static const double isometricSecondsPerRep = 3.0;

  static const List<Exercise> all = [
    // --- GÖĞÜS ---
    Exercise(
        name: 'Bench Press',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.triceps),
    Exercise(
        name: 'Incline Barbell Press',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.frontDelt),
    Exercise(
        name: 'Incline Dumbbell Press',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.frontDelt),
    Exercise(
        name: 'Dumbbell Bench Press',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.triceps),
    Exercise(
        name: 'Cable Fly',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.frontDelt),
    Exercise(
        name: 'Push-Up',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.triceps,
        bodyweightFactor: 0.64),
    Exercise(
        name: 'Weighted Dips',
        primaryMuscle: Muscles.chest,
        secondaryMuscle: Muscles.triceps,
        bodyweightFactor: 0.95),

    // --- SIRT ---
    Exercise(
        name: 'Deadlift',
        primaryMuscle: Muscles.lowerBack,
        secondaryMuscle: Muscles.hamstrings),
    Exercise(
        name: 'Barbell Row',
        primaryMuscle: Muscles.upperBack,
        secondaryMuscle: Muscles.lats),
    Exercise(
        name: 'Dumbbell Row',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.upperBack),
    Exercise(
        name: 'T-Bar Row',
        primaryMuscle: Muscles.upperBack,
        secondaryMuscle: Muscles.lats),
    Exercise(
        name: 'Seated Cable Row',
        primaryMuscle: Muscles.upperBack,
        secondaryMuscle: Muscles.biceps),
    Exercise(
        name: 'Lat Pulldown',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.biceps),
    Exercise(
        name: 'Pull-Up',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.biceps,
        bodyweightFactor: 1.0),
    Exercise(
        name: 'Pull-Up (Ağırlıklı)',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.biceps,
        bodyweightFactor: 1.0),
    Exercise(
        name: 'Chin-Up',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.biceps,
        bodyweightFactor: 1.0),
    Exercise(
        name: 'Muscle-Up',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.triceps,
        bodyweightFactor: 1.0),
    // Statik hareket: "tekrar" alanının saniye mi tekrar mı olduğunu sonra netleştireceğiz
    Exercise(
        name: 'Front Lever',
        primaryMuscle: Muscles.lats,
        secondaryMuscle: Muscles.abs,
        bodyweightFactor: 1.0),
    Exercise(
        name: 'Face Pull',
        primaryMuscle: Muscles.rearDelt,
        secondaryMuscle: Muscles.traps),
    Exercise(
        name: 'Shrug',
        primaryMuscle: Muscles.traps,
        secondaryMuscle: Muscles.forearm),
    Exercise(
        name: 'Back Extension',
        primaryMuscle: Muscles.lowerBack,
        secondaryMuscle: Muscles.glutes,
        bodyweightFactor: 0.5),
    Exercise(
        name: 'Good Morning',
        primaryMuscle: Muscles.lowerBack,
        secondaryMuscle: Muscles.hamstrings),

    // --- OMUZ ---
    Exercise(
        name: 'Overhead Press',
        primaryMuscle: Muscles.frontDelt,
        secondaryMuscle: Muscles.triceps),
    Exercise(
        name: 'Arnold Press',
        primaryMuscle: Muscles.frontDelt,
        secondaryMuscle: Muscles.triceps),
    Exercise(
        name: 'Lateral Raise',
        primaryMuscle: Muscles.frontDelt,
        secondaryMuscle: Muscles.traps),
    Exercise(
        name: 'Rear Delt Fly',
        primaryMuscle: Muscles.rearDelt,
        secondaryMuscle: Muscles.upperBack),
    Exercise(
        name: 'Upright Row',
        primaryMuscle: Muscles.traps,
        secondaryMuscle: Muscles.frontDelt),
    Exercise(
        name: 'Handstand Push-Up',
        primaryMuscle: Muscles.frontDelt,
        secondaryMuscle: Muscles.triceps,
        bodyweightFactor: 0.9),

    // --- KOL ---
    Exercise(
        name: 'Barbell Curl',
        primaryMuscle: Muscles.biceps,
        secondaryMuscle: Muscles.forearm),
    Exercise(
        name: 'Dumbbell Curl',
        primaryMuscle: Muscles.biceps,
        secondaryMuscle: Muscles.forearm),
    Exercise(
        name: 'Hammer Curl',
        primaryMuscle: Muscles.forearm,
        secondaryMuscle: Muscles.biceps),
    Exercise(
        name: 'Preacher Curl',
        primaryMuscle: Muscles.biceps,
        secondaryMuscle: Muscles.forearm),
    Exercise(
        name: 'Triceps Pushdown',
        primaryMuscle: Muscles.triceps,
        secondaryMuscle: ''),
    Exercise(
        name: 'Skull Crusher',
        primaryMuscle: Muscles.triceps,
        secondaryMuscle: ''),
    Exercise(
        name: 'Close-Grip Bench Press',
        primaryMuscle: Muscles.triceps,
        secondaryMuscle: Muscles.chest),
    Exercise(
        name: 'Wrist Curl',
        primaryMuscle: Muscles.forearm,
        secondaryMuscle: ''),

    // --- BACAK ---
    Exercise(
        name: 'Squat',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.glutes),
    Exercise(
        name: 'Front Squat',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.abs),
    Exercise(
        name: 'Leg Press',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.glutes),
    Exercise(
        name: 'Leg Extension',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: ''),
    // Tek bacak üzerinde çalışıldığı için vücut ağırlığının çoğu tek tarafa biner
    Exercise(
        name: 'Bulgarian Split Squat',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.glutes,
        bodyweightFactor: 0.7),
    Exercise(
        name: 'Walking Lunge',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.glutes,
        bodyweightFactor: 0.7),
    Exercise(
        name: 'Romanian Deadlift',
        primaryMuscle: Muscles.hamstrings,
        secondaryMuscle: Muscles.glutes),
    Exercise(
        name: 'Leg Curl',
        primaryMuscle: Muscles.hamstrings,
        secondaryMuscle: Muscles.calves),
    Exercise(
        name: 'Hip Thrust',
        primaryMuscle: Muscles.glutes,
        secondaryMuscle: Muscles.hamstrings),
    Exercise(
        name: 'Sumo Deadlift',
        primaryMuscle: Muscles.glutes,
        secondaryMuscle: Muscles.adductors),
    Exercise(
        name: 'Calf Raise',
        primaryMuscle: Muscles.calves,
        secondaryMuscle: ''),
    Exercise(
        name: 'Seated Calf Raise',
        primaryMuscle: Muscles.calves,
        secondaryMuscle: ''),

    // --- CORE ---
    // Plank / L-Sit / Dragon Flag statik hareketler; süre-tekrar ayrımı sonraki konu
    Exercise(
        name: 'Plank',
        primaryMuscle: Muscles.abs,
        secondaryMuscle: Muscles.obliques,
        bodyweightFactor: 0.6),
    Exercise(
        name: 'Hanging Leg Raise',
        primaryMuscle: Muscles.abs,
        secondaryMuscle: Muscles.obliques,
        bodyweightFactor: 0.5),
    Exercise(
        name: 'Cable Crunch',
        primaryMuscle: Muscles.abs,
        secondaryMuscle: ''),
    Exercise(
        name: 'L-Sit',
        primaryMuscle: Muscles.abs,
        secondaryMuscle: Muscles.quads,
        bodyweightFactor: 0.55),
    Exercise(
        name: 'Dragon Flag',
        primaryMuscle: Muscles.abs,
        secondaryMuscle: Muscles.lowerBack,
        bodyweightFactor: 0.6),
    Exercise(
        name: 'Russian Twist',
        primaryMuscle: Muscles.obliques,
        secondaryMuscle: Muscles.abs),

    // --- KARDİYO ---
    // Hazır şablonlarda geçtikleri için katalogda olmaları gerekiyor; aksi halde
    // kaydedilirken kas grubu olmayan satırlar açılıyor ve haritada kayboluyorlar.
    Exercise(
        name: 'Burpees',
        primaryMuscle: Muscles.quads,
        secondaryMuscle: Muscles.chest,
        bodyweightFactor: 0.7),
    Exercise(
        name: 'Jump Rope',
        primaryMuscle: Muscles.calves,
        secondaryMuscle: ''),
  ];
}
