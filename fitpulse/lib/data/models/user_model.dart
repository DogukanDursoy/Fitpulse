class User {
  final int? id;
  final String name;
  final int age;
  final double height;
  final String experienceLevel;

  User({
    this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.experienceLevel,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'height': height,
        'experience_level': experienceLevel,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        name: map['name'],
        age: map['age'],
        height: map['height'],
        experienceLevel: map['experience_level'],
      );
}

class UserMetricsHistory {
  final int? id;
  final int userId;
  final String date;
  final double weight;
  final double bodyFat;
  final double targetWeight;
  final double targetBodyFat;

  UserMetricsHistory({
    this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.bodyFat,
    required this.targetWeight,
    required this.targetBodyFat,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'weight': weight,
        'body_fat': bodyFat,
        'target_weight': targetWeight,
        'target_body_fat': targetBodyFat,
      };

  factory UserMetricsHistory.fromMap(Map<String, dynamic> map) =>
      UserMetricsHistory(
        id: map['id'],
        userId: map['user_id'],
        date: map['date'],
        weight: map['weight'],
        bodyFat: map['body_fat'],
        targetWeight: map['target_weight'],
        targetBodyFat: map['target_body_fat'],
      );
}
