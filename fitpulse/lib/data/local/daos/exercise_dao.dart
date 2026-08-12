import '../database_helper.dart';
import '../exercise_catalog.dart';
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

  // Katalogdaki hareketleri veritabanıyla senkronlar (her açılışta güvenle çalışır).
  //
  // Basit "tablo boşsa doldur" mantığı yetmiyor: kullanıcı antrenman kaydettiğinde
  // tanımadığımız bir hareket adı kas bilgisi olmadan tabloya düşebiliyor. Burada
  // eksikleri ekliyor, kas bilgisi boş/eski kalmış satırları da düzeltiyoruz ki
  // kas haritası o setleri kaybetmesin.
  Future<void> seedExerciseCatalog() async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      for (final exercise in ExerciseCatalog.all) {
        // Compound / statik bayrakları katalogdaki tek listeden türetiliyor
        final isCompound = ExerciseCatalog.isCompound(exercise.name) ? 1 : 0;
        final isStatic = ExerciseCatalog.isStatic(exercise.name) ? 1 : 0;

        final existing = await txn.query(
          'Exercises',
          columns: [
            'id',
            'primary_muscle',
            'secondary_muscle',
            'bodyweight_factor',
            'is_compound',
            'is_static'
          ],
          where: 'name = ?',
          whereArgs: [exercise.name],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert('Exercises', {
            ...exercise.toMap(),
            'is_compound': isCompound,
            'is_static': isStatic,
          });
          continue;
        }

        final row = existing.first;
        final needsUpdate = row['primary_muscle'] != exercise.primaryMuscle ||
            row['secondary_muscle'] != exercise.secondaryMuscle ||
            (row['bodyweight_factor'] as num?)?.toDouble() !=
                exercise.bodyweightFactor ||
            row['is_compound'] != isCompound ||
            row['is_static'] != isStatic;

        if (needsUpdate) {
          await txn.update(
            'Exercises',
            {
              'primary_muscle': exercise.primaryMuscle,
              'secondary_muscle': exercise.secondaryMuscle,
              'bodyweight_factor': exercise.bodyweightFactor,
              'is_compound': isCompound,
              'is_static': isStatic,
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    });
  }
}
