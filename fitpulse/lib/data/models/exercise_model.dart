class Exercise {
  final int? id;
  final String name;
  final String primaryMuscle;
  final String secondaryMuscle;

  /// Harekette vücut ağırlığının ne kadarının kaldırıldığı (0 = tamamen dış yük).
  ///
  /// Hacim hesabı `tekrar * (girilen kilo + katsayı * vücut ağırlığı)` şeklinde
  /// yapılır; böylece barfiks gibi hareketler 0 kg girilse de yük üretir,
  /// ağırlıklı yapıldığında ise ek yük vücut ağırlığının üzerine eklenir.
  final double bodyweightFactor;

  const Exercise({
    this.id,
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscle,
    this.bodyweightFactor = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'primary_muscle': primaryMuscle,
        'secondary_muscle': secondaryMuscle,
        'bodyweight_factor': bodyweightFactor,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'],
        name: map['name'],
        primaryMuscle: map['primary_muscle'],
        secondaryMuscle: map['secondary_muscle'],
        bodyweightFactor:
            (map['bodyweight_factor'] as num?)?.toDouble() ?? 0,
      );
}
