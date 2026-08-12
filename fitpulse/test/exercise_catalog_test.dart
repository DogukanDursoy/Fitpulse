import 'package:flutter_test/flutter_test.dart';
import 'package:fitpulse/data/local/exercise_catalog.dart';

void main() {
  test('katalogda aynı isimde iki hareket yok', () {
    final names = ExerciseCatalog.all.map((e) => e.name).toList();
    expect(names.length, names.toSet().length);
  });

  // Compound listesi isimle eşleştiği için tek harflik bir yazım hatası
  // hareketi sessizce gelişim hesabının dışında bırakır.
  test('compound listesindeki her isim katalogda mevcut', () {
    final names = ExerciseCatalog.all.map((e) => e.name).toSet();
    for (final lift in ExerciseCatalog.compoundLifts) {
      expect(names, contains(lift), reason: '"$lift" katalogda yok');
    }
  });

  // Haritada boyanamayan bir kas adı, o hareketin hacmini görünmez yapar.
  test('katalogdaki her kas adı SVG eşleştirme tablosunda var', () {
    final known = MuscleGroups.svgPaths.keys.toSet();
    for (final exercise in ExerciseCatalog.all) {
      expect(known, contains(exercise.primaryMuscle),
          reason: '${exercise.name} -> ${exercise.primaryMuscle}');
      if (exercise.secondaryMuscle.isNotEmpty) {
        expect(known, contains(exercise.secondaryMuscle),
            reason: '${exercise.name} -> ${exercise.secondaryMuscle}');
      }
    }
  });

  test('her kas grubunun bir filtre kategorisi var', () {
    for (final muscle in MuscleGroups.svgPaths.keys) {
      expect(MuscleGroups.categoryOf(muscle), isNot('Diğer'),
          reason: '$muscle hiçbir kategoriye bağlı değil');
    }
  });

  test('statik listesindeki her isim katalogda mevcut', () {
    final names = ExerciseCatalog.all.map((e) => e.name).toSet();
    for (final hold in ExerciseCatalog.staticHolds) {
      expect(names, contains(hold), reason: '"$hold" katalogda yok');
    }
  });

  // Statik hareket compound sayılsaydı e1RM'i tekrar sütununa bakardı ve
  // tekrar sütunu statik setlerde NULL olduğu için sessizce kaybolurdu.
  test('statik hareketler compound listesinde değil', () {
    for (final hold in ExerciseCatalog.staticHolds) {
      expect(ExerciseCatalog.compoundLifts, isNot(contains(hold)));
    }
  });

  test('vücut ağırlığı katsayıları makul aralıkta', () {
    for (final exercise in ExerciseCatalog.all) {
      expect(exercise.bodyweightFactor, inInclusiveRange(0, 1),
          reason: exercise.name);
    }
  });
}
