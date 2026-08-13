import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/core/theme/program_visuals.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

/// Görsel katmanının ağdan koptuğunu doğrular.
///
/// Kart görselleri Unsplash CDN'ine, avatarlar da api.dicebear.com'a doğrudan
/// link veriyordu. Release build'de INTERNET izni olmadığı için hiçbiri
/// yüklenmiyordu; kullanıcının kendi şablonlarında image_url boş kaldığı için
/// de detay sayfası çöküyordu. Artık ikisi de koddan çiziliyor.
///
/// Bu testler bilerek widget çizmiyor: sqflite'ın gerçek async G/Ç'si Flutter'ın
/// sahte test saatiyle uyuşmuyor ve pumpAndSettle sonsuz dönen bir spinner'da
/// 10 dakika bekliyor. Kontrol edilecek mantık zaten saf fonksiyonlarda.
void main() {
  group('program görselleri', () {
    test('her etiket için gradyan ve ikon üretilir', () {
      const tags = [
        'STRENGTH',
        'CARDIO',
        'FLEXIBILITY',
        // Kullanıcı şablonlarının kas grubu etiketleri
        'GÖĞÜS',
        'SIRT',
        'OMUZ',
        'KOL',
        'BACAK',
        'CORE',
      ];
      for (final tag in tags) {
        expect(ProgramVisuals.gradient(tag).colors, hasLength(2),
            reason: '$tag için gradyan yok');
        expect(ProgramVisuals.icon(tag), isA<IconData>());
      }
    });

    test('tanınmayan etiket varsayılana düşer, çökmez', () {
      for (final tag in ['', 'ANTRENMAN', 'bilinmeyen', 'çok garip bir tag']) {
        expect(ProgramVisuals.gradient(tag).colors, hasLength(2));
        expect(ProgramVisuals.icon(tag), isA<IconData>());
      }
    });

    test('etiket büyük/küçük harften bağımsız çözülür', () {
      expect(ProgramVisuals.icon('strength'), ProgramVisuals.icon('STRENGTH'));
      expect(ProgramVisuals.icon('Bacak'), ProgramVisuals.icon('BACAK'));
    });
  });

  group('kullanıcı avatarı', () {
    test('baş harfler isimden türetilir', () {
      expect(UserAvatar.initialsFor('Doğukan'), 'D');
      expect(UserAvatar.initialsFor('Doğukan Dursoy'), 'DD');
      expect(UserAvatar.initialsFor('  ali  veli  '), 'AV');
      expect(UserAvatar.initialsFor('Şampiyon'), 'Ş');
    });

    test('boş isim çökmez', () {
      expect(UserAvatar.initialsFor(''), '?');
      expect(UserAvatar.initialsFor('   '), '?');
    });
  });

  group('tohum verisi', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    const dbName = 'program_visuals_test.db';

    setUp(() async {
      await DatabaseHelper.resetForTesting(databaseName: dbName);
      await deleteDatabase(join(await getDatabasesPath(), dbName));
    });

    tearDownAll(() async {
      await DatabaseHelper.resetForTesting();
    });

    // Release build'de INTERNET izni yok; tohum verisi dış URL taşırsa
    // kartlar yayınlanan uygulamada görselsiz kalır.
    test('hazır şablonlar dış görsel URL\'i taşımıyor', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      final programs = await dao.getAllPrograms();
      expect(programs, isNotEmpty);
      for (final program in programs) {
        expect(program.imageUrl, isEmpty,
            reason: '${program.title} hâlâ dış URL taşıyor');
      }
    });

    // Fotoğraf ZORUNLU DEĞİL: ProgramVisuals iki katmanlı tasarlandı, fotoğrafı
    // olmayan program etiketinden türeyen gradyana düşüyor. Zorunlu tutan eski
    // test, kart sayısı 5'ken yazılmıştı; o bir tasarım kuralı değil, o günkü
    // durumun fotoğrafıydı.
    //
    // Asıl tehlike ters yönde: kayıtlı bir yol yanlışsa Image.asset çalışma
    // anında patlar, üstelik yalnızca o kart açıldığında.
    test('tanımlı her fotoğraf yolu asset klasörünü gösteriyor', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      for (final program in await dao.getAllPrograms()) {
        final asset = ProgramVisuals.photoAsset(program.title);
        if (asset == null) continue; // gradyana düşecek, sorun değil
        expect(asset, startsWith('assets/images/programs/'));
        expect(asset, endsWith('.jpg'));
      }
    });

    // Fotoğrafı olan her kartın Krediler ekranında karşılığı olmalı; fotoğrafı
    // olmayanın kredilendirilecek bir şeyi yok.
    test('fotoğrafı olan her şablonun kredi kaydı var', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      final credited =
          ProgramVisuals.photoCredits.map((c) => c.program).toSet();
      for (final program in await dao.getAllPrograms()) {
        if (!ProgramVisuals.hasPhoto(program.title)) continue;
        expect(credited, contains(program.title),
            reason: '${program.title} Krediler ekranında görünmüyor');
      }
    });

    // Yolu yanlış yazılmış bir asset yalnızca O KART açıldığında patlar; testler
    // widget çizmediği için burada dosyanın diskte olduğuna bakıyoruz.
    test('kayıtlı her fotoğraf dosyası diskte var', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      for (final program in await dao.getAllPrograms()) {
        final asset = ProgramVisuals.photoAsset(program.title);
        if (asset == null) continue;
        expect(File(asset).existsSync(), isTrue,
            reason: '${program.title} -> $asset diskte yok');
      }
    });

    // Yeniden adlandırılan bir program, fotoğrafını sessizce kaybeder ve
    // kullanılmayan bir asset uygulamada ölü ağırlık olarak kalır.
    test('her gömülü fotoğrafın karşılığı bir şablon var', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      final titles = (await dao.getAllPrograms()).map((p) => p.title).toSet();
      for (final credit in ProgramVisuals.photoCredits) {
        expect(titles, contains(credit.program),
            reason: '"${credit.program}" için fotoğraf var ama şablon yok');
      }
    });

    // Kullanıcının kendi şablonlarının fotoğrafı yok; gradyana düşmeli
    test('kullanıcı şablonu fotoğrafsız kalır, gradyan alır', () {
      expect(ProgramVisuals.photoAsset('Omuz Antrenmanı'), isNull);
      expect(ProgramVisuals.hasPhoto('Omuz Antrenmanı'), isFalse);
      expect(ProgramVisuals.gradient('OMUZ').colors, hasLength(2));
    });
  });
}
