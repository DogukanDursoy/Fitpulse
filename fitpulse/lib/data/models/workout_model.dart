import '../local/exercise_catalog.dart';

class WorkoutProgram {
  final int? id;
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  // Kart görselleri ProgramVisuals ile koddan çiziliyor; bu alan eski
  // kayıtlarla uyumluluk için duruyor ve yeni programlarda boş kalıyor.
  final String imageUrl;
  final int placeholderColor;
  // 0 ise sistem şablonu, 1 ise kullanıcının kendi oluşturduğu program
  final int isDraft;

  // Kullanıcı bu programı "Taslaklarım"a kaydetmiş mi.
  // Favorileme programın kopyasını çıkarmaz, sadece bu bayrağı çevirir.
  final int isFavorite;

  WorkoutProgram({
    this.id,
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    this.imageUrl = '',
    required this.placeholderColor,
    this.isDraft = 0, // Varsayılan olarak sistem şablonu (0) kabul ediyoruz
    this.isFavorite = 0,
  });

  bool get isSaved => isFavorite == 1;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'tag': tag,
        'duration': duration,
        'intensity': intensity,
        'image_url': imageUrl,
        'placeholder_color': placeholderColor,
        'is_draft': isDraft,
        'is_favorite': isFavorite,
      };

  factory WorkoutProgram.fromMap(Map<String, dynamic> map) => WorkoutProgram(
        id: map['id'],
        title: map['title'],
        tag: map['tag'],
        duration: map['duration'],
        intensity: map['intensity'],
        imageUrl: map['image_url'] ?? '',
        placeholderColor: map['placeholder_color'],
        isDraft: map['is_draft'] ?? 0,
        isFavorite: map['is_favorite'] ?? 0,
      );
}

class WorkoutSession {
  final int? id;
  final int? programId; // Boş antrenmanlarda program bağlantısı olmayabilir
  final String date;
  final int duration;
  final double totalVolume;
  final int rpeScore;
  final double hybridDifficultyScore;

  WorkoutSession({
    this.id,
    this.programId,
    required this.date,
    required this.duration,
    required this.totalVolume,
    required this.rpeScore,
    required this.hybridDifficultyScore,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'],
        programId: map['program_id'],
        date: map['date'],
        duration: map['duration'] ?? 0,
        totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0,
        rpeScore: map['rpe_score'] ?? 0,
        hybridDifficultyScore:
            (map['hybrid_difficulty_score'] as num?)?.toDouble() ?? 0,
      );
}

// ---------------------------------------------------------
// EKRAN (DRAFT) STATE MODELLERİ
// Antrenman kaydedilmeden önce ActiveWorkoutPage'de tutulan,
// kullanıcı düzenledikçe değişen geçici veri yapısı.
// ---------------------------------------------------------

class WorkoutSetState {
  double weight;
  int reps; // dinamik hareketlerde tekrar
  int seconds; // statik duruşlarda süre
  int difficulty; // RPE (1-10)

  /// Kullanıcı zorluğu gerçekten seçti mi, yoksa varsayılan mı?
  /// Seçilmemiş RPE'yi arayüzde sönük göstermek için kullanılıyor.
  bool difficultyTouched;

  WorkoutSetState({
    this.weight = 0,
    this.reps = 0,
    this.seconds = 0,
    this.difficulty = 8,
    this.difficultyTouched = false,
  });

  // "Akıllı set ekleme": yeni set, bir öncekinin verileriyle başlar
  WorkoutSetState copy() => WorkoutSetState(
        weight: weight,
        reps: reps,
        seconds: seconds,
        difficulty: difficulty,
        difficultyTouched: difficultyTouched,
      );

  /// Statik duruşlarda süre, [ExerciseCatalog.isometricSecondsPerRep] sabitine
  /// bölünerek eşdeğer tekrara çevrilir; böylece hacim aynı birimde kalır.
  double effectiveReps(bool isStatic) => isStatic
      ? seconds / ExerciseCatalog.isometricSecondsPerRep
      : reps.toDouble();

