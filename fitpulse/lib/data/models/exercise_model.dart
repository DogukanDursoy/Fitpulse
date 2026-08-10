class Exercise {
  final int? id;
  final String name;
  final String primaryMuscle;
  final String secondaryMuscle;

  Exercise({
    this.id,
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'primary_muscle': primaryMuscle,
        'secondary_muscle': secondaryMuscle,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'],
        name: map['name'],
        primaryMuscle: map['primary_muscle'],
        secondaryMuscle: map['secondary_muscle'],
      );
}
