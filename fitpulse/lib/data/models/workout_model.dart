class WorkoutProgram {
  final int? id;
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  final String imageUrl;
  final int placeholderColor;
  final int isDraft; // YENİ: 0 ise sistem şablonu, 1 ise kullanıcının taslağı

  WorkoutProgram({
    this.id,
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.imageUrl,
    required this.placeholderColor,
    this.isDraft = 0, // Varsayılan olarak sistem şablonu (0) kabul ediyoruz
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'tag': tag,
        'duration': duration,
        'intensity': intensity,
        'image_url': imageUrl,
        'placeholder_color': placeholderColor,
        'is_draft': isDraft, // YENİ
      };

  factory WorkoutProgram.fromMap(Map<String, dynamic> map) => WorkoutProgram(
        id: map['id'],
        title: map['title'],
        tag: map['tag'],
        duration: map['duration'],
        intensity: map['intensity'],
        imageUrl: map['image_url'],
        placeholderColor: map['placeholder_color'],
        isDraft: map['is_draft'] ?? 0, // YENİ
      );
}

class WorkoutSession {
  final int? id;
  final int programId;
  final String date;
  final int duration;
  final double totalVolume;
  final int rpeScore;
  final double hybridDifficultyScore;

  WorkoutSession({
    this.id,
    required this.programId,
    required this.date,
    required this.duration,
    required this.totalVolume,
    required this.rpeScore,
    required this.hybridDifficultyScore,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'program_id': programId,
        'date': date,
        'duration': duration,
        'total_volume': totalVolume,
        'rpe_score': rpeScore,
        'hybrid_difficulty_score': hybridDifficultyScore,
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'],
        programId: map['program_id'],
        date: map['date'],
        duration: map['duration'],
        totalVolume: map['total_volume'],
        rpeScore: map['rpe_score'],
        hybridDifficultyScore: map['hybrid_difficulty_score'],
      );
}

class WorkoutSet {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;

  WorkoutSet({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
      };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
        id: map['id'],
        sessionId: map['session_id'],
        exerciseId: map['exercise_id'],
        setNumber: map['set_number'],
        reps: map['reps'],
        weight: map['weight'],
      );
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