  double volume(bool isStatic) => weight * effectiveReps(isStatic);
}

/// Ana sayfadaki gelişim kartının sonucu.
///
/// [changePercent] null ise kıyaslanacak yeterli veri yok demektir;
/// [hasPreviousData] / [hasCurrentData] hangi dönemin boş olduğunu söyler,
/// böylece kullanıcıya "veri topluyor" mu yoksa "bir süredir antrenman yok" mu
/// diyeceğimizi ayırt edebiliyoruz.
class StrengthProgress {
  final double? changePercent;
  final int comparedLifts;
  final bool hasCurrentData;
  final bool hasPreviousData;

  const StrengthProgress({
    required this.changePercent,
    required this.comparedLifts,
    required this.hasCurrentData,
    required this.hasPreviousData,
  });

  /// Tek harekete dayanan sonuç: gösteriyoruz ama not düşüyoruz
  bool get isLowConfidence => comparedLifts == 1;
}

/// Profildeki "Kişisel Rekorlar" kartının tek satırı.
///
/// Kart TAHMİN GÖSTERMEZ: [estimatedOneRepMax] yalnızca hangi setin rekor
/// sayılacağını seçmek için kullanılır, ekrana yazılan [weight]/[reps] o gün
/// gerçekten yapılmış setin ta kendisidir.
class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  /// Hareketin vücut ağırlığı katsayısı; 0 ise yükün tamamı [weight]'tedir.
  final double bodyweightFactor;

  /// Sıralama ölçütü (RPE düzeltmeli Epley). Ekranda gösterilmez.
  final double estimatedOneRepMax;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
    required this.bodyweightFactor,
    required this.estimatedOneRepMax,
  });

  /// Barfiks, şınav gibi ek yük takılmadan yapılmış set: rekoru kilo değil
  /// tekrar sayısı anlatır.
  bool get isBodyweightOnly => weight <= 0 && bodyweightFactor > 0;
}

class WorkoutExerciseState {
  String name;
  final List<WorkoutSetState> sets;

  WorkoutExerciseState({
    required this.name,
    List<WorkoutSetState>? sets,
  }) : sets = sets ?? [WorkoutSetState()];

  /// Statik duruş mu (Plank, L-Sit, Front Lever): giriş tekrar yerine saniye
  bool get isStatic => ExerciseCatalog.isStatic(name);

  /// Kaydedilmeye değer setler: dinamikte tekrar, statikte saniye girilmiş olanlar
  List<WorkoutSetState> get filledSets =>
      sets.where((set) => isStatic ? set.seconds > 0 : set.reps > 0).toList();
}

/// Kaydedilmiş bir antrenmanın düzenlenebilir hali.
///
/// [exercises] doğrudan ekran modelidir ([WorkoutExerciseState]), böylece
/// düzenleme ekranı yeni antrenman ekranıyla aynı bileşenleri kullanabiliyor.
class SessionDetail {
  final int id;
  final DateTime date;
  final int duration;
  final int? programId;
  final List<WorkoutExerciseState> exercises;

  const SessionDetail({
    required this.id,
    required this.date,
    required this.duration,
    required this.programId,
    required this.exercises,
  });
}

class ProgramExercise {
  final int? id;
  final int
      programId; // Hangi antrenmana ait olduğu (Örn: Power Hypertrophy'nin ID'si)
  final String exerciseName;
  final String sets;
  final String reps;

  ProgramExercise({
    this.id,
    required this.programId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'program_id': programId,
        'exercise_name': exerciseName,
        'sets': sets,
        'reps': reps,
      };

  factory ProgramExercise.fromMap(Map<String, dynamic> map) => ProgramExercise(
        id: map['id'],
        programId: map['program_id'],
        exerciseName: map['exercise_name'],
        sets: map['sets'],
        reps: map['reps'],
      );
}
