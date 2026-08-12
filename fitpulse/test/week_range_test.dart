import 'package:flutter_test/flutter_test.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

void main() {
  // Haftalık aktivite küplerinin her pazartesi sıfırlanması ve istatistik
  // ekranındaki hafta navigasyonu tamamen bu fonksiyona bağlı.
  test('hafta her zaman pazartesi 00:00 ile başlar', () {
    for (var i = 0; i < 21; i++) {
      final day = DateTime(2026, 8, 1 + i, 13, 45);
      final start = WorkoutDao.weekStart(day);

      expect(start.weekday, DateTime.monday);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.isAfter(day), isFalse);
      expect(day.difference(start).inDays, lessThan(7));
    }
  });

  test('pazar ile ertesi pazartesi farklı haftalara düşer', () {
    // 2026-08-16 pazar, 2026-08-17 pazartesi
    final sunday = DateTime(2026, 8, 16, 23, 30);
    final monday = DateTime(2026, 8, 17, 0, 30);

    expect(sunday.weekday, DateTime.sunday);
    expect(monday.weekday, DateTime.monday);
    expect(WorkoutDao.weekStart(sunday) == WorkoutDao.weekStart(monday), isFalse);
    expect(
      WorkoutDao.weekStart(monday)
          .difference(WorkoutDao.weekStart(sunday))
          .inDays,
      7,
    );
  });
}
