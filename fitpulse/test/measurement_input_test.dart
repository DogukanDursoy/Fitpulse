import 'package:flutter_test/flutter_test.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';

void main() {
  group('parseDecimalInput', () {
    // Asıl hata buydu: Türkçe klavyede ondalık ayırıcı virgül, `double.tryParse`
    // ise virgülü çözemeyip null dönüyordu. Çağrı yerindeki `?? 0` da bunu
    // sessizce 0 kg'a çevirip kilo geçmişine yazıyordu.
    test('virgüllü ondalık girdiyi çözer', () {
      expect(parseDecimalInput('72,5'), 72.5);
      expect(parseDecimalInput('72.5'), 72.5);
      expect(parseDecimalInput(' 72,5 '), 72.5);
    });

    test('çözülemeyen girdide varsayılana düşmez, null döner', () {
      for (final input in ['', '   ', 'abc', '72,5,3', '--8', null]) {
        expect(parseDecimalInput(input), isNull, reason: 'girdi: $input');
      }
    });

    test('sonsuz ve NaN kabul edilmez', () {
      expect(parseDecimalInput('Infinity'), isNull);
      expect(parseDecimalInput('NaN'), isNull);
    });
  });

  group('parseWeightKg', () {
    test('makul kiloları kabul eder', () {
      expect(parseWeightKg('75'), 75);
      expect(parseWeightKg('72,5'), 72.5);
      expect(parseWeightKg('20'), minWeightKg);
      expect(parseWeightKg('400'), maxWeightKg);
    });

    // 0 kg FORM kartını, vücut ağırlıklı hacim hesabını ve barfiks/dips
    // e1RM'ini topluca bozuyordu; artık kayda hiç ulaşamıyor.
    test('sıfır, eksi ve saçma değerleri reddeder', () {
      for (final input in ['0', '-70', '5', '750', '1000']) {
        expect(parseWeightKg(input), isNull, reason: 'girdi: $input');
      }
    });
  });

  group('parseHeightCm', () {
    test('makul boyları kabul eder', () {
      expect(parseHeightCm('175'), 175);
      expect(parseHeightCm('180,5'), 180.5);
    });

    test('aralık dışını reddeder', () {
      expect(parseHeightCm('0'), isNull);
      expect(parseHeightCm('50'), isNull);
      expect(parseHeightCm('300'), isNull);
    });
  });

  group('parseWeeklyGoal', () {
    test('haftada 1-7 gün kabul edilir', () {
      expect(parseWeeklyGoal('1'), 1);
      expect(parseWeeklyGoal('4'), 4);
      expect(parseWeeklyGoal('7'), 7);
    });

    test('sıfır, aralık dışı ve ondalık reddedilir', () {
      for (final input in ['0', '8', '30', '3,5', '-2']) {
        expect(parseWeeklyGoal(input), isNull, reason: 'girdi: $input');
      }
    });
  });

  group('doğrulayıcılar', () {
    test('geçerli girdide hata mesajı üretmez', () {
      expect(validateWeight('72,5'), isNull);
      expect(validateHeight('175'), isNull);
      expect(validateWeeklyGoal('4'), isNull);
    });

    test('geçersiz girdide hata mesajı üretir', () {
      expect(validateWeight('0'), isNotNull);
      expect(validateWeight(''), isNotNull);
      expect(validateHeight('abc'), isNotNull);
      expect(validateWeeklyGoal('9'), isNotNull);
    });

    // Hedef kilo isteğe bağlı: boşsa form kartı hedefsiz moda düşer,
    // ama DOLU ve geçersizse kaydedilmemeli.
    test('hedef kilo boş bırakılabilir ama geçersiz olamaz', () {
      expect(validateOptionalTargetWeight(''), isNull);
      expect(validateOptionalTargetWeight(null), isNull);
      expect(validateOptionalTargetWeight('68'), isNull);
      expect(validateOptionalTargetWeight('0'), isNotNull);
    });
  });

  group('formatMeasurement', () {
    // SharedPreferences'a yazılan metin her zaman geri okunabilir olmalı;
    // virgüllü girdi noktalı biçimde saklanır.
    test('tam sayıda ondalık kuyruk bırakmaz', () {
      expect(formatMeasurement(75), '75');
      expect(formatMeasurement(72.5), '72.5');
    });

    test('yazılan değer geri okunabilir', () {
      for (final input in ['72,5', '75', '80.25']) {
        final parsed = parseWeightKg(input)!;
        expect(parseWeightKg(formatMeasurement(parsed)), parsed);
      }
    });
  });
}
