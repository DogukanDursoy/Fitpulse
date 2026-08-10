import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/exercise_model.dart';

class ExerciseDao {
  final dbHelper = DatabaseHelper.instance;

  // Yeni bir egzersiz ekleme (Kullanıcı kendi özel hareketini eklemek isterse)
  Future<int> insertExercise(Exercise exercise) async {
    final db = await dbHelper.database;
    return await db.insert('Exercises', exercise.toMap());
  }

  // Tüm egzersizleri alfabetik olarak listeleme (Antrenman sırasında hareket seçmek için)
  Future<List<Exercise>> getAllExercises() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('Exercises', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  // Uygulama ilk kurulduğunda veritabanını temel hareketlerle doldurma (Seed Data)
  Future<void> insertDefaultExercises() async {
    final db = await dbHelper.database;

    // Eğer veritabanında zaten hareket varsa ekleme yapma (Uygulama her açıldığında çift kayıt olmasın diye)
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Exercises'));
    if (count != null && count > 0) return;

    final List<Exercise> defaultExercises = [
      // Push (İtiş)
      Exercise(
          name: 'Bench Press',
          primaryMuscle: 'Göğüs',
          secondaryMuscle: 'Ön Omuz'),
      Exercise(
          name: 'Overhead Press',
          primaryMuscle: 'Ön Omuz',
          secondaryMuscle: 'Arka Kol'),
      Exercise(
          name: 'Dips',
          primaryMuscle: 'Alt Göğüs',
          secondaryMuscle: 'Arka Kol'),

      // Pull (Çekiş)
      Exercise(name: 'Pull-up', primaryMuscle: 'Sırt', secondaryMuscle: 'Pazı'),
      Exercise(
          name: 'Barbell Row',
          primaryMuscle: 'Sırt',
          secondaryMuscle: 'Arka Omuz'),
      Exercise(
          name: 'Face Pull',
          primaryMuscle: 'Arka Omuz',
          secondaryMuscle: 'Trapez'),

      // Legs (Bacak)
      Exercise(
          name: 'Squat', primaryMuscle: 'Ön Bacak', secondaryMuscle: 'Kalça'),
      Exercise(
          name: 'Romanian Deadlift',
          primaryMuscle: 'Arka Bacak',
          secondaryMuscle: 'Kalça'),
      Exercise(name: 'Calf Raise', primaryMuscle: 'Kalf', secondaryMuscle: ''),
    ];

    for (var exercise in defaultExercises) {
      await db.insert('Exercises', exercise.toMap());
    }
  }
}
