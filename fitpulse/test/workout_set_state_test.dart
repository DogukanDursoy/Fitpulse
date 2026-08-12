import 'package:flutter_test/flutter_test.dart';
import 'package:fitpulse/data/models/workout_model.dart';

void main() {
  group('statik duruşlar', () {
    test('saniye eşdeğer tekrara çevrilir (3 sn = 1 tekrar)', () {
      final set = WorkoutSetState(weight: 48, seconds: 60);
      expect(set.effectiveReps(true), 20);
      // 60 sn plank, 48 kg efektif yük -> 960 kg hacim:
      // bir bench setiyle (100x10 = 1000) aynı ölçekte kalıyor
      expect(set.volume(true), 960);
    });

    test('statik hareket saniyesi girilene kadar kayda girmez', () {
      final plank = WorkoutExerciseState(
        name: 'Plank',
        sets: [WorkoutSetState(reps: 12), WorkoutSetState(seconds: 45)],
      );
      expect(plank.isStatic, isTrue);
      // Hareket değiştirildiğinde geride kalan tekrar değeri sayılmamalı
      expect(plank.filledSets.length, 1);
      expect(plank.filledSets.single.seconds, 45);
    });

    test('dinamik hareket saniyeye değil tekrara bakar', () {
      final bench = WorkoutExerciseState(
        name: 'Bench Press',
        sets: [WorkoutSetState(weight: 100, reps: 10), WorkoutSetState(seconds: 30)],
      );
      expect(bench.isStatic, isFalse);
      expect(bench.filledSets.length, 1);
      expect(bench.filledSets.single.volume(false), 1000);
    });
  });

  test('akıllı set ekleme RPE seçimini de taşır', () {
    final set = WorkoutSetState(
        weight: 100, reps: 5, difficulty: 9, difficultyTouched: true);
    final copy = set.copy();

    expect(copy.weight, 100);
    expect(copy.reps, 5);
    expect(copy.difficulty, 9);
    expect(copy.difficultyTouched, isTrue);

    // Kopya bağımsız olmalı
    copy.reps = 8;
    expect(set.reps, 5);
  });

  test('varsayılan RPE dokunulmamış sayılır', () {
    expect(WorkoutSetState().difficulty, 8);
    expect(WorkoutSetState().difficultyTouched, isFalse);
  });
}
